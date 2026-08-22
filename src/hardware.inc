; ==============================================================================
; hardware.inc - Standard Game Boy (LR35902) Hardware Definitions
; Compatible with RGBDS (Rednex Game Boy Development System)
; ==============================================================================

; ------------------------------------------------------------------------------
; Memory Map Constants
; ------------------------------------------------------------------------------
DEF _VRAM               EQU $8000   ; Video RAM (8KB: $8000 - $9FFF)
DEF _VRAM_TILES         EQU $8000   ; Tile Pattern Table 0 / Sprite Tiles
DEF _SCRN0              EQU $9800   ; BG / Window Tile Map 0 ($9800 - $9BFF)
DEF _SCRN1              EQU $9C00   ; BG / Window Tile Map 1 ($9C00 - $9FFF)
DEF _SRAM               EQU $A000   ; External Cartridge RAM ($A000 - $BFFF)
DEF _RAM                EQU $C000   ; Work RAM Bank 0 ($C000 - $CFFF)
DEF _OAMRAM             EQU $FE00   ; Sprite Object Attribute Memory (160 bytes)
DEF _IO                 EQU $FF00   ; Hardware I/O Registers ($FF00 - $FF7F)
DEF _HRAM               EQU $FF80   ; High RAM ($FF80 - $FFFE)

; ------------------------------------------------------------------------------
; Hardware I/O Registers
; ------------------------------------------------------------------------------
DEF rJOYP               EQU $FF00   ; Joypad Register (P1)
DEF rP1                 EQU $FF00   ; Alias for rJOYP
DEF rSB                 EQU $FF01   ; Serial Data Transfer Byte
DEF rSC                 EQU $FF02   ; Serial Data Transfer Control
DEF rDIV                EQU $FF04   ; Divider Register (16384Hz)
DEF rTIMA               EQU $FF05   ; Timer Counter
DEF rTMA                EQU $FF06   ; Timer Modulo
DEF rTAC                EQU $FF07   ; Timer Control
DEF rIF                 EQU $FF0F   ; Interrupt Flag (Requested Interrupts)

; Sound Registers (NR10 - NR52)
DEF rNR10               EQU $FF10   ; Sound Channel 1 Sweep
DEF rNR11               EQU $FF11   ; Sound Channel 1 Sound Length / Wave Pattern Duty
DEF rNR12               EQU $FF12   ; Sound Channel 1 Volume Envelope
DEF rNR13               EQU $FF13   ; Sound Channel 1 Frequency Lo
DEF rNR14               EQU $FF14   ; Sound Channel 1 Frequency Hi
DEF rNR21               EQU $FF16   ; Sound Channel 2 Sound Length / Wave Pattern Duty
DEF rNR22               EQU $FF17   ; Sound Channel 2 Volume Envelope
DEF rNR23               EQU $FF18   ; Sound Channel 2 Frequency Lo
DEF rNR24               EQU $FF19   ; Sound Channel 2 Frequency Hi
DEF rNR30               EQU $FF1A   ; Sound Channel 3 Sound On/Off
DEF rNR31               EQU $FF1B   ; Sound Channel 3 Sound Length
DEF rNR32               EQU $FF1C   ; Sound Channel 3 Select Output Level
DEF rNR33               EQU $FF1D   ; Sound Channel 3 Frequency Lo
DEF rNR34               EQU $FF1E   ; Sound Channel 3 Frequency Hi
DEF rNR41               EQU $FF20   ; Sound Channel 4 Sound Length
DEF rNR42               EQU $FF21   ; Sound Channel 4 Volume Envelope
DEF rNR43               EQU $FF22   ; Sound Channel 4 Polynomial Counters
DEF rNR44               EQU $FF23   ; Sound Channel 4 Counter / Consecutive
DEF rNR50               EQU $FF24   ; Channel Control / On-Off / Volume
DEF rNR51               EQU $FF25   ; Sound Output Terminal Selection
DEF rNR52               EQU $FF26   ; Sound Master Control On/Off

; LCD Video Registers
DEF rLCDC               EQU $FF40   ; LCD Control Register
DEF rSTAT               EQU $FF41   ; LCD Status Register
DEF rSCY                EQU $FF42   ; Scroll Y (Background vertical position)
DEF rSCX                EQU $FF43   ; Scroll X (Background horizontal position)
DEF rLY                 EQU $FF44   ; LCDC Y-Coordinate (Current scanline: 0-153)
DEF rLYC                EQU $FF45   ; LY Compare
DEF rDMA                EQU $FF46   ; DMA Transfer and Start Address (OAM copy)
DEF rBGP                EQU $FF47   ; BG & Window Palette Data
DEF rOBP0               EQU $FF48   ; Object (Sprite) Palette 0 Data
DEF rOBP1               EQU $FF49   ; Object (Sprite) Palette 1 Data
DEF rWY                 EQU $FF4A   ; Window Y Position
DEF rWX                 EQU $FF4B   ; Window X Position (+7 offset)
DEF rIE                 EQU $FFFF   ; Interrupt Enable Register

; ------------------------------------------------------------------------------
; LCD Control Register (rLCDC) Bits and Masks
; ------------------------------------------------------------------------------
DEF LCDCF_OFF           EQU %00000000 ; LCD Display Off
DEF LCDCF_ON            EQU %10000000 ; LCD Display On
DEF LCDCF_WIN9C00       EQU %01000000 ; Window Tile Map: $9C00-$9FFF
DEF LCDCF_WIN9800       EQU %00000000 ; Window Tile Map: $9800-$9BFF
DEF LCDCF_WINON         EQU %00100000 ; Window Display On
DEF LCDCF_WINOFF        EQU %00000000 ; Window Display Off
DEF LCDCF_BG8000        EQU %00010000 ; BG & Window Tile Data: $8000-$8FFF (Unsigned)
DEF LCDCF_BG8800        EQU %00000000 ; BG & Window Tile Data: $8800-$97FF (Signed)
DEF LCDCF_BG9C00        EQU %00001000 ; BG Tile Map Display Select: $9C00-$9FFF
DEF LCDCF_BG9800        EQU %00000000 ; BG Tile Map Display Select: $9800-$9BFF
DEF LCDCF_OBJ16         EQU %00000100 ; Sprite Size: 8x16 pixels
DEF LCDCF_OBJ8          EQU %00000000 ; Sprite Size: 8x8 pixels
DEF LCDCF_OBJON         EQU %00000010 ; Sprite (OBJ) Display On
DEF LCDCF_OBJOFF        EQU %00000000 ; Sprite (OBJ) Display Off
DEF LCDCF_BGON          EQU %00000001 ; Background & Window Display On
DEF LCDCF_BGOFF         EQU %00000000 ; Background & Window Display Off

; ------------------------------------------------------------------------------
; Interrupt Enable (rIE) & Flag (rIF) Bits
; ------------------------------------------------------------------------------
DEF IEF_VBLANK          EQU %00000001 ; Bit 0: VBlank Interrupt
DEF IEF_LCDC            EQU %00000010 ; Bit 1: LCD STAT Interrupt
DEF IEF_TIMER           EQU %00000100 ; Bit 2: Timer Interrupt
DEF IEF_SERIAL          EQU %00001000 ; Bit 3: Serial Interrupt
DEF IEF_HILO            EQU %00010000 ; Bit 4: Joypad / Transition Interrupt

; ------------------------------------------------------------------------------
; Joypad Button Bit Definitions (for combined input byte)
; ------------------------------------------------------------------------------
DEF PADB_A              EQU 0
DEF PADB_B              EQU 1
DEF PADB_SELECT         EQU 2
DEF PADB_START          EQU 3
DEF PADB_RIGHT          EQU 4
DEF PADB_LEFT           EQU 5
DEF PADB_UP             EQU 6
DEF PADB_DOWN           EQU 7

DEF PADF_A              EQU 1 << PADB_A
DEF PADF_B              EQU 1 << PADB_B
DEF PADF_SELECT         EQU 1 << PADB_SELECT
DEF PADF_START          EQU 1 << PADB_START
DEF PADF_RIGHT          EQU 1 << PADB_RIGHT
DEF PADF_LEFT           EQU 1 << PADB_LEFT
DEF PADF_UP             EQU 1 << PADB_UP
DEF PADF_DOWN           EQU 1 << PADB_DOWN

; ------------------------------------------------------------------------------
; OAM (Sprite) Attribute Flags
; ------------------------------------------------------------------------------
DEF OAMF_PRI            EQU %10000000 ; Priority (0 = Above BG, 1 = Behind BG color 1-3)
DEF OAMF_YFLIP          EQU %01000000 ; Vertical Flip
DEF OAMF_XFLIP          EQU %00100000 ; Horizontal Flip
DEF OAMF_PAL0           EQU %00000000 ; Palette 0 (rOBP0)
DEF OAMF_PAL1           EQU %00010000 ; Palette 1 (rOBP1)
DEF OAMF_BANK0          EQU %00000000 ; VRAM Bank 0 (CGB)
DEF OAMF_BANK1          EQU %00001000 ; VRAM Bank 1 (CGB)

; ------------------------------------------------------------------------------
; Screen Dimensions
; ------------------------------------------------------------------------------
DEF SCRN_X              EQU 160 ; Screen width in pixels
DEF SCRN_Y              EQU 144 ; Screen height in pixels
DEF SCRN_X_TILES        EQU 20  ; Screen width in 8x8 tiles
DEF SCRN_Y_TILES        EQU 18  ; Screen height in 8x8 tiles
