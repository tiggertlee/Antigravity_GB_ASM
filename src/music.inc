; ==============================================================================
; music.inc - Music System Definitions, Note Equates, and Routine Declarations
; ==============================================================================

IF !DEF(MUSIC_INC)
DEF MUSIC_INC EQU 1

; ------------------------------------------------------------------------------
; Music Engine Constants
; ------------------------------------------------------------------------------
DEF MUSIC_TEMPO_FRAMES  EQU 7       ; 7 frames per step (~128.5 BPM electro punk tempo)
DEF MUSIC_STEP_COUNT    EQU 64      ; 64 sixteenth-note steps in the song loop (4 bars)

; ------------------------------------------------------------------------------
; Drum / Percussion Types (Channel 4 Noise)
; ------------------------------------------------------------------------------
DEF DRUM_NONE           EQU 0
DEF DRUM_KICK           EQU 1
DEF DRUM_SNARE          EQU 2
DEF DRUM_HIHAT          EQU 3
DEF DRUM_OPENHAT        EQU 4

; ------------------------------------------------------------------------------
; Note Frequency Equates (Game Boy 11-bit Frequency Values)
; Formula: 2048 - (131072 / FreqHz)
; ------------------------------------------------------------------------------
DEF NOTE_REST           EQU $0000

; Octave 2 & 3 (Bass)
DEF NOTE_E2             EQU $01CA   ; ~82.4 Hz
DEF NOTE_F2             EQU $0223   ; ~87.3 Hz
DEF NOTE_G2             EQU $02C7   ; ~98.0 Hz
DEF NOTE_A2             EQU $0358   ; ~110.0 Hz
DEF NOTE_B2             EQU $03DB   ; ~123.5 Hz
DEF NOTE_C3             EQU $0416   ; ~130.8 Hz
DEF NOTE_D3             EQU $0483   ; ~146.8 Hz
DEF NOTE_E3             EQU $04E5   ; ~164.8 Hz
DEF NOTE_F3             EQU $0511   ; ~174.6 Hz
DEF NOTE_G3             EQU $0563   ; ~196.0 Hz
DEF NOTE_GS3            EQU $0589   ; ~207.7 Hz (G#3)
DEF NOTE_A3             EQU $05AC   ; ~220.0 Hz
DEF NOTE_B3             EQU $05ED   ; ~246.9 Hz

; Octave 4, 5, 6 (Lead Synth & Arpeggios)
DEF NOTE_C4             EQU $060B   ; ~261.6 Hz
DEF NOTE_D4             EQU $0642   ; ~293.7 Hz
DEF NOTE_E4             EQU $0672   ; ~329.6 Hz
DEF NOTE_F4             EQU $0689   ; ~349.2 Hz
DEF NOTE_G4             EQU $06B2   ; ~392.0 Hz
DEF NOTE_GS4            EQU $06C4   ; ~415.3 Hz (G#4)
DEF NOTE_A4             EQU $06D6   ; ~440.0 Hz
DEF NOTE_B4             EQU $06F7   ; ~493.9 Hz
DEF NOTE_C5             EQU $0706   ; ~523.3 Hz
DEF NOTE_D5             EQU $0721   ; ~587.3 Hz
DEF NOTE_E5             EQU $0739   ; ~659.3 Hz
DEF NOTE_F5             EQU $0744   ; ~698.5 Hz
DEF NOTE_G5             EQU $0759   ; ~784.0 Hz
DEF NOTE_GS5            EQU $0762   ; ~830.6 Hz (G#5)
DEF NOTE_A5             EQU $076B   ; ~880.0 Hz
DEF NOTE_B5             EQU $077B   ; ~987.8 Hz
DEF NOTE_C6             EQU $0783   ; ~1046.5 Hz
DEF NOTE_D6             EQU $0790   ; ~1174.7 Hz
DEF NOTE_E6             EQU $079C   ; ~1318.5 Hz

; Global API routines implemented in music.asm:
; - StartMusicSplash
; - StopMusic
; - UpdateMusic

ENDC ; MUSIC_INC
