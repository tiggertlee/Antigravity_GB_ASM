; ==============================================================================
; music.asm - Multi-Track Chiptune Audio Driver & Song Data
; Features:
; - "Neon Surge": Electro Punk Title Theme (Splash Screen)
; - "Victory Bounce": Happy Skipping Major Anthem (You Win Screen)
; - "Death March": Slow Melancholic Dirge (You Lose Screen)
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "music.inc"
INCLUDE "sound.inc"

SECTION "MusicEngine", ROM0

; ------------------------------------------------------------------------------
; StartMusicSplash - Initializes and starts playing the Splash screen track
; Tempo: 7 frames/step (~128.5 BPM), 64 steps
; ------------------------------------------------------------------------------
StartMusicSplash::
    ld a, SONG_SPLASH
    ld [wMusicSongID], a
    ld a, 7
    ld [wMusicTempo], a
    ld a, 64
    ld [wMusicLength], a
    ld hl, SongData_Splash
    ld a, l
    ld [wMusicSongPtr + 0], a
    ld a, h
    ld [wMusicSongPtr + 1], a
    xor a
    ld [wMusicStep], a
    ld a, 1
    ld [wMusicTick], a                  ; Trigger immediately on first frame
    ld [wMusicPlaying], a
    ret

; ------------------------------------------------------------------------------
; StartMusicWin - Initializes and starts playing the You Win victory track
; Tempo: 8 frames/step (~112.5 BPM), 64 steps
; ------------------------------------------------------------------------------
StartMusicWin::
    ld a, SONG_WIN
    ld [wMusicSongID], a
    ld a, 8
    ld [wMusicTempo], a
    ld a, 64
    ld [wMusicLength], a
    ld hl, SongData_Win
    ld a, l
    ld [wMusicSongPtr + 0], a
    ld a, h
    ld [wMusicSongPtr + 1], a
    xor a
    ld [wMusicStep], a
    ld a, 1
    ld [wMusicTick], a                  ; Trigger immediately on first frame
    ld [wMusicPlaying], a
    ret

; ------------------------------------------------------------------------------
; StartMusicLose - Initializes and starts playing the You Lose death march track
; Tempo: 14 frames/step (~53.5 BPM), 64 steps
; ------------------------------------------------------------------------------
StartMusicLose::
    ld a, SONG_LOSE
    ld [wMusicSongID], a
    ld a, 14
    ld [wMusicTempo], a
    ld a, 64
    ld [wMusicLength], a
    ld hl, SongData_Lose
    ld a, l
    ld [wMusicSongPtr + 0], a
    ld a, h
    ld [wMusicSongPtr + 1], a
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
; UpdateMusic - Advances active song timer and dispatches notes/drums per frame
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

    ; Reset step tick countdown to active song tempo
    ld a, [wMusicTempo]
    ld [wMusicTick], a

    ; --------------------------------------------------------------------------
    ; Fetch Step Data from Active Song Pointer
    ; Step record: [DW Ch1_Freq, DW Ch2_Freq, DB Drum_Type] (5 bytes per step)
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

    ld a, [wMusicSongPtr + 0]
    ld e, a
    ld a, [wMusicSongPtr + 1]
    ld d, a
    add hl, de                          ; HL points to current step record in ROM

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
    ; Advance Step Counter (Loop at wMusicLength)
    ; --------------------------------------------------------------------------
    ld a, [wMusicStep]
    inc a
    ld b, a
    ld a, [wMusicLength]
    cp b
    jr z, .loopSong
    ld a, b
    ld [wMusicStep], a
    ret

.loopSong:
    xor a
    ld [wMusicStep], a
    ret

; ==============================================================================
; 1. Title Theme: "Neon Surge" (Electro Punk in A Minor)
; 64 Steps (4 Bars), Format: [DW Ch1_Lead, DW Ch2_Bass, DB Drum_Type]
; ==============================================================================
SECTION "MusicSongData_Splash", ROM0

SongData_Splash:
    ; --- BAR 1: A Minor Driving Intro Hook ---
    dw NOTE_A4,     NOTE_A2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C5,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_A2,    DRUM_SNARE
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    dw NOTE_C5,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_A4,     NOTE_A2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C5,     NOTE_A3,    DRUM_KICK
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_A2,    DRUM_SNARE
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_A3,    DRUM_OPENHAT
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE

    ; --- BAR 2: F Major (16-23) -> G Major (24-31) Power Chords ---
    dw NOTE_F4,     NOTE_F2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_A4,     NOTE_F3,    DRUM_HIHAT
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C5,     NOTE_F2,    DRUM_SNARE
    dw NOTE_F5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_F3,    DRUM_HIHAT
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G4,     NOTE_G2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_B4,     NOTE_G3,    DRUM_KICK
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_G2,    DRUM_SNARE
    dw NOTE_F5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_G3,    DRUM_OPENHAT
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE

    ; --- BAR 3: A Minor High Lead Riff ---
    dw NOTE_A5,     NOTE_A2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_A2,    DRUM_SNARE
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_C6,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_B5,     NOTE_REST,  DRUM_NONE
    dw NOTE_A5,     NOTE_A2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_D5,     NOTE_A2,    DRUM_SNARE
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_A3,    DRUM_OPENHAT
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE

    ; --- BAR 4: D Minor (48-55) -> E Major Turnaround (56-63) ---
    dw NOTE_D5,     NOTE_D3,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_F5,     NOTE_D3,    DRUM_HIHAT
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_F5,     NOTE_D3,    DRUM_SNARE
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE
    dw NOTE_F5,     NOTE_D3,    DRUM_HIHAT
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_E3,    DRUM_SNARE
    dw NOTE_GS5,    NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_E3,    DRUM_SNARE
    dw NOTE_GS5,    NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_E2,    DRUM_SNARE
    dw NOTE_D5,     NOTE_REST,  DRUM_SNARE
    dw NOTE_C5,     NOTE_E2,    DRUM_SNARE
    dw NOTE_B4,     NOTE_REST,  DRUM_OPENHAT

; ==============================================================================
; 2. Victory Theme: "Victory Bounce" (Happy Skipping Major in C)
; 64 Steps (4 Bars), Format: [DW Ch1_Lead, DW Ch2_Bass, DB Drum_Type]
; ==============================================================================
SECTION "MusicSongData_Win", ROM0

SongData_Win:
    ; --- BAR 1: C Major Joyful Fanfare & Bouncy Groove ---
    dw NOTE_C5,     NOTE_C3,    DRUM_KICK
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_G3,    DRUM_HIHAT
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_E3,    DRUM_SNARE
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_G3,    DRUM_HIHAT
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_E6,     NOTE_C3,    DRUM_KICK
    dw NOTE_D6,     NOTE_REST,  DRUM_NONE
    dw NOTE_C6,     NOTE_G3,    DRUM_KICK
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    dw NOTE_A5,     NOTE_E3,    DRUM_SNARE
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    dw NOTE_E5,     NOTE_G3,    DRUM_OPENHAT
    dw NOTE_D5,     NOTE_REST,  DRUM_NONE

    ; --- BAR 2: F Major (16-23) -> G Major (24-31) Skipping Lift ---
    dw NOTE_A5,     NOTE_F3,    DRUM_KICK
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_A5,     NOTE_C4,    DRUM_HIHAT
    dw NOTE_F5,     NOTE_REST,  DRUM_NONE
    dw NOTE_A5,     NOTE_A3,    DRUM_SNARE
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_C4,    DRUM_HIHAT
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_G3,    DRUM_KICK
    dw NOTE_D6,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_D4,    DRUM_KICK
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_B3,    DRUM_SNARE
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_D6,     NOTE_D4,    DRUM_OPENHAT
    dw NOTE_E6,     NOTE_REST,  DRUM_NONE

    ; --- BAR 3: A Minor -> E Minor Melodic Bounce ---
    dw NOTE_C6,     NOTE_A3,    DRUM_KICK
    dw NOTE_E6,     NOTE_REST,  DRUM_NONE
    dw NOTE_D6,     NOTE_E4,    DRUM_HIHAT
    dw NOTE_C6,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_C4,    DRUM_SNARE
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_E4,    DRUM_HIHAT
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_B5,     NOTE_E3,    DRUM_KICK
    dw NOTE_D6,     NOTE_REST,  DRUM_NONE
    dw NOTE_C6,     NOTE_B3,    DRUM_HIHAT
    dw NOTE_B5,     NOTE_REST,  DRUM_NONE
    dw NOTE_A5,     NOTE_G3,    DRUM_SNARE
    dw NOTE_G5,     NOTE_REST,  DRUM_NONE
    dw NOTE_F5,     NOTE_B3,    DRUM_OPENHAT
    dw NOTE_E5,     NOTE_REST,  DRUM_NONE

    ; --- BAR 4: F -> G7 -> C Major Victory Resolve & Fill ---
    dw NOTE_F5,     NOTE_F3,    DRUM_KICK
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_C6,     NOTE_A3,    DRUM_HIHAT
    dw NOTE_A5,     NOTE_REST,  DRUM_NONE
    dw NOTE_G5,     NOTE_G3,    DRUM_SNARE
    dw NOTE_B5,     NOTE_REST,  DRUM_NONE
    dw NOTE_D6,     NOTE_B3,    DRUM_HIHAT
    dw NOTE_F6,     NOTE_REST,  DRUM_NONE
    dw NOTE_E6,     NOTE_C4,    DRUM_SNARE
    dw NOTE_D6,     NOTE_REST,  DRUM_NONE
    dw NOTE_C6,     NOTE_G3,    DRUM_SNARE
    dw NOTE_G5,     NOTE_REST,  DRUM_SNARE
    dw NOTE_E5,     NOTE_E3,    DRUM_SNARE
    dw NOTE_G5,     NOTE_REST,  DRUM_SNARE
    dw NOTE_C6,     NOTE_C3,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_OPENHAT

; ==============================================================================
; 3. Defeat Theme: "Death March" (Slow Melancholic Dirge in C Minor)
; 64 Steps (4 Bars), Format: [DW Ch1_Lead, DW Ch2_Bass, DB Drum_Type]
; ==============================================================================
SECTION "MusicSongData_Lose", ROM0

SongData_Lose:
    ; --- BAR 1: C Minor Heavy Funeral Dirge ---
    dw NOTE_C4,     NOTE_C2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_C2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_C2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_C2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_D4,     NOTE_C2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_C2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_B3,     NOTE_G2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_G2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE

    ; --- BAR 2: Ab Major (16-23) -> G Minor (24-31) Descending Dirge ---
    dw NOTE_DS4,    NOTE_GS2,   DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_GS2,   DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_F4,     NOTE_GS2,   DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_GS2,   DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_D4,     NOTE_G2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_D4,     NOTE_G2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_C2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_B3,     NOTE_G2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE

    ; --- BAR 3: F Minor -> C Minor Mournful Lament ---
    dw NOTE_F4,     NOTE_F2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_GS4,    NOTE_F2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_G4,     NOTE_F2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_F4,     NOTE_F2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_C2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_F4,     NOTE_C2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_C2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_D4,     NOTE_C2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE

    ; --- BAR 4: G7 -> C Minor Final Dirge Cadence ---
    dw NOTE_D4,     NOTE_G2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_F4,     NOTE_G2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_DS4,    NOTE_G2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_D4,     NOTE_G2,    DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_C2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_REST,   NOTE_G2,    DRUM_SNARE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_B3,     NOTE_C2,    DRUM_KICK
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
    dw NOTE_C4,     NOTE_REST,  DRUM_NONE
    dw NOTE_REST,   NOTE_REST,  DRUM_NONE
