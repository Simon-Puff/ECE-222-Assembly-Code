;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
		MOV			R10,#0				;Universal Register, used to avoid introducing delay when starting the program
; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 			; 0x2009C000 - the base address for dealing with the ports
		STR 		R3, [r4, #0x20]		; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

ResetLUT
		CMP			R10, #0				; This only work when the first time, afterwards R10 will be incremented by 1 each time,
										; it never equal to 0 anymore, which means introducing delay
		LDR			LR,=Return_LED_RESET; I put the return address to LR, and inside the subroutine, the last instruction will always be BX LR
		BL			LED_OFF				; Branch to LED_OFF
Return_LED_RESET
		MOV			R11, #4				; Since this is where we resets the char array, we need to introduce a 4 time delay
										; R11 is universal register for delay repeat times
		LDR			LR, =Return_Reset	; same as above, save the return address to the LR
		BNE			DELAY				; 
Return_Reset
		LDR         R5, =InputLUT       ; assign R5 to the address at label LUT

; Start processing the characters

NextChar
		CMP			R10, #0				; Recall that R10 is execution time counter
		LDR			LR,=Return_LED_CHAR
		BL			LED_OFF
Return_LED_CHAR		
		MOV			R11, #3				; Makes delay repeat 3 times
		LDR			LR, =Return_Next
		BNE			DELAY
Return_Next
		ADD			R10, #1			; this increments the pointer by one, why one? because each morse pattern is a word, and a word is 8-bit or 1 byte
        LDRB        R0, [R5]		; Read a character to convert to Morse Code
       	ADD         R5, #1          ; point to next value for number of delays, jump by 1 byte
		TEQ         R0, #0          ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE			ProcessChar		; If we have a character process it

		MOV			R0, #4			; delay 4 extra spaces (7 total) between words
		BL			DELAY
		BEQ         ResetLUT		; if equal to 0, which means we have gone through all characters, it will return to resetLUT to reset the pointer

ProcessChar	BL		CHAR2MORSE		; convert ASCII to Morse pattern in R1		

;*************************************************************************************************************************************************
;*****************  These are alternate methods to read the bits in the Morse code LUT. You can use them or not **********************************
;************************************************************************************************************************************************* 

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
		
		
LOOP_CHAR
		LSLS		R1, #1			; left shift by 1, if a carry out happen, PSR flag will be updated
		LDR			LR, =Return_CARRY
		BCS			LED_ON 			;turn on the LED if carry out is set
		BCC			LED_OFF 		;turn off the LED if carry out is clear
Return_CARRY
		MOV			R11, #1			; Set the delay repeat time by 1, representing one dot or dash
		BL			DELAY			
		TEQ			R1, #0			; test if the register is 0, which means we already have all bits being executed
		BNE			LOOP_CHAR; If not equal to, branch back to this loop to execute the next char again
		BEQ			NextChar; If equal to 0, request another char
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test starting at bit 15 for 1 or 0
;	Then loop thru all of the data bits:
;
;		MOV		R6, #0x8000	; Init R6 with the value for the bit, 15th, which we wish to test
;		LSL		R1, R1, #1	; shift R1 left by 1, store in R1
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;		BEQ		; branch somewhere it's zero
;		BNE		; branch somewhere - it's not zero
;
;		....  lots of code
;		B 		somewhere in your code! 	; This is the end of the main program 
;
;	Alternate Method #2
; Shifting the data left - makes you walk thru it to the right.  You may find this confusing!
; Instead of shifting data - shift the masking pattern.  Consider this and you may find that
;   there is a much easier way to detect that all data has been dealt with.
;
;		LSR		R6, #1		; shift the mask 1 bit to the right
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;
;
;	Alternate Method #3
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
;  of leading zeros (CLZ) and a shift left operation to remove those leading zeros.

;*************************************************************************************************************************************************
;
;
; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	
		STMFD		R13!,{R14}		; push Link Register (return address) on stack
		LDR			R7, =MorseLUT
		;
		;... add code here to convert the ASCII to an index (subtract 41) and lookup the Morse patter in the Lookup Table
		SUB			R0, #0x41 		; Sub by 41
		ADD			R0, R0			; Multiply by 2
		ADD			R7, R0			; Add the offset
		LDRH		R1, [R7]		; Load the morse pattern into R1, only the half matters so we loaded half
		CLZ			R2, R1			; Count leading 0s and store the count into R2
		LSL			R1, R1, R2		; Logic shift left several bits, the number of bits is stored in R2, making the leading (MSB) 1
		;
		LDMFD		R13!,{R15}		; restore LR to R15 the Program Counter to return


; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON 	   	
		push 		{r3-r4}			; preserve R3 and R4 on the R13 stack
		pop			{r3-r4}			; r3 and r4 is not used for any other purposes
		;... insert your code here
		MOV			R3, #0xA0000000	; the number which represents on
		STR			R3,[R4, #0x20]	
		;
		BX 			LR				; branch to the address in the Link Register.  Ie return to the caller

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF
		;STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		;... insert your code here
		MOV			R3, #0xB0000000
		STR			R3,[R4,#0x20]
		BX			LR				; branch to the address in the Link Register.  Ie return to the caller
		;LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around
;
DELAY
		;STMFD		R13!,{R2, R14}
		CMP			R11, #0			; Recall R11 is the universal counter, since this is a looping function, I put the compare here
		BEQ			Return_Function	; This links to a external label which helps to return to the location where delay is called
									; by doing so we can make conditional return will enjoying the simplicity of BX LR
		SUBS		R11, #1			; Sub by 1, keeping the counter in track
		;MOV			R8, #1		; debugg code
		MOV 		R8, #0x2C2A		; Initialized R0 lower word for countdown ( countdown # is set to initial counter - to match frequency of 1 Hz)
		MOVT		R8, #0xA		; assign 0xA to higher part	R0
loop
		SUBS 		R8, #1 			; Decrement r0 and set the N,Z,C status bits 
		BNE			loop			; Use BNE to set if content inside
		BEQ			DELAY			; This will be exectued when R8, which is the register for delay, is equal to 0, 
									; it will go back to the start of delay, and check if there is more delay cycle to execute
		
Return_Function
		BX			LR				; This is where the external return locates
		
		
;exitDelay		LDMFD		R13!,{R2, R15}

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
InputLUT	DCB		"RKMBD", 0	; strings must be stored, and read, as BYTES

		ALIGN				; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 
