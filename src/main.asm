; ==============================================================================
; main.asm - Core Entry Point, Interrupt Vectors, System Initialization,
;            Joypad Polling, VBlank Handling, and Main State Dispatcher.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "memory.inc"
INCLUDE "graphics.inc"
INCLUDE "sound.inc"

; ==============================================================================
; RST Vectors ($0000 - $0038)
; ==============================================================================
SECTION "RST_00", ROM0[$0000]
    reti
SECTION "RST_08", ROM0[$0008]
    reti
SECTION "RST_10", ROM0[$0010]
    reti
SECTION "RST_18", ROM0[$0018]
    reti
SECTION "RST_20", ROM0[$0020]
    reti
SECTION "RST_28", ROM0[$0028]
    reti
SECTION "RST_30", ROM0[$0030]
    reti
SECTION "RST_38", ROM0[$0038]
    reti

; ==============================================================================
; Hardware Interrupt Vectors ($0040 - $0060)
; ==============================================================================
SECTION "VBlank_ISR", ROM0[$0040]
    jp VBlankHandler

SECTION "LCD_STAT_ISR", ROM0[$0048]
    reti

SECTION "Timer_ISR", ROM0[$0050]
    reti

SECTION "Serial_ISR", ROM0[$0058]
    reti

SECTION "Joypad_ISR", ROM0[$0060]
    reti

; ==============================================================================
; Game Boy ROM Header ($0100 - $014F)
; ==============================================================================
SECTION "Header", ROM0[$0100]
    nop
    jp SystemInit

    ; Header allocation (Overwritten and verified by rgbfix tool)
    ds $150 - @, 0

; ==============================================================================
; System Initialization
; ==============================================================================
SECTION "SystemInit", ROM0[$0150]

SystemInit:
    ; Disable interrupts during critical initialization
    di

    ; Initialize stack pointer to top of Work RAM
    ld sp, $E000

    ; Safely shut down LCD display to freely write to VRAM
    call TurnLCDOff

    ; --------------------------------------------------------------------------
    ; 1. Clear Work RAM ($C000 - $DFFF)
    ; --------------------------------------------------------------------------
    ld hl, _RAM
    ld bc, $2000                ; 8KB of WRAM
.clearWRAM:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearWRAM

    ; --------------------------------------------------------------------------
    ; 2. Clear High RAM ($FF80 - $FFFE)
    ; --------------------------------------------------------------------------
    ld hl, _HRAM
    ld c, $7F                   ; 127 bytes of HRAM
    xor a
.clearHRAM:
    ld [hli], a
    dec c
    jr nz, .clearHRAM

    ; --------------------------------------------------------------------------
    ; 3. Install OAM DMA Copy Routine in HRAM
    ; --------------------------------------------------------------------------
    ; Since OAM cannot be accessed while DMA runs, the DMA trigger code must
    ; execute from HRAM ($FF80+).
    ; --------------------------------------------------------------------------
    ld hl, DMARoutineSource
    ld de, hOAMDMA
    ld c, DMARoutineSourceEnd - DMARoutineSource
.copyDMA:
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copyDMA

    ; --------------------------------------------------------------------------
    ; 4. Clear Video RAM ($8000 - $9FFF)
    ; --------------------------------------------------------------------------
    ld hl, _VRAM
    ld bc, $2000                ; 8KB of VRAM
.clearVRAM:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearVRAM

    ; --------------------------------------------------------------------------
    ; 5. Load Tile Graphics into VRAM ($8000)
    ; --------------------------------------------------------------------------
    call LoadGraphics

    ; --------------------------------------------------------------------------
    ; 6. Clear Sprite Shadow OAM Buffer
    ; --------------------------------------------------------------------------
    call ClearShadowOAM

    ; --------------------------------------------------------------------------
    ; 7. Configure Display Palettes
    ; --------------------------------------------------------------------------
    ; Palette byte: %11 10 01 00 = Color3(Black), Color2(Dark), Color1(Light), Color0(White)
    ld a, %11100100
    ld [rBGP], a                ; Background palette
    ld [rOBP0], a               ; Sprite palette 0
    ld [rOBP1], a               ; Sprite palette 1

    ; Reset Scroll registers
    xor a
    ld [rSCY], a
    ld [rSCX], a

    ; --------------------------------------------------------------------------
    ; 8. Initialize Sound Hardware
    ; --------------------------------------------------------------------------
    call InitSound

    ; --------------------------------------------------------------------------
    ; 9. Set Initial State
    ; --------------------------------------------------------------------------
    ld a, STATE_SPLASH
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a

    ; Enable VBlank Interrupt
    ld a, IEF_VBLANK
    ld [rIE], a
    xor a
    ld [rIF], a                 ; Clear pending interrupt flags
    ei                          ; Enable hardware interrupts

    ; Turn LCD display on
    call TurnLCDOn

; ==============================================================================
; Main Loop - State Machine Dispatcher
; ==============================================================================
MainLoop:
    ; Wait for vertical blanking interval to synchronize at 59.7 FPS
    ; Also executes OAM DMA from HRAM
    call WaitVBlank

    ; Poll and debounce joypad input
    call ReadJoypad

    ; Check if active state needs initialization
    ld a, [wStateNeedsInit]
    and a
    jr z, .dispatchState

    ; Clear state initialization flag
    xor a
    ld [wStateNeedsInit], a

    ; Execute Init routine based on current state
    ld a, [wGameState]
    cp STATE_SPLASH
    jr nz, .checkGameInit
    call InitSplash
    jr .dispatchState

.checkGameInit:
    cp STATE_GAME
    jr nz, .checkGameOverInit
    call InitGame
    jr .dispatchState

.checkGameOverInit:
    cp STATE_GAMEOVER
    jr nz, .dispatchState
    call InitGameOver

.dispatchState:
    ; Execute per-frame Update routine for current state
    ld a, [wGameState]
    cp STATE_SPLASH
    jr nz, .notSplash
    call UpdateSplash
    jr MainLoop

.notSplash:
    cp STATE_GAME
    jr nz, .notGame
    call UpdateGame
    jr MainLoop

.notGame:
    cp STATE_GAMEOVER
    jr nz, .invalidState
    call UpdateGameOver
    jr MainLoop

.invalidState:
    ; Fallback safety: reset to splash
    ld a, STATE_SPLASH
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    jr MainLoop

; ==============================================================================
; Interrupt Service Routines & Frame Synchronization
; ==============================================================================
SECTION "EngineCore", ROM0

; ------------------------------------------------------------------------------
; VBlankHandler - Hardware interrupt vector $0040
; Signals to the main loop that VBlank has occurred.
; ------------------------------------------------------------------------------
VBlankHandler:
    push af
    ld a, 1
    ld [hVBlankFlag], a
    pop af
    reti

; ------------------------------------------------------------------------------
; WaitVBlank - Halts CPU until VBlank ISR fires, then triggers OAM DMA
; ------------------------------------------------------------------------------
WaitVBlank::
    ; Put CPU in low-power halt until interrupt fires
.waitHalt:
    halt
    nop                         ; Game Boy halt bug safeguard
    ld a, [hVBlankFlag]
    and a
    jr z, .waitHalt

    ; Reset VBlank flag
    xor a
    ld [hVBlankFlag], a

    ; Trigger high-speed Sprite OAM DMA transfer from HRAM
    call hOAMDMA

    ; Update frame counter and pseudo-random seed
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    ld b, a

    ld a, [rDIV]
    add a, b
    ld [wRNGSeed], a

    ret

; ------------------------------------------------------------------------------
; DMARoutineSource - Copied to HRAM ($FF80) at startup
; Triggers DMA transfer of 160 bytes from wShadowOAM ($C000) to OAM ($FE00).
; Takes exactly 160 µs (40 iterations).
; ------------------------------------------------------------------------------
DMARoutineSource:
    ld a, HIGH(wShadowOAM)      ; $C0
    ldh [rDMA], a               ; Start DMA transfer
    ld a, 40                    ; 40 loops delay
.loop:
    dec a
    jr nz, .loop
    ret
DMARoutineSourceEnd:

; ==============================================================================
; Joypad Reading & Debouncing Subroutine
; ==============================================================================
; Reads D-pad and Action buttons from rJOYP ($FF00).
; Computes:
;   wJoyHeld    - 1 for every button currently depressed.
;   wJoyPressed - 1 only on the initial frame a button transitions to pressed.
;
; Bit mapping:
;   Bit 7: Down
;   Bit 6: Up
;   Bit 5: Left
;   Bit 4: Right
;   Bit 3: Start
;   Bit 2: Select
;   Bit 1: B
;   Bit 0: A
; ------------------------------------------------------------------------------
ReadJoypad::
    ; 1. Poll D-Pad (P14 active low)
    ld a, %00100000             ; Select D-pad
    ld [rJOYP], a
    ld a, [rJOYP]
    ld a, [rJOYP]               ; Delay for key bounce stabilization
    cpl                         ; Invert (pressed keys become 1)
    and $0F                     ; Keep lower 4 bits (Down, Up, Left, Right)
    swap a                      ; Move to upper nibble (bits 4-7)
    ld b, a                     ; Store in B

    ; 2. Poll Buttons (P15 active low)
    ld a, %00010000             ; Select Buttons
    ld [rJOYP], a
    ld a, [rJOYP]
    ld a, [rJOYP]               ; Stabilization delay
    cpl                         ; Invert (pressed keys become 1)
    and $0F                     ; Keep lower 4 bits (Start, Select, B, A)
    or b                        ; Combine with D-pad in upper nibble
    ld b, a                     ; B now holds complete 8-button state

    ; Reset joypad register
    ld a, %00110000
    ld [rJOYP], a

    ; 3. Calculate wJoyPressed: (Current ^ Prev) & Current = Newly pressed
    ld a, [wJoyPrev]
    cpl
    and b
    ld [wJoyPressed], a         ; Save 1-frame trigger

    ; 4. Update wJoyHeld and wJoyPrev
    ld a, b
    ld [wJoyHeld], a
    ld [wJoyPrev], a

    ret

; ==============================================================================
; Video & Display Utilities
; ==============================================================================

; ------------------------------------------------------------------------------
; TurnLCDOff - Safely disables the LCD controller without damaging hardware
; Only turns off during VBlank (LY >= 144) as required by Game Boy hardware.
; ------------------------------------------------------------------------------
TurnLCDOff::
    ld a, [rLCDC]
    and LCDCF_ON
    ret z                       ; Return immediately if already off

.waitLY:
    ld a, [rLY]
    cp 144
    jr c, .waitLY               ; Loop until scanline 144 (VBlank)

    ; Clear LCD Enable bit
    ld a, [rLCDC]
    and ~LCDCF_ON
    ld [rLCDC], a
    ret

; ------------------------------------------------------------------------------
; TurnLCDOn - Restores standard LCD configuration and enables display
; ------------------------------------------------------------------------------
TurnLCDOn::
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ8 | LCDCF_BG8000 | LCDCF_BG9800
    ld [rLCDC], a
    ret

; ------------------------------------------------------------------------------
; ClearTileMap - Fills 32x32 Background Tile Map 0 ($9800-$9BFF) with blank tile
; ------------------------------------------------------------------------------
ClearTileMap::
    ld hl, _SCRN0
    ld bc, 32 * 32              ; 1024 tiles
    ld a, TILE_BLANK
.loop:
    ld [hli], a
    dec bc
    ld a, b
    or c
    ld a, TILE_BLANK
    jr nz, .loop
    ret

; ------------------------------------------------------------------------------
; ClearShadowOAM - Clears all 40 sprites in Shadow OAM by setting Y=0 (hidden)
; ------------------------------------------------------------------------------
ClearShadowOAM::
    ld hl, wShadowOAM
    ld c, 40 * 4                ; 160 bytes
    xor a
.loop:
    ld [hli], a
    dec c
    jr nz, .loop
    ret

; ------------------------------------------------------------------------------
; DrawString - Writes a null-terminated ASCII string to VRAM background map
; Input:
;   HL = Target VRAM destination address in tile map (e.g. $9800 + (y*32) + x)
;   DE = Pointer to null-terminated ASCII string in ROM
; Translates ASCII characters ('A'-'Z', '0'-'9', ' ', ':', '-', '!', '.', '>')
; into corresponding VRAM tile indices.
; ------------------------------------------------------------------------------
DrawString::
    ld a, [de]                  ; Read character from string
    and a                       ; Check for null terminator ($00)
    ret z                       ; Return if end of string

    ; Convert ASCII character to tile index
    call MapCharToTile
    ld [hli], a                 ; Write tile ID to VRAM
    inc de                      ; Advance string pointer
    jr DrawString

; Internal helper: translates ASCII in A to tile ID
MapCharToTile:
    cp " "                      ; Space
    jr nz, .checkUpper
    ld a, TILE_BLANK
    ret

.checkUpper:
    cp "A"
    jr c, .checkDigits
    cp "Z" + 1
    jr nc, .checkDigits
    sub "A"
    add a, TILE_A               ; Map 'A'-'Z' -> TILE_A to TILE_Z
    ret

.checkDigits:
    cp "0"
    jr c, .checkPunctuation
    cp "9" + 1
    jr nc, .checkPunctuation
    sub "0"
    add a, TILE_0               ; Map '0'-'9' -> TILE_0 to TILE_9
    ret

.checkPunctuation:
    cp ":"
    jr nz, .checkDash
    ld a, TILE_COLON
    ret
.checkDash:
    cp "-"
    jr nz, .checkExcl
    ld a, TILE_DASH
    ret
.checkExcl:
    cp "!"
    jr nz, .checkDot
    ld a, TILE_EXCLAMATION
    ret
.checkDot:
    cp "."
    jr nz, .checkArrow
    ld a, TILE_DOT
    ret
.checkArrow:
    cp ">"
    jr nz, .unknownChar
    ld a, TILE_ARROW
    ret
.unknownChar:
    ld a, TILE_BLANK
    ret

; ------------------------------------------------------------------------------
; DrawNumber2Digits - Formats an 8-bit unsigned number (0-99) as 2 decimal tiles
; Input:
;   A  = Number (0-99)
;   HL = Target VRAM address
; Destroys: A, B, C
; ------------------------------------------------------------------------------
DrawNumber2Digits::
    ld b, 0                     ; Tens counter
.calcTens:
    cp 10
    jr c, .doneTens
    sub 10
    inc b
    jr .calcTens

.doneTens:
    ld c, a                     ; C holds units digit (0-9)
    ld a, b
    add a, TILE_0               ; Convert tens digit to tile ID
    ld [hli], a                 ; Write tens digit to VRAM
    ld a, c
    add a, TILE_0               ; Convert units digit to tile ID
    ld [hli], a                 ; Write units digit to VRAM
    ret
