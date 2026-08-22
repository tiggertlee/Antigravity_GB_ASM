; ==============================================================================
; game.asm - Main Pong Gameplay State Machine & Physics Engine
; Handles human player input, AI opponent tracking, ball kinematics,
; collision physics, scorekeeping, and victory detection.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "memory.inc"
INCLUDE "graphics.inc"
INCLUDE "sound.inc"
INCLUDE "music.inc"

SECTION "GameStateRoutines", ROM0

; ------------------------------------------------------------------------------
; InitGame - Initializes court, scores, physics, and paddle positions
; ------------------------------------------------------------------------------
InitGame::
    ; Stop title music when entering game
    call StopMusic

    ; Safely shut down LCD to draw background court & score HUD
    call TurnLCDOff

    ; Reload in-game gameplay tiles into VRAM ($8000)
    call LoadGraphics

    ; Clear entire background tile map
    call ClearTileMap

    ; Clear sprite buffer
    call ClearShadowOAM

    ; --------------------------------------------------------------------------
    ; 1. Reset Game Variables & Scores
    ; --------------------------------------------------------------------------
    xor a
    ld [wScorePlayer], a
    ld [wScoreAI], a
    ld [wWinner], a
    ld [wScoreUpdateFlag], a

    ; Initial paddle Y positions (Centered vertically: 60)
    ld a, 60
    ld [wPlayerY], a
    ld [wAIY], a

    ; Initial Ball position and velocity
    ld a, BALL_INIT_X
    ld [wBallX], a
    ld a, BALL_INIT_Y
    ld [wBallY], a
    ld a, BALL_BASE_SPEED
    ld [wBallSpeed], a
    ld a, 1
    ld [wBallDX], a                     ; Initial serve moving right toward AI
    ld a, -1
    ld [wBallDY], a                     ; Slight upward angle
    ld a, SERVE_DELAY_FRAMES
    ld [wServeTimer], a                 ; Countdown before launch
    xor a
    ld [wPlayerMoving], a
    ld [wAIMoving], a

    ; --------------------------------------------------------------------------
    ; 2. Draw Score HUD on Row 0
    ; --------------------------------------------------------------------------
    ; Player 1 HUD: "P1: 00" (Row 0, Col 1)
    ld hl, _SCRN0 + (0 * 32) + 1
    ld de, strPlayerHUD
    call DrawString

    ld hl, _SCRN0 + (0 * 32) + 5
    ld a, [wScorePlayer]
    call DrawNumber2Digits

    ; AI Opponent HUD: "AI: 00" (Row 0, Col 13)
    ld hl, _SCRN0 + (0 * 32) + 13
    ld de, strAIHUD
    call DrawString

    ld hl, _SCRN0 + (0 * 32) + 17
    ld a, [wScoreAI]
    call DrawNumber2Digits

    ; --------------------------------------------------------------------------
    ; 3. Draw Court Top and Bottom Walls
    ; --------------------------------------------------------------------------
    ld hl, _SCRN0 + (1 * 32) + 0        ; Top Wall (Row 1)
    ld c, 20
    ld a, TILE_WALL
.drawTopWall:
    ld [hli], a
    dec c
    jr nz, .drawTopWall

    ld hl, _SCRN0 + (17 * 32) + 0       ; Bottom Wall (Row 17)
    ld c, 20
    ld a, TILE_WALL
.drawBotWall:
    ld [hli], a
    dec c
    jr nz, .drawBotWall

    ; --------------------------------------------------------------------------
    ; 4. Draw Center Dashed Net Line (Rows 2 to 16, Col 10)
    ; --------------------------------------------------------------------------
    ld hl, _SCRN0 + (2 * 32) + 10
    ld b, 15                            ; 15 vertical rows
    ld de, 32                           ; Row pitch
.drawNet:
    ld [hl], TILE_NET
    add hl, de
    dec b
    jr nz, .drawNet

    ; Render initial sprite positions
    call RenderGameSprites

    ; Restore standard gameplay palettes (%11 10 01 00)
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ld [rOBP1], a

    ; Turn LCD back on
    call TurnLCDOn
    ret

; ------------------------------------------------------------------------------
; UpdateGame - Main per-frame game physics and logic update
; ------------------------------------------------------------------------------
UpdateGame::
    ; --------------------------------------------------------------------------
    ; 1. Redraw Score HUD if a goal occurred
    ; --------------------------------------------------------------------------
    ld a, [wScoreUpdateFlag]
    and a
    jr z, .noScoreUpdate

    xor a
    ld [wScoreUpdateFlag], a

    ; Update Player score numbers
    ld hl, _SCRN0 + (0 * 32) + 5
    ld a, [wScorePlayer]
    call DrawNumber2Digits

    ; Update AI score numbers
    ld hl, _SCRN0 + (0 * 32) + 17
    ld a, [wScoreAI]
    call DrawNumber2Digits

.noScoreUpdate:
    ; --------------------------------------------------------------------------
    ; 2. Handle Human Player Paddle Movement (Left)
    ; --------------------------------------------------------------------------
    call UpdatePlayerPaddle

    ; --------------------------------------------------------------------------
    ; 3. Handle AI Opponent Paddle Tracking (Right)
    ; --------------------------------------------------------------------------
    call UpdateAIPaddle

    ; --------------------------------------------------------------------------
    ; 4. Handle Ball Serve Countdown & Kinematics
    ; --------------------------------------------------------------------------
    ld a, [wServeTimer]
    and a
    jr z, .moveBall

    ; Decrement serve freeze timer
    dec a
    ld [wServeTimer], a
    jr .finishFrame

.moveBall:
    call UpdateBallPhysics

.finishFrame:
    ; --------------------------------------------------------------------------
    ; 5. Update Shadow OAM Sprites for next VBlank DMA
    ; --------------------------------------------------------------------------
    call RenderGameSprites
    ret

; ==============================================================================
; Player Paddle Control
; ==============================================================================
UpdatePlayerPaddle:
    ld a, [wJoyHeld]
    bit PADB_UP, a
    jr z, .checkDown

    ; Move Player paddle UP
    ld a, 1
    ld [wPlayerMoving], a
    ld a, [wPlayerY]
    sub PLAYER_SPEED
    cp PADDLE_MIN_Y
    jr nc, .savePlayerYUp
    ld a, PADDLE_MIN_Y
.savePlayerYUp:
    ld [wPlayerY], a
    ret

.checkDown:
    bit PADB_DOWN, a
    jr z, .playerStationary

    ; Move Player paddle DOWN
    ld a, 1
    ld [wPlayerMoving], a
    ld a, [wPlayerY]
    add a, PLAYER_SPEED
    cp PADDLE_MAX_Y + 1
    jr c, .savePlayerYDown
    ld a, PADDLE_MAX_Y
.savePlayerYDown:
    ld [wPlayerY], a
    ret

.playerStationary:
    xor a
    ld [wPlayerMoving], a
    ret

; ==============================================================================
; AI Opponent Logic
; Implements half-court vision horizon (X >= 76) and an 8px deadzone for
; human-like reaction and beatable difficulty.
; ==============================================================================
UpdateAIPaddle:
    ; 1. Direction Check: Only track when ball is moving right toward AI (BallDX > 0)
    ld a, [wBallDX]
    bit 7, a                            ; Bit 7 = 1 if BallDX is negative (moving left)
    jr nz, .aiStationary

    ; 2. Vision Horizon Check: Only track when ball reaches mid-court (X >= 76)
    ld a, [wBallX]
    cp AI_VISION_X
    jr c, .aiStationary                 ; Ball still on player's half -> AI idles

    ; 3. Calculate AI Paddle Center: wAIY + 12
    ld a, [wAIY]
    add a, 12
    ld b, a                             ; B = AI paddle vertical center

    ; Calculate Ball Center: wBallY + 4
    ld a, [wBallY]
    add a, 4
    ld c, a                             ; C = Ball vertical center

    ; Compare Ball Center with AI Center
    ld a, c
    cp b
    jr c, .ballAbove

    ; Ball is below AI paddle center -> Move DOWN
    sub b                               ; Distance
    cp AI_DEADZONE                      ; Deadzone threshold (8px)
    jr c, .aiStationary                 ; Within deadzone, do not move

    ld a, 1
    ld [wAIMoving], a
    ld a, [wAIY]
    add a, AI_SPEED
    cp PADDLE_MAX_Y + 1
    jr c, .saveAIYDown
    ld a, PADDLE_MAX_Y
.saveAIYDown:
    ld [wAIY], a
    ret

.ballAbove:
    ; Ball is above AI paddle center -> Move UP
    ld a, b
    sub c                               ; Distance
    cp AI_DEADZONE                      ; Deadzone threshold (8px)
    jr c, .aiStationary                 ; Within deadzone

    ld a, 1
    ld [wAIMoving], a
    ld a, [wAIY]
    sub AI_SPEED
    cp PADDLE_MIN_Y
    jr nc, .saveAIYUp
    ld a, PADDLE_MIN_Y
.saveAIYUp:
    ld [wAIY], a
    ret

.aiStationary:
    xor a
    ld [wAIMoving], a
    ret

; ==============================================================================
; Ball Kinematics, Wall Reflections, Paddle Collisions & Scoring
; ==============================================================================
UpdateBallPhysics:
    ; --------------------------------------------------------------------------
    ; 1. Update Ball Position by Velocity
    ; --------------------------------------------------------------------------
    ; Update X
    ld a, [wBallDX]
    ld b, a
    ld a, [wBallX]
    add a, b
    ld [wBallX], a

    ; Update Y
    ld a, [wBallDY]
    ld b, a
    ld a, [wBallY]
    add a, b
    ld [wBallY], a

    ; --------------------------------------------------------------------------
    ; 2. Top & Bottom Wall Bounces
    ; --------------------------------------------------------------------------
    ; Top Wall Check
    ld a, [wBallY]
    cp BALL_MIN_Y
    jr nc, .checkBottomWall

    ; Bounce off top wall
    ld a, BALL_MIN_Y
    ld [wBallY], a
    ; Invert DY: DY = -DY
    ld a, [wBallDY]
    cpl
    inc a
    ld [wBallDY], a
    call PlaySoundWall
    jr .checkWallSpeedBoost

.checkBottomWall:
    cp BALL_MAX_Y + 1
    jr c, .checkPaddles

    ; Bounce off bottom wall
    ld a, BALL_MAX_Y
    ld [wBallY], a
    ; Invert DY: DY = -DY
    ld a, [wBallDY]
    cpl
    inc a
    ld [wBallDY], a
    call PlaySoundWall

.checkWallSpeedBoost:
    ; Check if wall bounce occurred within 20 pixels of the paddle it came from
    ld a, [wBallDX]
    bit 7, a                            ; Is BallDX negative (moving left towards player)?
    jr nz, .checkWallBoostAI

    ; Ball moving right (rebounded from Player paddle at X=16)
    ; Threshold: Ball X <= PLAYER_X + 8 + WALL_BOOST_DIST (16 + 20 = 36)
    ld a, [wBallX]
    cp (PLAYER_X + 8 + WALL_BOOST_DIST) + 1
    jr nc, .checkPaddles

    ; Boost speed!
    ld a, [wBallSpeed]
    cp BALL_MAX_SPEED
    jr nc, .checkPaddles
    inc a
    ld [wBallSpeed], a
    ld [wBallDX], a                     ; Re-apply DX = +wBallSpeed
    jr .checkPaddles

.checkWallBoostAI:
    ; Ball moving left (rebounded from AI paddle at X=136)
    ; Threshold: Ball X >= AI_X - 8 - WALL_BOOST_DIST (136 - 20 = 116)
    ld a, [wBallX]
    cp (AI_X - 8 - WALL_BOOST_DIST)
    jr c, .checkPaddles

    ; Boost speed!
    ld a, [wBallSpeed]
    cp BALL_MAX_SPEED
    jr nc, .checkPaddles
    inc a
    ld [wBallSpeed], a
    cpl
    inc a
    ld [wBallDX], a                     ; Re-apply DX = -wBallSpeed

.checkPaddles:
    ; --------------------------------------------------------------------------
    ; 3. Paddle Collisions
    ; --------------------------------------------------------------------------
    ld a, [wBallDX]
    bit 7, a                            ; Check sign bit of BallDX (1 = negative / moving left)
    jr nz, .checkPlayerPaddleCollision

    ; Ball moving right -> Check AI Paddle collision
    ld a, [wBallX]
    cp AI_X - 6                         ; Ball approaching AI paddle X (138)
    jp c, .checkGoals
    cp AI_X + 4                         ; Ball beyond paddle rebound zone
    jp nc, .checkGoals

    ; Vertical Overlap Check: Ball Y in [wAIY - 6, wAIY + 24]
    ld a, [wBallY]
    add a, 6
    ld b, a                             ; B = Ball Bottom
    ld a, [wAIY]
    cp b
    jp nc, .checkGoals                  ; AI Top > Ball Bottom (No collision)

    ld a, [wAIY]
    add a, 24
    ld b, a                             ; B = AI Bottom
    ld a, [wBallY]
    cp b
    jp nc, .checkGoals                  ; Ball Top > AI Bottom (No collision)

    ; --- Collision with AI Paddle Detected ---
    call PlaySoundPaddle
    ld a, AI_X - 8
    ld [wBallX], a                      ; Snap ball to paddle front

    ; Adjust speed based on AI paddle movement
    ld a, [wAIMoving]
    and a
    jr z, .aiPaddleStationary

    ; Moving paddle -> Increase speed
    ld a, [wBallSpeed]
    cp BALL_MAX_SPEED
    jr nc, .aiSpeedDone
    inc a
    ld [wBallSpeed], a
    jr .aiSpeedDone

.aiPaddleStationary:
    ; Stationary paddle -> Slow down (min BALL_BASE_SPEED)
    ld a, [wBallSpeed]
    cp BALL_BASE_SPEED + 1
    jr c, .aiSpeedDone
    dec a
    ld [wBallSpeed], a

.aiSpeedDone:
    ld a, [wBallSpeed]
    cpl
    inc a
    ld [wBallDX], a                     ; Rebound left with updated velocity

    ; Calculate deflection angle based on hit location relative to paddle
    ld a, [wBallY]
    add a, 4                            ; Ball center
    ld b, a
    ld a, [wAIY]                        ; AI paddle top
    sub b                               ; Result is negative
    cpl
    inc a                               ; A = Distance from paddle top (0 to 24)

    cp 8                                ; Upper third
    jr c, .deflectAIUpFast
    cp 16                               ; Middle third
    jr c, .deflectAIMid
    ; Lower third -> Deflect down
    ld a, 1
    ld [wBallDY], a
    jp .checkGoals

.deflectAIUpFast:
    ld a, -1
    ld [wBallDY], a
    jp .checkGoals

.deflectAIMid:
    ; Alternate or keep current DY
    jp .checkGoals

.checkPlayerPaddleCollision:
    ; Ball moving left -> Check Player Paddle collision
    ld a, [wBallX]
    cp PLAYER_X + 9                     ; Ball near player paddle X (17)
    jp nc, .checkGoals
    cp PLAYER_X - 2
    jp c, .checkGoals

    ; Vertical Overlap Check: Ball Y in [wPlayerY - 6, wPlayerY + 24]
    ld a, [wBallY]
    add a, 6
    ld b, a                             ; B = Ball Bottom
    ld a, [wPlayerY]
    cp b
    jp nc, .checkGoals                  ; Player Top > Ball Bottom (No collision)

    ld a, [wPlayerY]
    add a, 24
    ld b, a                             ; B = Player Bottom
    ld a, [wBallY]
    cp b
    jp nc, .checkGoals                  ; Ball Top > Player Bottom (No collision)

    ; --- Collision with Player Paddle Detected ---
    call PlaySoundPaddle
    ld a, PLAYER_X + 8
    ld [wBallX], a                      ; Snap ball to paddle front

    ; Adjust speed based on Player paddle movement
    ld a, [wPlayerMoving]
    and a
    jr z, .playerPaddleStationary

    ; Moving paddle -> Increase speed
    ld a, [wBallSpeed]
    cp BALL_MAX_SPEED
    jr nc, .playerSpeedDone
    inc a
    ld [wBallSpeed], a
    jr .playerSpeedDone

.playerPaddleStationary:
    ; Stationary paddle -> Slow down (min BALL_BASE_SPEED)
    ld a, [wBallSpeed]
    cp BALL_BASE_SPEED + 1
    jr c, .playerSpeedDone
    dec a
    ld [wBallSpeed], a

.playerSpeedDone:
    ld a, [wBallSpeed]
    ld [wBallDX], a                     ; Rebound right with updated velocity

    ; Calculate deflection angle based on hit location relative to paddle
    ld a, [wBallY]
    add a, 4                            ; Ball center
    ld b, a
    ld a, [wPlayerY]                    ; Player paddle top
    sub b
    cpl
    inc a                               ; A = Distance from paddle top (0 to 24)

    cp 8                                ; Upper third
    jr c, .deflectPlayerUp
    cp 16                               ; Middle third
    jr c, .deflectPlayerMid
    ; Lower third -> Deflect down
    ld a, 1
    ld [wBallDY], a
    jp .checkGoals

.deflectPlayerUp:
    ld a, -1
    ld [wBallDY], a
    jp .checkGoals

.deflectPlayerMid:
    ; Middle hit maintains trajectory
    jp .checkGoals

; ------------------------------------------------------------------------------
; Goal & Scoring Checks
; ------------------------------------------------------------------------------
.checkGoals:
    ; Check if AI scored (Ball passed left goal threshold)
    ld a, [wBallX]
    cp BALL_GOAL_LEFT
    jr nc, .checkPlayerGoal

    ; --- AI Scored Point ---
    call PlaySoundOut
    ld a, [wScoreAI]
    inc a
    ld [wScoreAI], a
    ld a, 1
    ld [wScoreUpdateFlag], a

    ; Check 11-point victory condition
    ld a, [wScoreAI]
    cp WINNING_SCORE
    jr nc, .aiWins

    ; Reset Serve towards Player
    ld a, BALL_INIT_X
    ld [wBallX], a
    ld a, BALL_INIT_Y
    ld [wBallY], a
    ld a, BALL_BASE_SPEED
    ld [wBallSpeed], a
    ld a, -1                            ; Ball serves left
    ld [wBallDX], a
    ld a, 1
    ld [wBallDY], a
    ld a, SERVE_DELAY_FRAMES
    ld [wServeTimer], a
    ret

.aiWins:
    ; AI Wins Match
    ld a, WINNER_AI
    ld [wWinner], a
    ld a, STATE_GAMEOVER
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

.checkPlayerGoal:
    ; Check if Player scored (Ball passed right goal threshold)
    ld a, [wBallX]
    cp BALL_GOAL_RIGHT
    ret c                               ; Ball still in play

    ; --- Player Scored Point ---
    call PlaySoundOut
    ld a, [wScorePlayer]
    inc a
    ld [wScorePlayer], a
    ld a, 1
    ld [wScoreUpdateFlag], a

    ; Check 11-point victory condition
    ld a, [wScorePlayer]
    cp WINNING_SCORE
    jr nc, .playerWins

    ; Reset Serve towards AI
    ld a, BALL_INIT_X
    ld [wBallX], a
    ld a, BALL_INIT_Y
    ld [wBallY], a
    ld a, BALL_BASE_SPEED
    ld [wBallSpeed], a
    ld a, 1                             ; Ball serves right
    ld [wBallDX], a
    ld a, -1
    ld [wBallDY], a
    ld a, SERVE_DELAY_FRAMES
    ld [wServeTimer], a
    ret

.playerWins:
    ; Player Wins Match
    ld a, WINNER_PLAYER
    ld [wWinner], a
    ld a, STATE_GAMEOVER
    ld [wGameState], a
    ld a, 1
    ld [wStateNeedsInit], a
    ret

; ==============================================================================
; RenderGameSprites - Writes Player, AI, and Ball sprites to Shadow OAM ($C000)
; ==============================================================================
RenderGameSprites:
    ld hl, wShadowOAM

    ; --------------------------------------------------------------------------
    ; 1. Human Player Paddle (Sprites 0, 1, 2)
    ; --------------------------------------------------------------------------
    ; Top Segment
    ld a, [wPlayerY]
    add a, 16                           ; OAM Y offset (+16)
    ld [hli], a
    ld a, PLAYER_X + 8                  ; OAM X offset (+8)
    ld [hli], a
    ld a, TILE_PADDLE_TOP
    ld [hli], a
    xor a
    ld [hli], a                         ; Flags

    ; Middle Segment
    ld a, [wPlayerY]
    add a, 16 + 8
    ld [hli], a
    ld a, PLAYER_X + 8
    ld [hli], a
    ld a, TILE_PADDLE_MID
    ld [hli], a
    xor a
    ld [hli], a

    ; Bottom Segment
    ld a, [wPlayerY]
    add a, 16 + 16
    ld [hli], a
    ld a, PLAYER_X + 8
    ld [hli], a
    ld a, TILE_PADDLE_BOT
    ld [hli], a
    xor a
    ld [hli], a

    ; --------------------------------------------------------------------------
    ; 2. AI Opponent Paddle (Sprites 3, 4, 5)
    ; --------------------------------------------------------------------------
    ; Top Segment
    ld a, [wAIY]
    add a, 16
    ld [hli], a
    ld a, AI_X + 8
    ld [hli], a
    ld a, TILE_PADDLE_TOP
    ld [hli], a
    xor a
    ld [hli], a

    ; Middle Segment
    ld a, [wAIY]
    add a, 16 + 8
    ld [hli], a
    ld a, AI_X + 8
    ld [hli], a
    ld a, TILE_PADDLE_MID
    ld [hli], a
    xor a
    ld [hli], a

    ; Bottom Segment
    ld a, [wAIY]
    add a, 16 + 16
    ld [hli], a
    ld a, AI_X + 8
    ld [hli], a
    ld a, TILE_PADDLE_BOT
    ld [hli], a
    xor a
    ld [hli], a

    ; --------------------------------------------------------------------------
    ; 3. Ball (Sprite 6)
    ; --------------------------------------------------------------------------
    ld a, [wBallY]
    add a, 16
    ld [hli], a
    ld a, [wBallX]
    add a, 8
    ld [hli], a
    ld a, TILE_BALL
    ld [hli], a
    xor a
    ld [hli], a

    ; --------------------------------------------------------------------------
    ; 4. Hide remaining 33 sprites (Sprites 7 to 39)
    ; --------------------------------------------------------------------------
    ld b, 40 - 7
    xor a
.hideLoop:
    ld [hli], a                         ; Y = 0 (Hides sprite offscreen)
    inc hl
    inc hl
    inc hl                              ; Skip X, Tile, Flags
    dec b
    jr nz, .hideLoop

    ret

; ------------------------------------------------------------------------------
; String Literals for Game State
; ------------------------------------------------------------------------------
SECTION "GameStrings", ROM0

strPlayerHUD:
    db "P1:", 0
strAIHUD:
    db "AI:", 0
