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

; Game Screens
_INTRO		  EQU	0
_CHOOSE_STORY EQU	1
_READ_STORY	  EQU	2
_CHOOSE_CARD  EQU	3
_READ_CARD	  EQU	4
_OUTRO		  EQU	5

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

padOldState				RB 1	; The last frame's input from the d-pad and buttons
padState				RB 1	; The input from the d-pad and buttons
padDown					RB 1	; Bits are set here the first frame a button is pressed
padUp					RB 1	; Bits are set here the first frame a button is released

bgDrawDirection			RB 1	; Which direction of the background do we draw, 1 = east, 2 = west
bgOffset				RB 1	; how far to the right (in tiles) is our leftmost tile in data
bgRightEdge				RB 1 	; where are we writing our next east tile 0-31
bgLeftEdge				RB 1 	; where are we writing our next west tile 0-31

scrollX					RB 1
scrollY					RB 1

currentScreen			RB 1	;What screen are we on

isPyramidsLoaded		RB 1

tileBytesToLoadHigh		RB 1	;What tiles to load on the next VBlank
tileBytesToLoadLow		RB 1
tileBytesToLoadSizeHigh	RB 1
tileBytesToLoadSizeLow	RB 1

mapAddressHigh			RB 1
mapAddressLow			RB 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RSSET _RAM_BLOCK_0 + 96
_RAM_BLOCK_1			RB 0

isWindowVisible			RB 1
wantWindowVisible		RB 1

currentTextPage			RB 1
desiredTextPage			RB 1

imageNum				RB 1

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

	ld		a, 0
	ld		[$FF4F], a

	; copy tiles to VRAM
	;ld		hl, FontData				; source
	;ld		de, _VRAM					; destination
	;ld		bc, EndFontData - FontData	; number of bytes to copy
	;call	mem_CopyMono
	
	ld		a, 0
	ld		[desiredTextPage], a

	; copy window tile map
	ld		hl, Text
	ld		de, _SCRN1			; map 1 location
	ld		bc, 32 * 32			; screen size
	call 	memcpy

	; load start screen toggle value
	ld		a, 0
	ld		[wantWindowVisible], a

	ld		a, 0
	ld		[imageNum], a

	; set current background offset
	ld 		a, 6
	ld 		[bgOffset], a
	ld 		a, 31
	ld 		[bgRightEdge], a
	ld 		a, 0
	ld 		[bgLeftEdge], a

	; clear pad input state
	ld		a, 0
	ld		[padState], a
	ld		[padOldState], a
	ld		[padDown], a
	ld		[padUp], a

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
	
;Clear local variables
	ld a, _CHOOSE_STORY
	ld [currentScreen], a
	
	ld a, 1
	ld [isPyramidsLoaded], a

	ld a, 0
	ld [tileBytesToLoadHigh], a
	ld [tileBytesToLoadLow], a
	ld [tileBytesToLoadSizeHigh], a
	ld [tileBytesToLoadSizeLow], a
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameLoop:

;LoadTiles cleanup, so we don't load tiles every frame
.loadTilesCleanup:
	ld a, 0
	ld [tileBytesToLoadSizeHigh], a
	ld [tileBytesToLoadSizeLow], a

.doneTilesCleanup:	
	call	ReadPad
	call	DetectPadEvents
	call 	GregTempCode
	
;Pre-VBlank Load variables for when VBlank is done
	call PreVBlank
	
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; start VRAM dependent code
	
	;Check if there are any bytes to copy, if not, bail
.testLoadTiles:
	ld a, b
	or c
	jp z, .doneLoadTiles
.loadTiles:
	call memcpy
.loadMap:
	ld a, [mapAddressHigh]
	ld h, a
	ld a, [mapAddressLow]
	ld l, a
	call CopyTileMap
.doneLoadTiles:	
	
	; set camera scroll position
	ld		a, [scrollX]
	ld		[rSCX], a
	ld		a, [scrollY]
	ld		[rSCY], a

	call	UpdateWindowVisibility
	call	UpdateTextMap
	call	$FF80 ; Call DMA Copy routine

	; end VRAM dependent code
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.waitForNotVBlank:
	ld		a, [rLY]
	cp		144
	jr		nc, .waitForNotVBlank
		
	jr		GameLoop
	
	;END MAIN LOOP
	
;;Gameplay content loading commands

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Temp main loop code:
GregTempCode:
	;Temp Code : pyramids and scuba toggle
	
	ld a, [padDown]
	cp 0
	ret z

; bump image num
	ld hl, imageNum
	ld a, [hl]
	inc a
	ld [hl], a


	cp 11
	jr nz, .nomod
	sub 10
	ld [hl], a

.nomod:
	cp 1
	jr z, .image1
	cp 2
	jr z, .image2
	cp 3
	jr z, .image3
	cp 4
	jr z, .image4
	cp 5
	jr z, .image5
	cp 6
	jr z, .image6
	cp 7
	jr z, .image7
	cp 8
	jr z, .image8
	cp 9
	jr z, .image9
	cp 10
	jr z, .image10
	ret

.image1 ; airplane
	call LoadAirplane
	ret
.image2 ; sand dunes
	call LoadSandDunes
	ret
.image3 ; falls
	call LoadFalls
	ret
.image4 ; island
	call LoadIsland
	ret
.image5 ; killi
	call LoadKilli
	ret
.image6 ; safari
	call LoadSafari
	ret
.image7 ; scuba
	call LoadScuba
	ret
.image8 ; pyramids
	call LoadPyramids
	ret
.image9 ; cross
	call LoadCross
	ret
.image10 ; erta ale
	call LoadErta
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Code to save cycles in VBlank. Must be executed immediately before the VBlank check in main loop.
PreVBlank:
.loadTilesPrep:
	ld a, [tileBytesToLoadSizeHigh]
	ld b, a
	ld a, [tileBytesToLoadSizeLow]
	ld c, a
	ld a, [tileBytesToLoadHigh]
	ld h, a
	ld a, [tileBytesToLoadLow]
	ld l, a
	ld de, _VRAM
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAirplane:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, AirplanePalette
	call	LoadPalette
	; copy tiles
	ld bc, AirplaneTilesEnd - AirplaneTiles
	ld de, _VRAM
	ld hl, AirplaneTiles
	call memcpy

	; copy map to VRAM
	ld		hl, AirplaneWindowLabelPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, AirplaneWindowLabelPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadSandDunes:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, SandDunesPalette
	call	LoadPalette
	; copy tiles
	ld bc, SandDunesTilesEnd - SandDunesTiles
	ld de, _VRAM
	ld hl, SandDunesTiles
	call memcpy

	; copy map to VRAM
	ld		hl, SandDunesPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, SandDunesPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadFalls:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, FallsPalette
	call	LoadPalette
	; copy tiles
	ld bc, FallsTilesEnd - FallsTiles
	ld de, _VRAM
	ld hl, FallsTiles
	call memcpy

	; copy map to VRAM
	ld		hl, FallsPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, FallsPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadIsland:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, IslandPalette
	call	LoadPalette
	; copy tiles
	ld bc, IslandTilesEnd - IslandTiles
	ld de, _VRAM
	ld hl, IslandTiles
	call memcpy

	; copy map to VRAM
	ld		hl, IslandPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, IslandPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadKilli:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, KilliPalette
	call	LoadPalette
	; copy tiles
	ld bc, KilliTilesEnd - KilliTiles
	ld de, _VRAM
	ld hl, KilliTiles
	call memcpy

	; copy map to VRAM
	ld		hl, KilliPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, KilliPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadSafari:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, SafariPalette
	call	LoadPalette
	; copy tiles
	ld bc, SafariTilesEnd - SafariTiles
	ld de, _VRAM
	ld hl, SafariTiles
	call memcpy

	; copy map to VRAM
	ld		hl, SafariPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, SafariPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadErta:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, ErtaAlePalette
	call	LoadPalette
	; copy tiles
	ld bc, ErtaAleTilesEnd - ErtaAleTiles
	ld de, _VRAM
	ld hl, ErtaAleTiles
	call memcpy

	; copy map to VRAM
	ld		hl, ErtaAlePLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, ErtaAlePLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret





LoadPyramids:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, PyramidPalette
	call	LoadPalette

	; copy tiles
	ld bc, PyrmaidsTilesEnd - PyrmaidsTiles
	ld de, _VRAM
	ld hl, PyrmaidsTiles
	call memcpy

	; copy map to VRAM
	ld		hl, PyramidLabelPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, PyramidLabelPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadCross:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, CrossPalette
	call	LoadPalette
	; copy tiles
	ld bc, CrossTilesEnd - CrossTiles
	ld de, _VRAM
	ld hl, CrossTiles
	call memcpy

	; copy map to VRAM
	ld		hl, CrossLabelPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, CrossLabelPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

LoadScuba:

;;;;;;;;;;;;;;;;;;;;
.waitForVBlank:
	ld		a, [rLY]
	cp		144
	jr		c, .waitForVBlank

	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;

	ld		a, 0
	ld		[$FF4F], a

	ld		hl, ScubaPalette
	call	LoadPalette
	; copy tiles
	ld bc, ScubaTilesEnd - ScubaTiles
	ld de, _VRAM
	ld hl, ScubaTiles
	call memcpy

	; copy map to VRAM
	ld		hl, ScubaMapPLN0
	call	CopyTileMap

	ld		a, 1
	ld		[$FF4F], a

	ld		hl, ScubaMapPLN1
	call	CopyTileMap

	ld		a, 0
	ld		[$FF4F], a

;;;;;;;;;;;;;;;;;;;;
	pop		af
	ld		[rLCDC], a
;;;;;;;;;;;;;;;;;;;;
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read button state into [padState]
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
	ld		[padState], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DetectPadEvents:
	; put current pad state in b
	ld		a, [padState]
	ld		b, a

	ld		a, [padOldState]
	xor		b
	and		b
	ld		[padDown], a

	ld		a, [padOldState]
	ld		c, a
	xor		b
	and		c
	ld		[padUp], a

	ld		a, [padState]
	ld		[padOldState], a

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateTextMap:
	ld		a, [currentTextPage]
	ld		b, a
	ld		a, [desiredTextPage]
	cp		b

	ret		z	; already on the correct page
	
	cp		0
	jr		z, .Text2

.Text1:
	ld		[currentTextPage], a

	ld		hl, Text
	jr		.Copy

.Text2:
	ld		[currentTextPage], a

	ld		hl, Text2

.Copy:
	; turn off LCD because this takes too long to do in a single vblank
	ld		a, [rLCDC]
	push	af
	ld		a, LCDCF_OFF
	ld		[rLCDC], a

	ld		de, _SCRN1			; map 1 location
	ld		bc, 32 * 32			; screen size
	call 	memcpy
	
	pop		af
	ld		[rLCDC], a

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateWindowVisibility:
	ld		a, [isWindowVisible]
	ld		b, a
	ld		a, [wantWindowVisible]

	; if the visibility flag matches what we want, return
	cp		b
	ret 	z

	cp		0
	jr		z, .CloseWindow

	ld		a, 1
	ld		[isWindowVisible], a

	ld		a, 7
	ld		[rWX], a	; window x location

	ld		a, 0
	ld		[rWY], a	; window y location

	; activate windows and deactivate sprites
	ld		hl, rLCDC
	ld		a, [hl]		; load LCD control contents
	set		5, a			; turn on window
	res		0, a			; turn off background
	res		1, a			; turn off sprites
	ld		[hl], a

	ret

.CloseWindow
	ld		a, 0
	ld		[isWindowVisible], a

	; deactivate the window and activate the sprites
	ld		hl, rLCDC
	ld		a, [hl]		; load LCD control contents
	res		5, a			; turn off window
	set		0, a			; turn on background
	set		1, a			; turn on sprites
	ld		[hl], a

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CopyTileMap:
	ld		de, _SCRN0		; map 0 loaction
	ld		b, 18	; number of lines to copy

.copy_bg_row
	ld		a, b 	; do we have more lines to copy?
	cp 		0		; sets the flags
	ret 	z		; if zero, return

	dec 	b		; decrement the line count and save it
	push 	bc

	ld		bc, 20	; lines are 20 bytes
	call 	memcpy	; copy a line
	
	push	hl
	ld		hl, 12
	add     hl, de
	ld		d, h
	ld		e, l
	pop		hl

	pop 	bc
	jr 		.copy_bg_row	; loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Expects palette address on hl
LoadPalette:
	; palette colors
	; BGR 555  %0bbbbbgggggrrrrr
	ld		a, %10000000
	ld		[rBGPI], a
	REPT	64
	ld		a, [hl+]
	ld		[rBGPD], a
	ENDR

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

Text:
	INCLUDE "text.inc"
TextEnd:

Text2:
	INCLUDE "text2.inc"
Text2End:

UITiles:
	INCLUDE "UiTiles.inc"
UITilesEnd:

;Tiles and Maps for Large Images

;Intro
INCLUDE "AirplaneWindowTiles.inc"
INCLUDE "AirplaneWindowTiles.z80"
INCLUDE "AirplaneWindowMap.z80"

INCLUDE "SandDunesTiles.inc"
INCLUDE "SandDunesTiles.z80"
INCLUDE "SandDunesMap.z80"

INCLUDE "FallsTiles.inc"
INCLUDE "FallsTiles.z80"
INCLUDE "FallsMap.z80"

INCLUDE "IslandTiles.inc"
INCLUDE "IslandTiles.z80"
INCLUDE "IslandMap.z80"

INCLUDE "KilliTiles.inc"
INCLUDE "KilliTiles.z80"
INCLUDE "KilliMap.z80"

INCLUDE "SafariTiles.inc"
INCLUDE "SafariTiles.z80"
INCLUDE "SafariMap.z80"

INCLUDE "ScubaTiles.inc"
INCLUDE "ScubaTiles.z80"
INCLUDE "ScubaMap.z80"

INCLUDE "PyramidsTiles.z80"
INCLUDE "PyramidMap.z80"
INCLUDE "PyramidsTiles.inc"

INCLUDE "CrossTiles.inc"
INCLUDE "CrossTiles.z80"
INCLUDE "CrossMap.z80"

INCLUDE "ErtaAleTiles.inc"
INCLUDE "ErtaAleTiles.z80"
INCLUDE "ErtaAleMap.z80"

; Additional Maps

INCLUDE "TestMap.z80"

LocationCursor:
	INCLUDE "LocationSelector.inc"
LocationCursorEnd:
	
FontData:
	chr_IBMPC1
EndFontData:
