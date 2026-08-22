; ==============================================================================
; gameover.asm - Win/Loss Screen and Post-Match Menu State Machine
; Displays "YOU WIN!" / "YOU LOSE...", final match scores, and interactive menu.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "memory.inc"
INCLUDE "graphics.inc"

SECTION "GameOverState", ROM0

; ------------------------------------------------------------------------------
; InitGameOver - Renders the victory/defeat banner, final scores, and menu
; ------------------------------------------------------------------------------
InitGameOver::
    ; Safely shut down LCD to draw background tile map
    call TurnLCDOff

    ; Ensure in-game font and UI tiles are loaded
    call LoadGraphics

    ; Clear entire 32x32 background map
    call ClearTileMap

    ; Clear sprite buffer
    call ClearShadowOAM

    ; Reset menu cursor to top option ("PLAY AGAIN")
    xor a
    ld [wMenuSelection], a

    ; --------------------------------------------------------------------------
    ; 1. Draw Decorative Court Borders
    ; --------------------------------------------------------------------------
    ld hl, _SCRN0 + (1 * 32) + 0        ; Top Wall (Row 1)
    ld c, 20
    ld a, TILE_WALL
.topWall:
    ld [hli], a
    dec c
    jr nz, .topWall

    ld hl, _SCRN0 + (16 * 32) + 0       ; Bottom Wall (Row 16)
    ld c, 20
    ld a, TILE_WALL
.botWall:
    ld [hli], a
    dec c
    jr nz, .botWall

    ; --------------------------------------------------------------------------
    ; 2. Display Winner Banner ("YOU WIN!" or "YOU LOSE...")
    ; --------------------------------------------------------------------------
    ld a, [wWinner]
    cp WINNER_PLAYER
    jr nz, .showAILost

    ; Player won: Display "YOU WIN!" (Row 4, Col 6)
    ld hl, _SCRN0 + (4 * 32) + 6
    ld de, strYouWin
    call DrawString
    jr .drawScores

.showAILost:
    ; AI won: Display "YOU LOSE..." (Row 4, Col 5)
    ld hl, _SCRN0 + (4 * 32) + 5
    ld de, strYouLose
    call DrawString

.drawScores:
    ; --------------------------------------------------------------------------
    ; 3. Display Final Match Scores: "FINAL: XX - XX" (Row 7, Col 3)
    ; --------------------------------------------------------------------------
    ld hl, _SCRN0 + (7 * 32) + 3
    ld de, strFinalScoreLabel
    call DrawString

    ; Player score (2 digits at Row 7, Col 10)
    ld hl, _SCRN0 + (7 * 32) + 10
    ld a, [wScorePlayer]
    call DrawNumber2Digits

    ; Dash separator at Row 7, Col 12
    ld hl, _SCRN0 + (7 * 32) + 12
    ld a, TILE_DASH
    ld [hl], a

    ; AI score (2 digits at Row 7, Col 14)
    ld hl, _SCRN0 + (7 * 32) + 14
    ld a, [wScoreAI]
    call DrawNumber2Digits

    ; --------------------------------------------------------------------------
    ; 4. Draw Menu Options
    ; --------------------------------------------------------------------------
    ; Option 0: "PLAY AGAIN" (Row 11, Col 6)
    ld hl, _SCRN0 + (11 * 32) + 6
    ld de, strPlayAgain
    call DrawString

    ; Option 1: "FINISH" (Row 13, Col 6)
    ld hl, _SCRN0 + (13 * 32) + 6
    ld de, strFinish
    call DrawString

    ; Update cursor sprite
    call RenderMenuCursor

    ; Ensure standard palettes (%11 10 01 00)
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ld [rOBP1], a

    ; Turn LCD display on
    call TurnLCDOn
    ret

; ------------------------------------------------------------------------------
; UpdateGameOver - Handles cursor movement (UP/DOWN) and selection (A/START)
; ------------------------------------------------------------------------------
UpdateGameOver::
    ; --------------------------------------------------------------------------
    ; 1. Navigate Menu Cursor (UP / DOWN)
    ; --------------------------------------------------------------------------
    ld a, [wJoyPressed]
    bit PADB_UP, a
    jr z, .checkDown

    ; Move cursor UP to Option 0 ("PLAY AGAIN")
    xor a
    ld [wMenuSelection], a
    jr .checkSelect

.checkDown:
    bit PADB_DOWN, a
    jr z, .checkSelect

    ; Move cursor DOWN to Option 1 ("FINISH")
    ld a, 1
    ld [wMenuSelection], a

.checkSelect:
    ; --------------------------------------------------------------------------
    ; 2. Check Action / Start Button Trigger
    ; --------------------------------------------------------------------------
    ld a, [wJoyPressed]
    and PADF_A | PADF_START
    jr z, .finishFrame

    ; A or START was pressed -> Execute menu selection
    ld a, [wMenuSelection]
    cp MENU_OPT_PLAYAGAIN
    jr nz, .selectFinish

    ; Option 0 Selected: Restart Game
    ld a, STATE_GAME
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

.selectFinish:
    ; Option 1 Selected: Return to Title / Splash Screen
    ld a, STATE_SPLASH
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

.finishFrame:
    ; --------------------------------------------------------------------------
    ; 3. Animate & Position Selector Cursor Sprite
    ; --------------------------------------------------------------------------
    call RenderMenuCursor
    ret

; ==============================================================================
; RenderMenuCursor - Updates Shadow OAM for the menu selector arrow
; ==============================================================================
RenderMenuCursor:
    ld hl, wShadowOAM

    ; Determine Y position based on wMenuSelection
    ld a, [wMenuSelection]
    cp MENU_OPT_PLAYAGAIN
    jr nz, .yOptionFinish

    ; Row 11: Y = (11 * 8) + 16 = 104
    ld a, (11 * 8) + 16
    jr .setSpriteY

.yOptionFinish:
    ; Row 13: Y = (13 * 8) + 16 = 120
    ld a, (13 * 8) + 16

.setSpriteY:
    ld [hli], a                         ; Sprite 0 Y

    ; Micro-animation: Bob selector arrow horizontally
    ld a, [wFrameCounter]
    srl a
    srl a
    srl a                               ; Divide frame counter by 8
    and 1                               ; 0 or 1
    sla a                               ; 0 or 2 pixel displacement
    add a, (4 * 8) + 8                  ; Base X = 40
    ld [hli], a                         ; Sprite 0 X

    ld a, TILE_ARROW
    ld [hli], a                         ; Sprite 0 Tile ID
    xor a
    ld [hli], a                         ; Sprite 0 Flags

    ; Hide remaining 39 sprites
    ld b, 39
    xor a
.hideSprites:
    ld [hli], a                         ; Y = 0 (Offscreen)
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .hideSprites

    ret

; ------------------------------------------------------------------------------
; String Literals for Game Over State
; ------------------------------------------------------------------------------
SECTION "GameOverStrings", ROM0

strYouWin:
    db "YOU WIN!", 0
strYouLose:
    db "YOU LOSE...", 0
strFinalScoreLabel:
    db "FINAL:", 0
strPlayAgain:
    db "PLAY AGAIN", 0
strFinish:
    db "FINISH", 0
