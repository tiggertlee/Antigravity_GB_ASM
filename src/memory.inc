; ==============================================================================
; memory.inc - Game Constants and Memory Definitions
; ==============================================================================

IF !DEF(MEMORY_INC)
DEF MEMORY_INC EQU 1

; ------------------------------------------------------------------------------
; Game State Identifiers
; ------------------------------------------------------------------------------
DEF STATE_SPLASH        EQU 0   ; Title & Splash screen state
DEF STATE_GAME          EQU 1   ; Main Pong gameplay state
DEF STATE_GAMEOVER      EQU 2   ; Match result and replay menu state

; ------------------------------------------------------------------------------
; Match & Gameplay Configuration Constants
; ------------------------------------------------------------------------------
DEF WINNING_SCORE       EQU 11  ; First player to 11 points wins the match
DEF SERVE_DELAY_FRAMES  EQU 45  ; Freeze frames before ball launches after point

; Screen Boundaries & Dimensions (Screen Pixel Coordinates)
DEF PADDLE_HEIGHT       EQU 24  ; Paddle height in pixels (3 sprites of 8x8)
DEF PADDLE_MIN_Y        EQU 18  ; Top screen boundary for paddle movement
DEF PADDLE_MAX_Y        EQU 116 ; Bottom screen boundary (140 - 24)
DEF PLAYER_X            EQU 8   ; Left paddle Screen X position
DEF AI_X                EQU 144 ; Right paddle Screen X position
DEF PLAYER_SPEED        EQU 2   ; Human paddle movement per frame (pixels)
DEF AI_SPEED            EQU 1   ; AI paddle movement per frame (capped for fair play)
DEF AI_VISION_X         EQU 76  ; Mid-court X threshold before AI starts tracking ball
DEF AI_DEADZONE         EQU 8   ; Vertical deadzone threshold (pixels) to prevent perfect tracking

; Ball Physical Boundaries & Velocity
DEF BALL_MIN_Y          EQU 18  ; Top court wall bounce threshold
DEF BALL_MAX_Y          EQU 134 ; Bottom court wall bounce threshold
DEF BALL_GOAL_LEFT      EQU 6   ; Ball X threshold where AI scores
DEF BALL_GOAL_RIGHT     EQU 148 ; Ball X threshold where Player scores
DEF BALL_INIT_X         EQU 76  ; Center court X
DEF BALL_INIT_Y         EQU 72  ; Center court Y
DEF BALL_BASE_SPEED     EQU 1   ; Base minimum ball velocity (pixels/frame)
DEF BALL_MAX_SPEED      EQU 3   ; Maximum ball velocity cap (pixels/frame)
DEF WALL_BOOST_DIST     EQU 20  ; Distance threshold (pixels) from paddle for wall boost

; Winner Identifiers
DEF WINNER_PLAYER       EQU 0
DEF WINNER_AI           EQU 1

; Menu Options for Game Over
DEF MENU_OPT_PLAYAGAIN  EQU 0
DEF MENU_OPT_FINISH     EQU 1

ENDC ; MEMORY_INC
