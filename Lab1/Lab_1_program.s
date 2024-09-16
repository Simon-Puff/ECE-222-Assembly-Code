;*----------------------------------------------------------------------------
;* Name:    Lab_1_program.s 
;* Purpose: This code flashes one LED at approximately 1 Hz frequency 
;* Author: 	Rayan Kaleem Mohammed , Bowen Deng
;*----------------------------------------------------------------------------*/
	THUMB		; Declare THUMB instruction set 
	AREA		My_code, CODE, READONLY 	; 
	EXPORT		__MAIN 		; Label __MAIN is used externally q
	ENTRY 
__MAIN
; The following operations can be done in simpler methods. They are done in this 
; way to practice different memory addressing methods. 
; MOV moves into the lower word (16 bits) and clears the upper word
; MOVT moves into the upper word
; show several ways to create an address using a fixed offset and register as offset
;   and several examples are used below
; NOTE MOV can move ANY 16-bit, and only SOME >16-bit, constants into a register
; BNE and BEQ can be used to branch on the last operation being Not Equal or EQual to zero
;
	MOV 		R2, #0xC000		; move 0xC000 into R2
	MOV 		R4, #0x0		; init R4 register to 0 to build address
	MOVT 		R4, #0x2009		; assign 0x2009 into R4
	ADD 		R4, R4, R2 		; add 0xC000 to R4 to get 0x2009C000 

	MOV 		R3, #0x0000007C	; move initial value for port P2 into R3 
	STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

	MOV 		R3, #0xB0000000	; move initial value for port P1 into R3
	STR 		R3, [R4, #0x20]	; Turn off three LEDs on Port 1 using an offset

	MOV 		R2, #0x20		; put Port 1 offset into R2 for user later

refill ; The below two instructions are used to reset the R0 register as a counter
	MOV 		R0, #0x2C2A		; Initialized R0 lower word for countdown ( countdown # is set to initial counter - to match frequency of 1 Hz)
	MOVT		R0, #0xA		; assign 0xA to higher part	R0

loop
	SUBS 		R0, #1 			; Decrement r0 and set the N,Z,C status bits 
	
	BNE		loop			; Use BNE to set if content inside 
	
	EOR 		R3, R3, #0x10000000  ; We use EOR to toggle the 28th bit of the register, which can control the on and off state of the LED we want 
	STR 		R3, [R4, R2] 		; write R3 port 1, YOU NEED to toggle bit 28 first
	

	B	refill ; We are creating a infinite loop, since the branch instruction did not require a PSR flags status, therefore it will branch infinitely 
 	
	END 
		

; Hand Assembly (Post lab) Machine Langugae
; ADD R4,R4,R2  1110 00 0 0100 0 0100 0100 00000000 0010

; Process of finding this hand Assembly:
; 1110 - condition is set as (AL) - because it will always execute
; 00 0 - first 2 are given in the appendix and 3rd 0 is RI - because it bits to register 
; 0100 - OP Code for ADD
; 0 -set to 0 because condition flags are not needed to be set
; 0100 - operand register - R4 so binary value of 4
; 0100 - Destination register - R4 so binary value of 4
; 00000000 - shift 
; 0010 - Operand 2 register - R2 - binary value of 2








;