; ==============================================================================
; studio.asm - Studio Splash Screen (TornMedia Intro)
; Displays studio logo graphic from gfx/TornMedia.png on initial boot for 3 seconds.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "memory.inc"
INCLUDE "graphics.inc"

SECTION "StudioState", ROM0

; ------------------------------------------------------------------------------
; InitStudio - Sets up background tilemap and display for the studio splash screen
; ------------------------------------------------------------------------------
InitStudio::
    ; Safely shut down LCD to load background tilemap & pattern data
    call TurnLCDOff

    ; Clear entire 32x32 background map
    call ClearTileMap

    ; Clear all sprites in shadow OAM
    call ClearShadowOAM

    ; --------------------------------------------------------------------------
    ; 1. Load Studio Splash Tile Patterns into VRAM ($8000)
    ; --------------------------------------------------------------------------
    call LoadStudioGraphics

    ; --------------------------------------------------------------------------
    ; 2. Load Full 20x18 Background Tilemap into _SCRN0 ($9800)
    ; --------------------------------------------------------------------------
    call LoadStudioTilemap

    ; --------------------------------------------------------------------------
    ; 3. Configure Display Palettes (Reversed shades: %00 01 10 11)
    ; --------------------------------------------------------------------------
    ld a, %00011011
    ld [rBGP], a                        ; Background palette
    ld [rOBP0], a                       ; Sprite palette 0
    ld [rOBP1], a                       ; Sprite palette 1

    ; Reset Scroll registers
    xor a
    ld [rSCY], a
    ld [rSCX], a

    ; --------------------------------------------------------------------------
    ; 4. Initialize 3-Second Duration Countdown Timer (180 frames @ 60 FPS)
    ; --------------------------------------------------------------------------
    ld a, STUDIO_DURATION_FRAMES
    ld [wStudioTimer], a

    ; Turn LCD display on
    call TurnLCDOn
    ret

; ------------------------------------------------------------------------------
; UpdateStudio - Per-frame update for studio splash screen
; Counts down 3-second display duration and checks for Start/A button skip.
; ------------------------------------------------------------------------------
UpdateStudio::
    ; Countdown display timer
    ld a, [wStudioTimer]
    dec a
    ld [wStudioTimer], a
    jr z, .exitStudio

    ; Check for START or A button press to skip intro directly
    ld a, [wJoyPressed]
    and PADF_START | PADF_A
    ret z                               ; No button pressed, stay on studio screen

.exitStudio:
    ; Transition to Title / Start Screen (STATE_SPLASH)
    ld a, STATE_SPLASH
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

; ------------------------------------------------------------------------------
; LoadStudioGraphics - Copies 2BPP tile patterns from TornMedia.2bpp to VRAM ($8000)
; ------------------------------------------------------------------------------
LoadStudioGraphics::
    ld hl, _VRAM_TILES
    ld de, StudioTiles
    ld bc, StudioTilesEnd - StudioTiles
.copyTiles:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copyTiles
    ret

; ------------------------------------------------------------------------------
; LoadStudioTilemap - Copies 20x18 tilemap from TornMedia.tilemap into _SCRN0 ($9800)
; ------------------------------------------------------------------------------
LoadStudioTilemap::
    ld hl, _SCRN0
    ld de, StudioTilemap
    ld b, 18                            ; 18 rows
.rowLoop:
    ld c, 20                            ; 20 columns per row
.colLoop:
    ld a, [de]
    inc de
    ld [hli], a
    dec c
    jr nz, .colLoop
    ; Skip remaining 12 offscreen columns in 32-tile wide row
    ld a, l
    add a, 12
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    dec b
    jr nz, .rowLoop
    ret

; ------------------------------------------------------------------------------
; Studio Splash Screen Graphics & Tilemap Binary Data
; ------------------------------------------------------------------------------
SECTION "StudioGraphicsData", ROM0

StudioTiles:
    INCBIN "gfx/TornMedia.2bpp"
StudioTilesEnd:

StudioTilemap:
    INCBIN "gfx/TornMedia.tilemap"
StudioTilemapEnd:
