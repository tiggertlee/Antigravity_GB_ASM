; ==============================================================================
; memory.asm - RAM Allocation for AIPongGB
; Allocates Work RAM ($C000) and High RAM ($FF80) Variables
; ==============================================================================

INCLUDE "hardware.inc"

; ------------------------------------------------------------------------------
; Shadow OAM Section ($C000 - $C09F)
; ------------------------------------------------------------------------------
; The Game Boy OAM ($FE00-$FE9F) cannot be safely accessed directly while the
; LCD controller is rendering. We maintain a mirror (Shadow OAM) in WRAM and copy
; it to hardware OAM in ~160 microseconds during VBlank using DMA transfer.
; 40 Sprites x 4 bytes per sprite = 160 ($A0) bytes.
; ------------------------------------------------------------------------------
SECTION "ShadowOAM", WRAM0[$C000]

wShadowOAM::            ds 40 * 4   ; 160-byte buffer for Sprite OAM DMA transfer

; ------------------------------------------------------------------------------
; Game Engine State & Physics Variables ($C0A0+)
; ------------------------------------------------------------------------------
SECTION "GameVariables", WRAM0

; Engine State
wGameState::            ds 1        ; Current active state (STATE_STUDIO, STATE_SPLASH, etc.)
wStateNeedsInit::       ds 1        ; Set to 1 when state has transitioned and needs setup
wFrameCounter::         ds 1        ; Monotonic 8-bit frame counter (increments every VBlank)
wStudioTimer::          ds 1        ; Countdown timer for initial studio splash (frames)

; Joypad Input Buffers
wJoyHeld::              ds 1        ; Buttons currently held down (1 = pressed)
wJoyPressed::           ds 1        ; Buttons newly pressed on this frame (edge triggered)
wJoyPrev::              ds 1        ; Previous frame's held buttons for edge calculation

; Paddle Coordinates (Screen Y in pixels)
wPlayerY::              ds 1        ; Human player paddle Y position (Left)
wAIY::                  ds 1        ; AI opponent paddle Y position (Right)
wPlayerMoving::         ds 1        ; 1 = Player paddle moved this frame, 0 = stationary
wAIMoving::             ds 1        ; 1 = AI paddle moved this frame, 0 = stationary

; Ball Kinematics
wBallX::                ds 1        ; Ball Screen X position
wBallY::                ds 1        ; Ball Screen Y position
wBallDX::               ds 1        ; Ball horizontal velocity (-3..-1, 1..3)
wBallDY::               ds 1        ; Ball vertical velocity (-2, -1, 0, 1, 2)
wBallSpeed::            ds 1        ; Current ball velocity magnitude (1..BALL_MAX_SPEED)
wServeTimer::           ds 1        ; Delay countdown before ball launches

; Match Scoring & Results
wScorePlayer::          ds 1        ; Player 1 score (0 - 11)
wScoreAI::              ds 1        ; AI score (0 - 11)
wWinner::               ds 1        ; WINNER_PLAYER (0) or WINNER_AI (1)
wScoreUpdateFlag::      ds 1        ; Set to 1 to signal VBlank score redraw

; UI & System
wMenuSelection::        ds 1        ; Selected option in Game Over menu (0 or 1)
wRNGSeed::              ds 1        ; Pseudo-random number generator seed

; Music Player State
wMusicPlaying::         ds 1        ; 1 = Music active, 0 = Music stopped
wMusicTick::            ds 1        ; Speed tick countdown (frames per step)
wMusicStep::            ds 1        ; Current song step index (0 to 63)
wMusicSongID::          ds 1        ; Active song identifier (SONG_SPLASH, SONG_WIN, SONG_LOSE)
wMusicTempo::           ds 1        ; Active song tempo (frames per step)
wMusicLength::          ds 1        ; Active song length (total steps before looping)
wMusicSongPtr::         ds 2        ; 16-bit pointer to active song data in ROM

; ------------------------------------------------------------------------------
; High RAM (HRAM) Variables ($FF80 - $FFFE)
; ------------------------------------------------------------------------------
; HRAM is accessible at all times, including during DMA transfers.
; ------------------------------------------------------------------------------
SECTION "HRAM_Variables", HRAM

hVBlankFlag::           ds 1        ; Set to 1 by VBlank ISR to synchronize frame loop
hOAMDMA::               ds 10       ; Executable DMA routine buffer in HRAM
