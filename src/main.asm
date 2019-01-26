; vim: tabstop=4 shiftwidth=4 noexpandtab ft=z80

INCLUDE "gbchw.inc"
INCLUDE "font.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Directions for BG loadings
_EAST	EQU		1
_WEST	EQU		2

; Button bitflags
_PAD_B		EQU		%00000001
_PAD_A		EQU		%00000010
_PAD_SELECT	EQU		%00000100
_PAD_START	EQU		%00001000
_PAD_RIGHT	EQU		%00010000
_PAD_LEFT	EQU		%00100000
_PAD_UP		EQU		%01000000
_PAD_DOWN	EQU		%10000000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ram
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shadow OAM addresses.  Some may not be used.
RSSET _RAM
_SHADOW_OAM	RB 0

_SPR0_Y		RB 1	; Y Coord
_SPR0_X		RB 1	; X Coord
_SPR0_NUM	RB 1	; Tile number
_SPR0_ATT	RB 1	; Attribute flags

_SPR1_Y		RB 1	; Y Coord
_SPR1_X		RB 1	; X Coord
_SPR1_NUM	RB 1	; Tile number
_SPR1_ATT	RB 1	; Attribute flags

_SPR2_Y		RB 1	; Y Coord
_SPR2_X		RB 1	; X Coord
_SPR2_NUM	RB 1	; Tile number
_SPR2_ATT	RB 1	; Attribute flags

_SPR3_Y		RB 1	; Y Coord
_SPR3_X		RB 1	; X Coord
_SPR3_NUM	RB 1	; Tile number
_SPR3_ATT	RB 1	; Attribute flags

_SPR4_Y		RB 1	; Y Coord
_SPR4_X		RB 1	; X Coord
_SPR4_NUM	RB 1	; Tile number
_SPR4_ATT	RB 1	; Attribute flags

_SPR5_Y		RB 1	; Y Coord
_SPR5_X		RB 1	; X Coord
_SPR5_NUM	RB 1	; Tile number
_SPR5_ATT	RB 1	; Attribute flags

_SPR6_Y		RB 1	; Y Coord
_SPR6_X		RB 1	; X Coord
_SPR6_NUM	RB 1	; Tile number
_SPR6_ATT	RB 1	; Attribute flags

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BLOCK 0
; 96 bytes
; mostly for global data like buttons and world state 
RSSET _RAM + 160
_RAM_BLOCK_0			RB 0

padInput				RB 1	; The input from the d-pad and buttons

bgDrawDirection			RB 1	; Which direction of the background do we draw, 1 = east, 2 = west
bgOffset				RB 1	; how far to the right (in tiles) is our leftmost tile in data
bgRightEdge				RB 1 	; where are we writing our next east tile 0-31
bgLeftEdge				RB 1 	; where are we writing our next west tile 0-31

scrollX					RB 1
scrollY					RB 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_0 + 96
_RAM_BLOCK_1			RB 0

windowToggle			RB 1
currentTextPage			RB 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_1 + 128
_RAM_BLOCK_2			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_2 + 128
_RAM_BLOCK_3			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_3 + 128
_RAM_BLOCK_4			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_4 + 128
_RAM_BLOCK_5			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_5 + 128
_RAM_BLOCK_6			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_6 + 128
_RAM_BLOCK_7			RB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IRQs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION	"Vblank", ROM0[$0040]
	reti
SECTION	"LCDC", ROM0[$0048]
	reti
SECTION	"Timer_Overflow", ROM0[$0050]
	reti
SECTION	"Serial", ROM0[$0058]
	reti
SECTION	"p1thru4", ROM0[$0060]
	reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rom Header
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Header and start vector boilerplate
SECTION "header", ROM0[$0100]
	nop
	jp	Init

	; ROM Header (Macro defined in gbhw.inc)
	ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "game code", ROM0[$0150]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialization
; load palettes for sprites and background
; load map location and scroll variables
; remember to stop LCD before copying tiles to memory
Init:
	nop
	di

	; Set double-rate CPU mode. Gotta go fast!
	ld		hl, rKEY1
	ld		a, [hl]
	and		%10000000
	jr		nz, .waitForVBlank ; if it's already set, we're done.
	ld		[hl], %00000001
	stop

.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; we are in VBlank, turn off LCD
	ld		a, LCDCF_OFF
	ld		[rLCDC], a

	; init stack
	ld		sp, $FFFF

	; copy DMA routine to HRAM
	ld		c, $80
	ld		b, $A
	ld		hl, DMACopy
.copyDMALoop:
	ld		a, [hl+]
	ld		[c], a
	inc		c
	dec		b
	jr		nz, .copyDMALoop

	ld		hl, $FF4F
	ld		[hl], 0

; palette colors
; BGR 555  %0bbbbbgggggrrrrr
_BLUE  EQU %0111110000000000
_GREEN EQU %0000001111100000
_RED   EQU %0000000000011111
_BLACK EQU %0000000000000000

	ld		b, 8
.setPalettes
	; set bg 0 palette
	ld		hl, rBGPI
	ld		[hl], %10000000
	ld		hl, rBGPD
	ld		[hl],  LOW( _BLUE  )
	ld		[hl], HIGH( _BLUE  )
	ld		[hl],  LOW( _GREEN )
	ld		[hl], HIGH( _GREEN )
	ld		[hl],  LOW( _RED   )
	ld		[hl], HIGH( _RED   )
	ld		[hl],  LOW( _BLACK )
	ld		[hl], HIGH( _BLACK )

	; set sprite palette 0
	; BGR 555
	; 0bbbbbgg gggrrrrr
	ld		hl, rOBPI
	ld		[hl], %10000000
	ld		hl, rOBPD
	ld		[hl],  LOW( _BLUE  )
	ld		[hl], HIGH( _BLUE  )
	ld		[hl],  LOW( _GREEN )
	ld		[hl], HIGH( _GREEN )
	ld		[hl],  LOW( _RED   )
	ld		[hl], HIGH( _RED   )
	ld		[hl],  LOW( _BLACK )
	ld		[hl], HIGH( _BLACK )

	dec		b
	jr		nz, .setPalettes

	; copy tiles to VRAM
	ld		hl, Tiles				; source
	ld		de, _VRAM				; destination
	ld		bc, EndTiles - Tiles	; number of bytes to copy
	call	memcpy

	; copy tiles to VRAM
	ld		hl, FontData				; source
	ld		de, _VRAM					; destination
	ld		bc, EndFontData - FontData	; number of bytes to copy
	call	mem_CopyMono

	; copy tile map to VRAM
	call	CopyTileMap

	; copy window tile map
	ld		hl, Text
	ld		de, _SCRN1			; map 1 location
	ld		bc, 32 * 32			; screen size
	call 	memcpy

	; load start screen toggle value
	ld		a, 0
	ld		[windowToggle], a

	; set current background offset
	ld 		a, 6
	ld 		[bgOffset], a
	ld 		a, 31
	ld 		[bgRightEdge], a
	ld 		a, 0
	ld 		[bgLeftEdge], a

	; clear Shadow OAM
	ld		a, 0		; put everything to zero
	ld		bc, 40 * 4	; 40 sprites, 4 bytes each = 160 bytes
	ld		hl, _SHADOW_OAM
	call 	memfill

	; Position screen rect
	ld		a, 0
	ld		[rSCY], a
	ld		[scrollY], a
	ld		[rSCX], a
	ld		[scrollX], a

	; configure and activate display
	ld		a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
	ld		[rLCDC], a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameLoop:
	call	ShowWindow
	call	ReadPad

.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; start VRAM dependent code

	; set camera scroll position
	ld		a, [scrollX]
	ld		[rSCX], a
	ld		a, [scrollY]
	ld		[rSCY], a

	call	$FF80 ; Call DMA Copy routine

	; end VRAM dependent code
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.waitForNotVBlank:
	ld		a, [rLY]
	cp		144
	jr		nc, .waitForNotVBlank

	jr		GameLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read button state into [padInput]
ReadPad:
	; check the d-pad
	ld		a, %00100000	; bit 4 to 0, 5 to 1 (Activate d-pad, not buttons)
	ld		[rP1], a		; button register

	; now we read the state of the d-pad, and avoid bouncing
	ld		a, [rP1]
	ld		a, [rP1]
	ld		a, [rP1]
	ld		a, [rP1]

	and		$0F		; only care about the lower 4 bits
	swap	a		; lower and upper combined
	ld		b, a	; save state in b

	; check buttons
	ld		a, %00010000	; bit 4 to 1, 5 to 0 (activated buttons, no d-pad)
	ld		[rP1], a

	; read several times to avoid bouncing
	ld		a, [rP1]
	ld		a, [rP1]
	ld		a, [rP1]
	ld		a, [rP1]

	; check A against buttons
	and		$0F	; only care about bottom 4 bits
	or		b	; or with b to 'meter' the d-pad status

	; now we have in A the state of all buttons, compliment and store variable
	cpl
	ld		[padInput], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ShowWindow:
	ld		a, [windowToggle]
	cp		0
	ret 	nz

	ld		a, 7
	ld		[rWX], a	; window x location

	ld		a, 0
	ld		[rWY], a	; window y location

	; activate windows and deactivate sprites
	ld		a, [rLCDC]		; load LCD control contents
	or		LCDCF_WINON		; check if window is on
	xor		LCDCF_BGOFF		; turn off background
	xor		LCDCF_OBJOFF	; turn off sprites
	res		1, a			; bit 1 to 0
	ld		[rLCDC], a

.CheckExit
	call	ReadPad
	and		%00001000	; start button
	jr		z, .CheckExit

.CloseWindow
	; turn off start screen toggle
	ld		a, 5
	ld		[windowToggle], a

	; deactivate the window and activate the sprites
	ld		a, [rLCDC]
	res		5, a			; reset window sprites to 0
	or		LCDCF_OBJON		; turn on objects
	or		LCDCF_BGON		; turn off background
	ld		[rLCDC], a		; apply changes
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CopyTileMap:
	ld		hl, MAIN_MAP
	ld		de, _SCRN0		; map 0 loaction
	ld		b, 32	; number of lines to copy

.copy_bg_row
	ld		a, b 	; do we have more lines to copy?
	cp 		0		; sets the flags
	ret 	z		; if zero, return

	dec 	b		; decrement the line count and save it
	push 	bc

	ld		bc, 32	; lines are 32 bytes
	call 	memcpy	; copy a line

	ld		bc, 96	; stride in the source
	add		hl, bc

	pop 	bc
	jr 		.copy_bg_row	; loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DMA Transfer routine
; writes the shadow OAM address to the DMA register and spins
; for 160 microseconds while the copy is done by hardware
DMACopy:
	ld		a, $C0		; $C0 is the first byte of the shadow OAM address
	ld		[rDMA], a	; initiate the copy
	ld		a, $28		; magic number of cycles to loop

	; loop until it's done.
.loop
	dec		a
	jr		nz, .loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; memory copy routine
; copy a number of bytes from one location to another
; assumes number of bytes is greater than 0
;
; parameters:
; 	bc: number of bytes to copy
; 	de: destination address
; 	hl: source address
memcpy:
	ld	a, [hl+]	; Load source data into a and post-increment the source pointer.
	ld	[de], a		; Write data to the destination.
	inc	de			; Increment the destination pointer.
	dec	bc			; Decrement the byte count.

	; Keep copying if bc is not zero.
	ld	a, b
	or	c
	jr	nz, memcpy

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; copy a monochrome font
; same as memcpy but it copies each byte to the destionation twice.
;
; input:
;   bc: number of bytes to copy
;   de: destination
;   hl: source address
mem_CopyMono:
	inc		b
	inc		c
	jr		.skip
.loop
	ld		a, [hl+]
	ld		[de], a
	inc		de
	ld		[de], a
	inc		de
.skip
	dec		c
	jr		nz,.loop
	dec		b
	jr 		nz,.loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fill memory
; write a specific byte value to a range of memory.
; 
; mangles a, b, c, h, l
;
; parameters:
; 	a: data to fill
; 	bc: number of bytes to fill
; 	hl: destination address
memfill:
	inc		b
	inc		c
	jr		.skip
.loop
	ld		[hl+], a
.skip
	dec		c
	jr		nz, .loop
	dec		b
	jr		nz, .loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Tiles:
	INCLUDE "maintiles.z80"
EndTiles:

Map:
	INCLUDE"mainmap.z80"
EndMap:

WindowStart:
	INCLUDE"windowstart.z80"
EndWindowStart:

Text:
	INCLUDE "text.inc"
TextEnd:

Text2:
	INCLUDE "text2.inc"
TextEnd:

FontData:
	chr_IBMPC1
EndFontData:
