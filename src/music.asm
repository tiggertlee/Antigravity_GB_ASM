; ==============================================================================
; music.asm - Chiptune Music Driver & Splash Screen "Neon Surge" Electro Punk Track
; Handles step-sequencing, channel synthesis, and tempo synchronization.
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "music.inc"
INCLUDE "sound.inc"

SECTION "MusicEngine", ROM0

; ------------------------------------------------------------------------------
; StartMusicSplash - Initializes and starts playing the Splash screen track
; ------------------------------------------------------------------------------
StartMusicSplash::
    ; Reset playback state
    xor a
    ld [wMusicStep], a
    ld a, 1
    ld [wMusicTick], a                  ; Trigger immediately on first frame
    ld [wMusicPlaying], a
    ret

; ------------------------------------------------------------------------------
; StopMusic - Stops music playback and silences all channels
; ------------------------------------------------------------------------------
StopMusic::
    xor a
    ld [wMusicPlaying], a

    ; Cut volume envelopes and trigger channel silence
    ld [rNR12], a
    ld [rNR22], a
    ld [rNR42], a
    ld a, $80
    ld [rNR14], a
    ld [rNR24], a
    ld [rNR44], a
    ret

; ------------------------------------------------------------------------------
; UpdateMusic - Advances song timer and dispatches notes/drums per frame
; ------------------------------------------------------------------------------
UpdateMusic::
    ; Check if music is actively playing
    ld a, [wMusicPlaying]
    and a
    ret z

    ; Countdown frame ticks per step
    ld a, [wMusicTick]
    dec a
    ld [wMusicTick], a
    ret nz                              ; Not yet time for next step

    ; Reset step tick countdown
    ld a, MUSIC_TEMPO_FRAMES
    ld [wMusicTick], a

    ; --------------------------------------------------------------------------
    ; Fetch Step Data from Song Table
    ; Step structure: [DW Ch1_Freq, DW Ch2_Freq, DB Drum_Type] (5 bytes per step)
    ; --------------------------------------------------------------------------
    ld a, [wMusicStep]
    ld l, a
    ld h, 0
    ; Multiply step index by 5: HL = (step * 4) + step
    add hl, hl                          ; * 2
    add hl, hl                          ; * 4
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a                             ; HL = step * 5

    ld de, SongData_Splash
    add hl, de                          ; HL points to current step record

    ; --------------------------------------------------------------------------
    ; 1. Play Channel 1 Note (Lead Synth / Arpeggio)
    ; --------------------------------------------------------------------------
    ld a, [hli]                         ; Frequency Low
    ld c, a
    ld a, [hli]                         ; Frequency High
    ld b, a
    or c                                ; Check for NOTE_REST ($0000)
    jr z, .ch1Done

    ; Trigger Lead Synth note on Channel 1
    xor a
    ld [rNR10], a                       ; No sweep
    ld a, %10000000                     ; 50% duty cycle
    ld [rNR11], a
    ld a, %10010010                     ; Initial Vol: 9, Decay Pace: 2
    ld [rNR12], a
    ld a, c                             ; Freq Lo
    ld [rNR13], a
    ld a, b
    or %10000000                        ; Trigger bit 7 + Freq Hi
    ld [rNR14], a

.ch1Done:
    ; --------------------------------------------------------------------------
    ; 2. Play Channel 2 Note (Pumping Bass)
    ; --------------------------------------------------------------------------
    ld a, [hli]                         ; Frequency Low
    ld c, a
    ld a, [hli]                         ; Frequency High
    ld b, a
    or c                                ; Check for NOTE_REST ($0000)
    jr z, .ch2Done

    ; Trigger Bass note on Channel 2 (25% duty for buzzing electro bass)
    ld a, %01000000                     ; 25% duty cycle
    ld [rNR21], a
    ld a, %10100001                     ; Initial Vol: 10, Decay Pace: 1
    ld [rNR22], a
    ld a, c                             ; Freq Lo
    ld [rNR23], a
    ld a, b
    or %10000000                        ; Trigger bit 7 + Freq Hi
    ld [rNR24], a

.ch2Done:
    ; --------------------------------------------------------------------------
    ; 3. Play Channel 4 Percussion (Noise Drums)
    ; --------------------------------------------------------------------------
    ld a, [hli]                         ; Drum Type
    and a
    jr z, .advanceStep                  ; DRUM_NONE

    cp DRUM_KICK
    jr nz, .checkSnare
    ; --- Kick Drum ---
    xor a
    ld [rNR41], a
    ld a, %11000001                     ; Vol 12, Fast Decay 1
    ld [rNR42], a
    ld a, %00010000                     ; Low frequency noise thump
    ld [rNR43], a
    ld a, %10000000                     ; Trigger
    ld [rNR44], a
    jr .advanceStep

.checkSnare:
    cp DRUM_SNARE
    jr nz, .checkHiHat
    ; --- Snare Drum ---
    xor a
    ld [rNR41], a
    ld a, %10110010                     ; Vol 11, Decay 2
    ld [rNR42], a
    ld a, %01010000                     ; Wideband crisp snap
    ld [rNR43], a
    ld a, %10000000                     ; Trigger
    ld [rNR44], a
    jr .advanceStep

.checkHiHat:
    cp DRUM_HIHAT
    jr nz, .checkOpenHat
    ; --- Closed Hi-Hat ---
    xor a
    ld [rNR41], a
    ld a, %01110001                     ; Vol 7, Rapid Decay 1
    ld [rNR42], a
    ld a, %00010101                     ; 7-bit metallic click
    ld [rNR43], a
    ld a, %10000000                     ; Trigger
    ld [rNR44], a
    jr .advanceStep

.checkOpenHat:
    ; --- Open Hi-Hat ---
    xor a
    ld [rNR41], a
    ld a, %10010010                     ; Vol 9, Decay 2
    ld [rNR42], a
    ld a, %00100101                     ; 7-bit metallic shimmer
    ld [rNR43], a
    ld a, %10000000                     ; Trigger
    ld [rNR44], a

.advanceStep:
    ; --------------------------------------------------------------------------
    ; Advance Step Counter (Loop at 64 steps)
    ; --------------------------------------------------------------------------
    ld a, [wMusicStep]
    inc a
    cp MUSIC_STEP_COUNT
    jr c, .saveStep
    xor a                               ; Loop back to step 0
.saveStep:
    ld [wMusicStep], a
    ret

; ==============================================================================
; Electro Punk Song Data: "Neon Surge"
; 64 Steps (4 Bars), Format: [DW Ch1_Lead, DW Ch2_Bass, DB Drum_Type]
; ==============================================================================
SECTION "MusicSongData", ROM0

SongData_Splash:
    ; --------------------------------------------------------------------------
    ; BAR 1: A Minor Driving Intro Hook
    ; --------------------------------------------------------------------------
    ; Step 00 - Beat 1.1
    dw NOTE_A4,     NOTE_A2,    DRUM_KICK
    ; Step 01 - Beat 1.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 02 - Beat 1.3
    dw NOTE_C5,     NOTE_A3,    DRUM_HIHAT
    ; Step 03 - Beat 1.4
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 04 - Beat 2.1
    dw NOTE_E5,     NOTE_A2,    DRUM_SNARE
    ; Step 05 - Beat 2.2
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    ; Step 06 - Beat 2.3
    dw NOTE_C5,     NOTE_A3,    DRUM_HIHAT
    ; Step 07 - Beat 2.4
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 08 - Beat 3.1
    dw NOTE_A4,     NOTE_A2,    DRUM_KICK
    ; Step 09 - Beat 3.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 10 - Beat 3.3
    dw NOTE_C5,     NOTE_A3,    DRUM_KICK
    ; Step 11 - Beat 3.4
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    ; Step 12 - Beat 4.1
    dw NOTE_E5,     NOTE_A2,    DRUM_SNARE
    ; Step 13 - Beat 4.2
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    ; Step 14 - Beat 4.3
    dw NOTE_E5,     NOTE_A3,    DRUM_OPENHAT
    ; Step 15 - Beat 4.4
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE

    ; --------------------------------------------------------------------------
    ; BAR 2: F Major (Steps 16-23) -> G Major (Steps 24-31) Power Chord Pulse
    ; --------------------------------------------------------------------------
    ; Step 16 - Beat 1.1 (F Major)
    dw NOTE_F4,     NOTE_F2,    DRUM_KICK
    ; Step 17 - Beat 1.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 18 - Beat 1.3
    dw NOTE_A4,     NOTE_F3,    DRUM_HIHAT
    ; Step 19 - Beat 1.4
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 20 - Beat 2.1
    dw NOTE_C5,     NOTE_F2,    DRUM_SNARE
    ; Step 21 - Beat 2.2
    dw NOTE_F5,     NOTE_REST,  DRUM_NONE
    ; Step 22 - Beat 2.3
    dw NOTE_E5,     NOTE_F3,    DRUM_HIHAT
    ; Step 23 - Beat 2.4
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    ; Step 24 - Beat 3.1 (G Major)
    dw NOTE_G4,     NOTE_G2,    DRUM_KICK
    ; Step 25 - Beat 3.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 26 - Beat 3.3
    dw NOTE_B4,     NOTE_G3,    DRUM_KICK
    ; Step 27 - Beat 3.4
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    ; Step 28 - Beat 4.1
    dw NOTE_G5,     NOTE_G2,    DRUM_SNARE
    ; Step 29 - Beat 4.2
    dw NOTE_F5,     NOTE_REST,  DRUM_NONE
    ; Step 30 - Beat 4.3
    dw NOTE_E5,     NOTE_G3,    DRUM_OPENHAT
    ; Step 31 - Beat 4.4
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE

    ; --------------------------------------------------------------------------
    ; BAR 3: A Minor High Lead Riff & Octave Lift
    ; --------------------------------------------------------------------------
    ; Step 32 - Beat 1.1
    dw NOTE_A5,     NOTE_A2,    DRUM_KICK
    ; Step 33 - Beat 1.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 34 - Beat 1.3
    dw NOTE_G5,     NOTE_A3,    DRUM_HIHAT
    ; Step 35 - Beat 1.4
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    ; Step 36 - Beat 2.1
    dw NOTE_G5,     NOTE_A2,    DRUM_SNARE
    ; Step 37 - Beat 2.2
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    ; Step 38 - Beat 2.3
    dw NOTE_C6,     NOTE_A3,    DRUM_HIHAT
    ; Step 39 - Beat 2.4
    dw NOTE_B5,     NOTE_REST,  DRUM_NONE
    ; Step 40 - Beat 3.1
    dw NOTE_A5,     NOTE_A2,    DRUM_KICK
    ; Step 41 - Beat 3.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 42 - Beat 3.3
    dw NOTE_G5,     NOTE_A3,    DRUM_HIHAT
    ; Step 43 - Beat 3.4
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    ; Step 44 - Beat 4.1
    dw NOTE_D5,     NOTE_A2,    DRUM_SNARE
    ; Step 45 - Beat 4.2
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    ; Step 46 - Beat 4.3
    dw NOTE_G5,     NOTE_A3,    DRUM_OPENHAT
    ; Step 47 - Beat 4.4
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE

    ; --------------------------------------------------------------------------
    ; BAR 4: D Minor (Steps 48-55) -> E Major Turnaround & Snare Fill (Steps 56-63)
    ; --------------------------------------------------------------------------
    ; Step 48 - Beat 1.1 (D Minor)
    dw NOTE_D5,     NOTE_D3,    DRUM_KICK
    ; Step 49 - Beat 1.2
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    ; Step 50 - Beat 1.3
    dw NOTE_F5,     NOTE_D3,    DRUM_HIHAT
    ; Step 51 - Beat 1.4
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    ; Step 52 - Beat 2.1
    dw NOTE_F5,     NOTE_D3,    DRUM_SNARE
    ; Step 53 - Beat 2.2
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    ; Step 54 - Beat 2.3
    dw NOTE_F5,     NOTE_D3,    DRUM_HIHAT
    ; Step 55 - Beat 2.4
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    ; Step 56 - Beat 3.1 (E Major Turnaround & Snare Fill)
    dw NOTE_E5,     NOTE_E3,    DRUM_SNARE
    ; Step 57 - Beat 3.2
    dw NOTE_GS5,    NOTE_REST,  DRUM_NONE
    ; Step 58 - Beat 3.3
    dw NOTE_B5,     NOTE_E3,    DRUM_SNARE
    ; Step 59 - Beat 3.4
    dw NOTE_GS5,    NOTE_REST,  DRUM_NONE
    ; Step 60 - Beat 4.1
    dw NOTE_E5,     NOTE_E2,    DRUM_SNARE
    ; Step 61 - Beat 4.2
    dw NOTE_D5,     NOTE_REST,  DRUM_SNARE
    ; Step 62 - Beat 4.3
    dw NOTE_C5,     NOTE_E2,    DRUM_SNARE
    ; Step 63 - Beat 4.4
    dw NOTE_B4,     NOTE_REST,  DRUM_OPENHAT
