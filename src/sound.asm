; ==============================================================================
; sound.asm - Game Boy APU Audio Driver & Sound Effects
; Provides routines for APU initialization and sound effects (paddle beep,
; wall boop, and out-of-bounds buzz).
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "sound.inc"

SECTION "SoundRoutines", ROM0

; ------------------------------------------------------------------------------
; InitSound - Powers on APU and configures master volume and panning
; ------------------------------------------------------------------------------
InitSound::
    ; 1. Power on the APU (Master sound enable bit 7 of rNR52)
    ld a, $80                           ; Bit 7 = 1 (APU Power ON)
    ld [rNR52], a

    ; 2. Set Master Volume (Left and Right at max volume 7/7, no VIN)
    ld a, $77
    ld [rNR50], a

    ; 3. Enable Stereo Output for all 4 Channels (Left & Right enabled)
    ld a, $FF
    ld [rNR51], a

    ; 4. Clear/Silence all sound channels
    xor a
    ld [rNR10], a                       ; Ch1 Sweep
    ld [rNR11], a                       ; Ch1 Duty / Length
    ld [rNR12], a                       ; Ch1 Volume Envelope
    ld [rNR13], a                       ; Ch1 Frequency Lo
    ld [rNR14], a                       ; Ch1 Frequency Hi / Trigger

    ld [rNR21], a                       ; Ch2 Duty / Length
    ld [rNR22], a                       ; Ch2 Volume Envelope
    ld [rNR23], a                       ; Ch2 Frequency Lo
    ld [rNR24], a                       ; Ch2 Frequency Hi / Trigger

    ld [rNR41], a                       ; Ch4 Length
    ld [rNR42], a                       ; Ch4 Volume Envelope
    ld [rNR43], a                       ; Ch4 Polynomial Counter
    ld [rNR44], a                       ; Ch4 Trigger
    ret

; ------------------------------------------------------------------------------
; PlaySoundPaddle - High-pitch crisp beep on paddle hit (Pulse Channel 1)
; Frequency: ~880 Hz (A5), 50% duty cycle, rapid envelope decay
; ------------------------------------------------------------------------------
PlaySoundPaddle::
    xor a
    ld [rNR10], a                       ; No frequency sweep
    ld a, %10000000                     ; 50% duty cycle
    ld [rNR11], a
    ld a, %10100001                     ; Initial Volume: 10/15, Envelope: Decay, Pace: 1
    ld [rNR12], a
    ld a, $6B                           ; Frequency Lo ($076B = ~880 Hz)
    ld [rNR13], a
    ld a, %10000111                     ; Bit 7 = Trigger, Bits 0-2 = Frequency Hi ($07)
    ld [rNR14], a
    ret

; ------------------------------------------------------------------------------
; PlaySoundWall - Lower-pitch boop on wall reflection (Pulse Channel 1)
; Frequency: ~260 Hz (C4), 50% duty cycle, mellow envelope decay
; ------------------------------------------------------------------------------
PlaySoundWall::
    xor a
    ld [rNR10], a                       ; No frequency sweep
    ld a, %10000000                     ; 50% duty cycle
    ld [rNR11], a
    ld a, %10110010                     ; Initial Volume: 11/15, Envelope: Decay, Pace: 2
    ld [rNR12], a
    ld a, $08                           ; Frequency Lo ($0608 = ~260 Hz)
    ld [rNR13], a
    ld a, %10000110                     ; Bit 7 = Trigger, Bits 0-2 = Frequency Hi ($06)
    ld [rNR14], a
    ret

; ------------------------------------------------------------------------------
; PlaySoundOut - Harsh metallic buzz on out-of-bounds / point scored (Noise Channel 4)
; Mode: 7-bit LFSR noise for metallic buzz with descending envelope
; ------------------------------------------------------------------------------
PlaySoundOut::
    xor a
    ld [rNR41], a                       ; Sound length: continuous
    ld a, %11000011                     ; Initial Volume: 12/15, Envelope: Decay, Pace: 3
    ld [rNR42], a
    ld a, %01101010                     ; Clock Shift 6, 7-bit LFSR mode (bit 3 = 1), Divisor 2
    ld [rNR43], a
    ld a, %10000000                     ; Bit 7 = Trigger
    ld [rNR44], a
    ret
