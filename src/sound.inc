; ==============================================================================
; sound.inc - Sound System Constants and Definitions
; ==============================================================================

IF !DEF(SOUND_INC)
DEF SOUND_INC EQU 1

; Sound Frequency Constants
DEF SFX_PADDLE_PITCH_LO EQU $6B ; ~880 Hz (A5)
DEF SFX_PADDLE_PITCH_HI EQU $07
DEF SFX_WALL_PITCH_LO   EQU $08 ; ~260 Hz (C4)
DEF SFX_WALL_PITCH_HI   EQU $06

ENDC ; SOUND_INC
