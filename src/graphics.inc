; ==============================================================================
; graphics.inc - Tile IDs and Graphics Definitions
; ==============================================================================

IF !DEF(GRAPHICS_INC)
DEF GRAPHICS_INC EQU 1

; ------------------------------------------------------------------------------
; VRAM Tile Index Constants ($8000 Pattern Table)
; ------------------------------------------------------------------------------
DEF TILE_BLANK          EQU $00

; Alphabet 'A'-'Z' ($01 - $1A)
DEF TILE_A              EQU $01
DEF TILE_B              EQU $02
DEF TILE_C              EQU $03
DEF TILE_D              EQU $04
DEF TILE_E              EQU $05
DEF TILE_F              EQU $06
DEF TILE_G              EQU $07
DEF TILE_H              EQU $08
DEF TILE_I              EQU $09
DEF TILE_J              EQU $0A
DEF TILE_K              EQU $0B
DEF TILE_L              EQU $0C
DEF TILE_M              EQU $0D
DEF TILE_N              EQU $0E
DEF TILE_O              EQU $0F
DEF TILE_P              EQU $10
DEF TILE_Q              EQU $11
DEF TILE_R              EQU $12
DEF TILE_S              EQU $13
DEF TILE_T              EQU $14
DEF TILE_U              EQU $15
DEF TILE_V              EQU $16
DEF TILE_W              EQU $17
DEF TILE_X              EQU $18
DEF TILE_Y              EQU $19
DEF TILE_Z              EQU $1A

; Digits '0'-'9' ($1B - $24)
DEF TILE_0              EQU $1B
DEF TILE_1              EQU $1C
DEF TILE_2              EQU $1D
DEF TILE_3              EQU $1E
DEF TILE_4              EQU $1F
DEF TILE_5              EQU $20
DEF TILE_6              EQU $21
DEF TILE_7              EQU $22
DEF TILE_8              EQU $23
DEF TILE_9              EQU $24

; Punctuation & Symbols ($25 - $29)
DEF TILE_COLON          EQU $25 ; ':'
DEF TILE_DASH           EQU $26 ; '-'
DEF TILE_EXCLAMATION    EQU $27 ; '!'
DEF TILE_DOT            EQU $28 ; '.'
DEF TILE_ARROW          EQU $29 ; Menu Selector Arrow '>'

; Game Sprite and Court Tiles ($2A - $2F)
DEF TILE_PADDLE_TOP     EQU $2A ; Rounded top paddle cap
DEF TILE_PADDLE_MID     EQU $2B ; Solid paddle middle
DEF TILE_PADDLE_BOT     EQU $2C ; Rounded bottom paddle cap
DEF TILE_BALL           EQU $2D ; Ball sprite
DEF TILE_NET            EQU $2E ; Dashed court center net
DEF TILE_WALL           EQU $2F ; Court boundary wall

DEF TOTAL_TILES         EQU $30 ; 48 total 8x8 tiles (768 bytes)

ENDC ; GRAPHICS_INC
