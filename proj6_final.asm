TITLE Portfolio Assignment     (template.asm)

; Author: Alex DeWald
; Last Modified: 3-15-2020
; OSU email address: dewalda@Oregonstate.edu
; Course number/section: CS271-401
; Project Number: Program #6               Due Date: 3-15-2020
; Description: Reads 10 signed integer strings from the user and converts each digit to numeric.
;	The converted numeric integers are then stored in an array. Then the sum and average of all
;	the numeric integers is calulcated and stored into a memory location. Finally, the entered 
;	integers are converted back to strings and displayed in the order entered. The sum and average
;	numeric values are also converted back to strings and displayed.
; Implementation notes:
;	This program is implemented using procedures and macros.
;	All data variables are passed as paramters for each procedure and macro.

INCLUDE Irvine32.inc

;----------------------
; Macro mgetString
; A macro to get a 14 byte string from user input and store the string length.
; Pre-conditions: parameter prompt: address of prompt text to display
;				  parameter location: address of BYTE memory location to store string
;				  parameter length: adress of memory location to store string length
; Post-conditions: None
; Registers changed: None (push/pop save)
;-----------------------
mgetString	MACRO	prompt, location, length
	push	edx
	push	esi
	push	ecx
	push	eax
	mov		edx, prompt		;@ of user prompt in edx
	call	WriteString
	mov		ecx, 14			;max string size 14
	mov		edx, location	;@ of string storage mem location in edx
	call	ReadString
	mov		esi, length		;@ of string length mem location in esi
	mov		[esi], eax		; string length stored in mem location
	pop		eax
	pop		ecx
	pop		esi
	pop		edx
ENDM
;----------------------
; Macro mdisplayString
; A macro that displays a string.
; Pre-conditions: parameter buffer: offset of memory location of string to display
; Post-conditions: None
; Registers changed: None (push/pop save)
;-----------------------
mdisplayString	MACRO	buffer
	push	edx
	mov		edx, buffer		;@string to display in edx
	call	WriteString
	pop		edx
ENDM

.data
intro_1			BYTE	"Portfolio: Low-level I/O procedures						Alex DeWald",0
intro_2			BYTE	"Enter 10 signed decimal integers.",0
intro_3			BYTE	"The number entered must be able to fit in a 32-bit register.",0
intro_4			BYTE	"A list of the integers entered will then be displayed, their sum, and rounded average.",0
prompt_1		BYTE	"Please enter a signed number: ",0
error_1			BYTE	"ERROR: Did not enter a signed number or number was too big.",0
display_1		BYTE	"The following numbers were entered:",0
display_2		BYTE	"The sum of these numbers is: ",0
display_3		BYTE	"The rounded average is: ",0
goodbye			BYTE	"Thank you for using this program.",0
spacing			BYTE	", ",0
int_array		SDWORD	10	DUP(?)
string_holder	BYTE	14 DUP(?)		; set to 14 to account for some leading 0's
string_length	BYTE	?
array_sum		SDWORD	?
array_avg		SDWORD	?

.code
main PROC
push	OFFSET	intro_1
push	OFFSET	intro_2
push	OFFSET	intro_3
PUSH	OFFSET	intro_4
call	introduction

push	OFFSET	error_1
push	OFFSET	int_array
push	OFFSET	string_holder
push	OFFSET	string_length
push	OFFSET	prompt_1
call	ReadVal

push	OFFSET int_array
push	OFFSET array_sum
push	OFFSET array_avg
call	array_sum_avg

push	array_sum
push	array_avg
push	OFFSET	display_1
push	OFFSET	display_2
push	OFFSET	display_3
push	OFFSET	spacing
push	OFFSET	string_holder
push	OFFSET	int_array
call	displayResults

push	OFFSET	goodbye
call	displayBye


	exit	; exit to operating system
main ENDP
;-------------------------
; Procedure introduction
;		STACK FRAME
;		@intro_1    +48
;		@intro_2    +44
;		@intro_3    +40
;		@intro_4    +36
;		ret intro   +32
;		genregs		ebp
;	
; Procedure to display program introduction.
; Receives parameters on system stack in order: @ of intro_1,
; @ of intro_2, @ of intro_3, @ of intro_4
; Pre-conditions: None
; Post-conditions: None
; Registers changed: None (pushad/popad)
;--------------------------
introduction PROC
	pushad
	mov		ebp, esp
	mdisplayString	[ebp+48]
	call	CrLf
	mdisplayString	[ebp+44]
	call	CrLf
	mdisplayString	[ebp+40]
	call	CrLf
	mdisplayString	[ebp+36]
	call	CrLf
	popad
	ret 16		;cleaning up stack
introduction ENDP
;-------------------------
; Procedure ReadVal
;		STACK FRAME
;		@error			+52
;		@int_array		+48
;		@string_holder	+44
;		@string_length	+40
;		@prompt_1		+36
;		ret intro		+32
;		genregs			ebp
;		mul_factor		-4
;	
; Procedure that gets user's inputted string of digits, converts to numeric, validates, and stores in an array.
; Receives parameters on system stack in order: @ of error(message),
;@ of int_array, @ of string_holder, @ of string_length, @ of prompt_1
; Pre-conditions: None
; Post-conditions: string_holder contains last user entered number string
; Registers changed: None (pushad/popad)
;--------------------------
mul_factor	EQU	DWORD	PTR [ebp-4]		; = 10 for conversion
ReadVal PROC
	pushad
	mov		ebp, esp
	sub		esp, 4				; creating space for mul_factor local var
	mov		mul_factor, 10
	mov		esi, [ebp+44]		; @string_holder in esi
	mov		edi, [ebp+48]		; @int_array in edi
	call	CrLf
	mov		ecx, 10				; loop counter for 10 numbers
	cld
getValues:
	;main loop to get 10 numbers
	mov		esi, [ebp+44]		; @string_holder in esi
	push	ecx
	push	esi
	mgetString	[ebp+36], [ebp+44], [ebp+40]	;using getString macro to read input
	mov		esi, [ebp+40]		; @string_length in esi
	mov		edx, [esi]			; value of string_length in edx
	pop		esi					; @string_holder in esi
	mov		ecx, edx			; setting inner loop counter to string length
	mov		eax, 0
	mov		edx, 0				;used as accumulator
	lodsb
	cmp		al, "-"				; check if number is negative
	je		signedneg
	cmp		al, "+"
	je		signed				; if positive with "+", load next byte and ignore "+""
convert:
	;inner loop that converts a positive signed number
	push	eax			;saves ascii in eax if error throws
	cmp		al, "+"		;validate for ascii 0-9
	je		error
	cmp		al, "9"
	jg		error
	cmp		al, "0"
	jl		error
	pop		eax
	sub		al, 48		;convert ascii to numeric digit value
	push	eax			;save eax if error throws
	mov		eax, edx	;moving accumulated number to eax for *10
	mul		mul_factor
	jo		error
	mov		edx, eax	;storing accumulated number*10 to edx
	pop		eax
	add		edx, eax	;adding single digit to accumulator/edx
	push	eax			;save eax if error throws
	jo		error
	js		error
	pop		eax
	dec		ecx			
	lodsb
	cmp		ecx, 0
	jne		convert
	mov		eax, 2147483647		;compare to max signed positive 
	push	eax
	cmp		edx, eax
	jg		error
	pop		eax
	mov		[edi], edx			;storing converted number to int_array
	add		edi, 4
	pop		ecx
	dec		ecx
	cmp		ecx, 0
	jne		getValues			;back to main loop
	jmp		endRead
signed:
	;skips "+"
	dec		ecx
	lodsb
	jmp		convert
signedneg:
	;inner loop that converts a negative signed number
	lodsb				;lodsb at beginning to ignore "-"
	push	eax			;save eax if error throws
	cmp		al, "9"		;validating for ascii 0-9
	jg		error
	cmp		al, "0"
	jl		error
	pop		eax
	sub		al, 48		;convert ascii to numeric digit value
	push	eax			;saving eax if error throws
	mov		eax, edx	;moving accumulated number to eax for *10
	mul		mul_factor
	jo		error
	mov		edx, eax	;storing accumulated number*10 to edx
	pop		eax
	add		edx, eax	;adding single digit to accumulator/edx
	dec		ecx
	cmp		ecx, 1
	jne		signedneg
	push	eax			;save eax if error throws
	not		edx			;two's complement
	add		edx, 1
	jns		error		;checking for sign flag
	pop		eax
	cmp		edx, 0		;check for a -0 value error
	push	eax
	je		error
	pop		eax
	mov		[edi], edx	;moving signed negative num to int_array
	add		edi, 4
	pop		ecx
	dec		ecx
	cmp		ecx, 0
	jne		getValues	;back to main loop
	jmp		endRead
error:
	pop		eax
	mdisplayString	[ebp+52]	;display error message
	call	CrLf
	pop		ecx
	jmp		getValues		;re-do user input
endRead:
	mov		esp, ebp		;cleaning up local variable
	popad
	ret		20				;cleaning up stack
ReadVal ENDP
;-------------------------
; Procedure array_sum_avg
;		STACK FRAME
;		@int_array		+44
;		@array_sum		+40
;		@array_avg		+36
;		ret @			+32
;		genregs			ebp
;		div_factor		-4
;	
; Procedure to calculate sum and average of signed integer array.
; Receives parameters on system stack in order: @ of int_array,
; @ of arra_sum, @ of array_avg
; Pre-conditions: ReadVal must be called prior/int_array filled
; Post-conditions: None
; Registers changed: None (pushad/popad)
;--------------------------
div_factor	EQU	DWORD	PTR [ebp-4]		;=10 for conversion
array_sum_avg PROC
	pushad
	mov		ebp, esp
	sub		esp, 4				;creating space for div_factor local var
	mov		div_factor, 10
	mov		esi, [ebp+44]		;@int_array in esi
	mov		ecx, 10				;loop counter for 10 numbers
	mov		edx, 0
	mov		eax, 0				;used as accumulator
sumLoop:
	mov		edx, [esi]			;int_array value in edx
	add		eax, edx			;add signed integer to accumulator
	add		esi, 4
	LOOP	sumLoop
average:
	mov		edi, [ebp+40]		;@array_sum in edi
	mov		[edi], eax			;store sum in array_sum
	mov		edx, 0
	cdq							;convert to quadword for division
	idiv	div_factor
	mov		edi, [ebp+36]		;@array_avg in edi
	mov		[edi], eax			;store average in array_avg
	mov		esp, ebp			;clean up local variable
	popad
	ret		12					;cleaning up stack
array_sum_avg ENDP
;-------------------------
; Procedure writeVal
;		STACK FRAME
;		@string_holder	+40
;		signedInt(val)	+36
;		ret intro		+32
;		genregs			ebp
;		mul_factor		-4
;		div_factor		-8
; Procedure to convert numeric signed integer to string and display the string.
; Receives parameters on system stack in order: @ of string_holder,
; val of signedInt
; Pre-conditions: None
; Post-conditions: string_holder contains signedInt BYTE string
; Registers changed: None (pushad/popad)
;--------------------------	
div_factor	EQU	DWORD	PTR [ebp-4]		;=10 for conversion
WriteVal PROC
	pushad
	mov		ebp, esp
	sub		esp, 4				;creating space for local var div_factor
	mov		div_factor, 10
	mov		edi, [ebp+40]		;@string_holder in edi
	mov		ecx, 14
	cld
	mov		eax, [ebp+36]		;@signedInt in eax
	cmp		eax, 0				;checking is signed num is positive/negative
	jge		positive
	not		eax					;creating two's complement
	add		eax, 1
	jmp		negative
positive:
	;converts a positive signed number to string
	mov		edx, 0
	idiv	div_factor
	add		edx, 48			;converting numeric digit to ascii
	push	edx				;pushing each digit onto the stack from L-->R
	dec		ecx
	cmp		eax, 0			;check if all digits have been converted
	jg		positive
	mov		edx, ecx		;move remaining loop counter to edx
	mov		eax, 14			;moving loop counter original val to eax
	sub		eax, ecx		;finding difference/how many digits were converted
	mov		ecx, eax		;set loop counter to how many digits converted
stackLoop1:
	pop		eax				;pop each digit in reverse to store
	stosb	
	LOOP	stackLoop1
	mov		eax, 0			;storing null terminator 
	stosb
	jmp		endWrite
negative:
	;converts a negative signed number to string
	mov		edx, 0
	idiv	div_factor
	add		edx, 48		;converting numeric digit to ascii
	push	edx			;pushing each digit onto the stack from L-->R
	dec		ecx
	cmp		eax, 0		;check if all digits have been converted
	jg		negative
	mov		edx, ecx	;move remaining loop counter to edx
	mov		eax, 14		;moving loop counter original val to eax
	sub		eax, ecx	;finding difference/how many digits were converted
	mov		ecx, eax	;set loop counter to how many digits converted
	mov		al, 45		;store "-" ascii at beginning of string
	stosb
stackLoop2:
	pop		eax			;pop each digit in reverse to store
	stosb
	LOOP	stackLoop2
	mov		eax, 0		;storing null terminator
	stosb

endWrite:
	mdisplayString	[ebp+40]	;macro displays @stringholder
	mov		esp, ebp			;cleaning up local var
	popad
	ret		8					;cleaning up stack
WriteVal ENDP
;-------------------------
; Procedure displayResults
;		STACK FRAME
;		array_sum(val)	+64
;		array_avg(val)	+60
;		@display_1		+56
;		@display_2		+52
;		@display_3		+48
;		@spacing		+44
;		@string_holder	+40
;		@int_array		+36
;		ret intro		+32
;		genregs			ebp
;	
; Procedure to display user input results.
; Receives parameters on system stack in order: array_sum val,
; array_avg val, @ of display_1, @ of display_2, @ of display_3
; @ of spacing, @ of string_holder, @ of int_array
; Pre-conditions: array_sum, array_avg, and int_array must be filled prior
; Post-conditions: string_holder contains array_avg value string
; Registers changed: None (pushad/popad)
;--------------------------
displayResults PROC
	pushad
	mov		ebp, esp
	call	CrLf
	mdisplayString	[ebp+56]	;display numbers entered: text
	call	CrLf
	mov		esi, [ebp+36]		;@int_array in esi
	mov		ecx, 10
arrayLoop:
	;displays the signed integers held in int_array as strings
	push	[ebp+40]			;parameter @string_holder
	push	[esi]				;parameter value of int_array[0-9]
	call	WriteVal			;convert integer to string and display
	cmp		ecx, 1
	je		sum
	mdisplayString	[ebp+44]	;display spacing text
	add		esi, 4
	LOOP	arrayLoop
sum:
	;displays the sum of user entered signed integers
	call	CrLf
	mdisplayString	[ebp+52]	;display sum: text
	push	[ebp+40]			;parameter @string_holder 
	push	[ebp+64]			;parameter value of array_sum
	call	WriteVal			;convert array sum to string and display
	call	CrLf
median:
	mdisplayString	[ebp+48]	;display avg: text
	push	[ebp+40]			;parameter @string_holder
	push	[ebp+60]			;parameter value of array_avg
	call	WriteVal			;convert array avg to string and display
	popad
	ret		32					;cleaining up the stack
displayResults ENDP
;-------------------------
; Procedure displayBye
;		STACK FRAME
;		@goodbye		+36
;		ret intro		+32
;		genregs			ebp
;	
; Procedure to display a farewell.
; Receives parameter on system stack of: @ of goodbye
; Pre-conditions: None
; Post-conditions: None
; Registers changed: None (pushad/popad)
;-------------------------
displayBye	PROC
	pushad
	mov		ebp, esp
	call	CrLf
	call	CrLf
	mdisplayString	[ebp+36]	;display @goodbye text
	popad
	ret		4					;cleaning up the stack
displayBye	ENDP

END main
