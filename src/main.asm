; vim: tabstop=4 shiftwidth=4 noexpandtab ft=z80

; hardware definitions
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

_PLAYER_ANIM_SPEED	EQU		15
_PLAYER_MOVE_SPEED	EQU		1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ram
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shadow OAM addresses.  Some may not be used.
RSSET _RAM
_SHADOW_OAM	RB 0

playerY		RB 1	; Y Coord
playerX		RB 1	; X Coord
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
screenShakeX			RB 1
screenShakeY			RB 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BLOCK 1
; 128 bytes
; mostly for player data
RSSET _RAM_BLOCK_0 + 96
_RAM_BLOCK_1			RB 0

playerSprite			RB 1	; the player sprite number
playerDirection 		RB 1	; bit 0 = up/down, up = 1;  bit 1 = left/right, left = 1
playerAnimFrameTimer	RB 1	; how many cycles before we change animation frame

playerCollision			RB 1	; bit mask indicating collisions. %0000udlr

playerMoveTimer			RB 1	; how long before we should move the player

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_1 + 128
_RAM_BLOCK_2			RB 0

startScreenToggle		RB 1

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

; Header and start vector boilerplate
SECTION "header", ROM0[$0100]
	nop
	jp	Init

	; ROM Header (Macro defined in gbhw.inc)
	ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

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

	; copy	window tile map
	ld		hl, Text
	ld		de, _SCRN1			; map 1 location
	ld		bc, 32 * 32			; screen size
	call 	memcpy

	; load start screen toggle value
	ld		a, 0
	ld		[startScreenToggle], a

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

	; Set the initial state of the player.
	ld 		a, 60
	ld		[playerY], a
	ld		[playerX], a

	ld 		a, _PLAYER_ANIM_SPEED
	ld 		[playerAnimFrameTimer], a
	ld 		a, 0
	ld 		[playerSprite], a

	ld		hl, playerMoveTimer
	ld		[hl], _PLAYER_MOVE_SPEED

	; configure and activate display
	ld		a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
	ld		[rLCDC], a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameLoop:
	call	StartScreen
	call	CollidePlayer

	call	ReadPad
	call	Movement
	call	Facing
	call	AnimatePlayer
	call	RenderPlayer

.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; start VRAM dependent code

	ld		a, [scrollX]
	ld		[rSCX], a
	ld		a, [scrollY]
	ld		[rSCY], a
	call	CopyNewBGTiles
	call	$FF80 ; Call DMA Copy routine

	; end VRAM dependent code
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.waitForNotVBlank:
	ld		a, [rLY]
	cp		144
	jr		nc, .waitForNotVBlank

	jr		GameLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CopyNewBGTiles:
	; Early out if we don't need to draw a new bg column
	ld		a, [bgDrawDirection]
	cp		0
	ret		z

	; load the background map into bc
	ld		bc, MAIN_MAP
	ld		de, _SCRN0

.DrawBGCol:
	; check which direction we are drawing
	cp		_EAST
	jr		z, .DrawEast

.DrawWest:
	; get the destination in vram
	ld		a, [bgLeftEdge]
	ld		h,  0
	ld		l,  a
	add		hl, de
	ld		d, h
	ld		e, l

	push de

	; set the low index to offset-6
	ld		a, [bgOffset]
	ld		h, 0
	ld		l, a
	ld		de, 6
	add		hl, de
	add		hl, bc
	ld		b, h
	ld		c, l

	pop de

	ld		a, 16
	jr		.CopyBGColumn

.DrawEast:
	; get the destination in vram
	ld		a, [bgRightEdge]
	ld		h,  0
	ld		l,  a
	add		hl, de
	ld		d, h
	ld		e, l

	push de

	; set the high index to offset+20+6
	ld		a, [bgOffset]
	ld		h, 0
	ld		l, a
	ld		de, 26
	add		hl, de
	add		hl, bc
	ld		b, h
	ld		c, l

	pop de

	ld		a, 16

; a  - row count
; bc - source of our ROM data
; de - VRAM destination
.CopyBGColumn:
	ld		h, a

	; copy a byte
	ld		a, [bc]
	ld		[de], a

	ld		a, h

	; add 32 to the RAM destination
	ld		hl, 32
	add		hl, de
	ld		d, h
	ld		e, l

	; add 128 to the ROM source
	ld		hl, 128
	add		hl, bc
	ld		b, h
	ld		c, l

	dec		a
	ret		z
	jr		.CopyBGColumn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CollidePlayer:
	; compute the axis extents of the player
	; find the 9 surrounding tiles
	; determine if any should be considered blocked
	; for any blocked cells, compute if we touch.
	; if we touch, keep a record of that.

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RenderPlayer:
	; Compute the correct sprite number and write it to the OAM
	ld 		a, [playerDirection] ; has bit 1 set for left/right.  1 is left
	and		%00000001	; mask out the y-direction bit
	sla		a						; a *= 2
	ld		hl, playerSprite
	add		a, [hl]
	ld 		[_SPR0_NUM], a

	; Compute sprite attributes
	; byte 3 bit 5 for x-swap
	ld 		a, [playerDirection] ; has bit 1 set for left/right.  1 is left
	and		%00000010		; mask out the x-direction bit
	swap	a				; puts the x direction value in the x-flip attribute bit location
	or		%00010000		; additional flags
	ld		[_SPR0_ATT], a	; set the attributes

	; Reset the up/down flag so the player doesn't stay facing up
	ld		a, [playerDirection]
	and		%11111110	; Clear the up bit
	ld		[playerDirection], a

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AnimatePlayer:
	; If we have no input, just set it to the start sprite
	ld		a, [padInput]
	and		_PAD_LEFT | _PAD_RIGHT | _PAD_UP | _PAD_DOWN
	jr		z, .ResetAnim

	; check if it's time to switch frames
	ld		hl, playerAnimFrameTimer
	dec		[hl]
	ld		a, [hl]
	cp		0							; is it 0 yet?
	ret		nz							; if it is not, return (this is the delay)

	; reset the frame timer
	ld		[hl], _PLAYER_ANIM_SPEED

	; change the sprite
	ld		hl, playerSprite
	inc		[hl]

	; if the animation isn't over, return
	ld		a, [hl]
	cp		2
	ret		nz

.ResetAnim
	; reset the frame timer
	ld		hl, playerAnimFrameTimer
	ld		[hl], _PLAYER_ANIM_SPEED

	; retart aniamtion frame number
	ld		hl, playerSprite
	ld		[hl], 0
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Movement:
	ld		hl, playerMoveTimer
	dec		[hl]
	ret		nz
	ld		[hl], _PLAYER_MOVE_SPEED
	
.MoveRight
	ld		a, [padInput]
	and		_PAD_RIGHT
	call	nz, MoveRight

.MoveLeft
	ld		a, [padInput]
	and		_PAD_LEFT
	call	nz, MoveLeft

	ld		hl, playerY
.MoveUp
	ld		a, [padInput]
	and		_PAD_UP
	jr		z, .MoveDown
	dec		[hl]

.MoveDown
	ld		a, [padInput]
	and		_PAD_DOWN
	ret		z
	inc		[hl]
	ret

MoveLeft:
	; Check if we should move the screen or the player
	ld		hl, playerX
	ld		a, [hl]
	cp		32
	jp		z, .LeftScreen

	; Change player position
	dec		[hl]
	ret

	; Change screen position, load data if necessary
.LeftScreen
	call	ScrollLeft
	ret

MoveRight:
	; check for move edge
	ld		hl, playerX
	ld		a, [hl]
	cp		121
	jp		z, .RightScreen

	; update player position
	inc		[hl]
	ret

	; move scroll, load bg if necessary
.RightScreen
	call	ScrollRight
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Facing:
	ld		a, [playerDirection]
	ld		c, a
	ld		a, [padInput]
	ld		b, a

	; b has padInput
	; c has playerDirection
.FaceRight
	and		_PAD_RIGHT
	jr		z, .FaceLeft

	; Set the direction flag bit
	ld		a, c
	and		%11111101
	ld		c, a

.FaceLeft
	ld		a, b
	and		_PAD_LEFT
	jr		z, .FaceUp

	; Set the direction flag bit
	ld		a, c
	or		%00000010
	ld		c, a

.FaceUp
	ld		a, b
	and		_PAD_UP
	jr		z, .FaceDown

	; Set the direction flag bit
	ld		a, c
	or		%00000001
	ld		c, a

.FaceDown
	ld		a, b
	and		_PAD_DOWN
	ld		a, c	; doesn't clear zero flag and saves us some instructions doing it here.
	jr		z, .Save
	and		%11111110

.Save
	ld		[playerDirection], a
	ret

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
StartScreen:
	ld		a, [startScreenToggle]
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
	ld		[startScreenToggle], a

	; deactivate the window and activate the sprites
	ld		a, [rLCDC]
	res		5, a			; reset window sprites to 0
	or		LCDCF_OBJON		; turn on objects
	or		LCDCF_BGON		; turn off background
	ld		[rLCDC], a		; apply changes
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScrollRight:
	; increment X scroll
	ld		hl, scrollX
	ld		a, [hl]
	inc 	a
	ld 		[hl], a

	and		%00000111		; check if divisible by 8
	ret		nz

	; increment background vram east and west
	ld		hl, bgRightEdge
	ld		a, [hl]
	inc		a
	cp 		a, 32
	jr 		nz, .SaveEastInc
	ld 		a, 0
.SaveEastInc
	ld		[hl], a

	ld		hl, bgLeftEdge
	ld		a, [hl]
	inc		a
	cp		a, 32
	jr		nz, .SaveWestInc
	ld		a, 0
.SaveWestInc
	ld		[hl], a

	ld 		hl, bgOffset
	ld		a, [hl]
	inc		a
	cp		128
	jr		nz, .SaveOffsetInc
	ld		a, 0
.SaveOffsetInc
	ld 		[hl], a

	ld 		a, 1
	ld 		[bgDrawDirection], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScrollLeft:
	ld		hl, scrollX	; load a with screen x scroll
	ld		a, [hl]
	dec		a
	ld		[hl], a
	and		%00000111			; check if divisible by 8
	ret		nz

	; decrement background light vram east and west
.DecBgLight:
	ld		hl, bgRightEdge
	ld		a, [hl]
	cp 		a, 0
	jr		nz, .SaveEastDec
	ld		a, 32
.SaveEastDec
	dec		a
	ld		[hl], a

	ld		hl, bgLeftEdge
	ld		a, [hl]
	cp		a, 0
	jr		nz, .SaveWestDec
	ld		a, 32
.SaveWestDec
	dec		a
	ld		[hl], a

	ld		hl, bgOffset
	ld		a, [hl]
	dec		a
	cp		a, -1
	jr		nz, .SaveOffsetDec
	ld		a, 127
.SaveOffsetDec
	ld		[hl], a

	ld		a, 2
	ld		[bgDrawDirection], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tileMap copy routine
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


;***************************************************************************
;*
;* mem_Copy - "Copy" a monochrome font from ROM to RAM
;*
;* input:
;*   hl - pSource
;*   de - pDest
;*   bc - bytecount of Source
;*
;***************************************************************************
mem_CopyMono::
	inc	b
	inc	c
	jr	.skip
.loop	ld	a,[hl+]
	ld	[de],a
	inc	de
        ld      [de],a
        inc     de
.skip	dec	c
	jr	nz,.loop
	dec	b
	jr	nz,.loop
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
	inc	b
	inc	c
	jr	.skip
.loop	ld	[hl+],a
.skip	dec	c
	jr nz, .loop
	dec	b
	jr nz, .loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SPRITE FILES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

FontData:
	chr_IBMPC1
EndFontData:

; End Screen
; EndScreen:
; INCLUDE"endscreen.z80"
; EndEndScreen:
