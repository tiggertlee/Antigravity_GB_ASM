; ==============================================================================
; splash.asm - Title Screen and Splash State Machine
; Displays game title splash graphic from gfx/Pong.png and animated prompt.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "memory.inc"
INCLUDE "graphics.inc"

SECTION "SplashState", ROM0

; ------------------------------------------------------------------------------
; InitSplash - Sets up background tilemap and sprites for the splash screen
; ------------------------------------------------------------------------------
InitSplash::
    ; Safely shut down LCD to load background tilemap & pattern data
    call TurnLCDOff

    ; Clear entire 32x32 background map
    call ClearTileMap

    ; Clear all sprites in shadow OAM
    call ClearShadowOAM

    ; --------------------------------------------------------------------------
    ; 1. Load Splash Screen Tile Patterns into VRAM ($8000)
    ; --------------------------------------------------------------------------
    call LoadSplashGraphics

    ; --------------------------------------------------------------------------
    ; 2. Load Full 20x18 Background Tilemap into _SCRN0 ($9800)
    ; --------------------------------------------------------------------------
    call LoadSplashTilemap

    ; --------------------------------------------------------------------------
    ; 3. Initialize Flashing Prompt Sprite (OAM Sprite 0)
    ; Placed to the left of the "START" word inside the button box
    ; Screen (X, Y) = (48, 110) -> OAM (X, Y) = (56, 126)
    ; --------------------------------------------------------------------------
    ld hl, wShadowOAM
    ld a, 110 + 16                      ; Screen Y = 110 (OAM Y = 126)
    ld [hli], a                         ; Sprite 0 Y
    ld a, 48 + 8                        ; Screen X = 48 (OAM X = 56)
    ld [hli], a                         ; Sprite 0 X
    ld a, $D9                           ; Arrow / cursor tile from splash graphics
    ld [hli], a                         ; Sprite 0 Tile ID
    ld a, OAMF_XFLIP                    ; Point right toward "START"
    ld [hli], a                         ; Sprite 0 Attributes (Palette 0, X-flipped)

    ; --------------------------------------------------------------------------
    ; 4. Configure Reversed Display Palettes for Splash Screen
    ; Reverses lightest and darkest shades (%00 01 10 11)
    ; --------------------------------------------------------------------------
    ld a, %00011011
    ld [rBGP], a                        ; Reversed background palette
    ld [rOBP0], a                       ; Sprite palette 0
    ld [rOBP1], a                       ; Sprite palette 1

    ; Turn LCD display on
    call TurnLCDOn
    ret

; ------------------------------------------------------------------------------
; UpdateSplash - Per-frame update for splash screen
; Flashes prompt indicator and monitors Start/A inputs.
; ------------------------------------------------------------------------------
UpdateSplash::
    ; --------------------------------------------------------------------------
    ; Flashing Prompt Animation: Toggle visibility on bit 5 (~0.5s period)
    ; With subtle 2-pixel bobbing pulse when visible
    ; --------------------------------------------------------------------------
    ld a, [wFrameCounter]
    bit 5, a                            ; Flash phase toggle
    jr nz, .hidePrompt

    ; Prompt Visible: Position next to "START" with subtle horizontal bob
    ld a, [wFrameCounter]
    srl a
    srl a
    srl a                               ; Divide frame counter by 8
    and 1                               ; 0 or 1
    sla a                               ; 0 or 2 pixel displacement
    add a, 48 + 8                       ; Base OAM X = 56
    ld [wShadowOAM + 1], a              ; Sprite 0 X
    ld a, 110 + 16                      ; Base OAM Y = 126
    ld [wShadowOAM + 0], a              ; Sprite 0 Y
    jr .checkInput

.hidePrompt:
    ; Prompt Hidden during off-phase
    xor a
    ld [wShadowOAM + 0], a              ; Set Y=0 (off-screen)

.checkInput:
    ; --------------------------------------------------------------------------
    ; Check for START or A button press to begin game
    ; --------------------------------------------------------------------------
    ld a, [wJoyPressed]
    and PADF_START | PADF_A
    ret z                               ; No trigger, remain on splash

    ; Transition to Main Game State
    ld a, STATE_GAME
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

; ------------------------------------------------------------------------------
; LoadSplashGraphics - Copies 2BPP tile patterns from Pong.2bpp to VRAM ($8000)
; ------------------------------------------------------------------------------
LoadSplashGraphics::
    ld hl, _VRAM_TILES
    ld de, SplashTiles
    ld bc, SplashTilesEnd - SplashTiles
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
; LoadSplashTilemap - Copies 20x18 tilemap from Pong.tilemap into _SCRN0 ($9800)
; ------------------------------------------------------------------------------
LoadSplashTilemap::
    ld hl, _SCRN0
    ld de, SplashTilemap
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
; Splash Screen Graphics & Tilemap Binary Data
; ------------------------------------------------------------------------------
SECTION "SplashGraphicsData", ROM0

SplashTiles:
    INCBIN "gfx/Pong.2bpp"
SplashTilesEnd:

SplashTilemap:
    INCBIN "gfx/Pong.tilemap"
SplashTilemapEnd:
