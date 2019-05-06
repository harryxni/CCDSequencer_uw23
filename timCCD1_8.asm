;Miscellaneous CCD control routines, common to all detector types
;Copyright (C) 2019 Pitam Mitra
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU Affero General Public License as published
;by the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU Affero General Public License for more details.

;You should have received a copy of the GNU Affero General Public License
;along with this program. If not, see <https://www.gnu.org/licenses/>.

POWER_OFF
	JSR	<CLEAR_SWITCHES_AND_DACS ; Clear all analog switches
	BSET	#LVEN,X:HDR 
	BSET	#HVEN,X:HDR 
	JMP	<FINISH

; Execute the power-on cycle, as a command
POWER_ON
	JSR	<CLEAR_SWITCHES_AND_DACS	; Clear switches and DACs

; Turn on the low voltages (+/- 6.5V, +/- 16.5V) and delay
	BCLR	#LVEN,X:HDR		; Set these signals to DSP outputs 
	MOVE	#2000000,X0
	DO      X0,*+3			; Wait 20 millisec for settling
	NOP 	

; Turn on the high +36 volt power line and delay
	BCLR	#HVEN,X:HDR		; HVEN = Low => Turn on +36V
	MOVE	#2000000,X0
	DO      X0,*+3			; Wait 20 millisec for settling
	NOP

	JCLR	#PWROK,X:HDR,PWR_ERR	; Test if the power turned on properly
	JSR	<SET_BIASES		; Turn on the DC bias supplies
	MOVE	#IDLE,R0		; Put controller in IDLE state
	MOVE	R0,X:<IDL_ADR
	JMP	<FINISH

; The power failed to turn on because of an error on the power control board
PWR_ERR	BSET	#LVEN,X:HDR		; Turn off the low voltage emable line
	BSET	#HVEN,X:HDR		; Turn off the high voltage emable line
	JMP	<ERROR

; Set all the DC bias voltages and video processor offset values, reading
;   them from the 'DACS' table
SET_BIASES
	BSET	#3,X:PCRD		; Turn on the serial clock
	BCLR	#1,X:<LATCH		; Separate updates of clock driver
	BSET	#CDAC,X:<LATCH		; Disable clearing of DACs
	BSET	#ENCK,X:<LATCH		; Enable clock and DAC output switches
	MOVEP	X:LATCH,Y:WRLATCH	; Write it to the hardware
	JSR	<PAL_DLY		; Delay for all this to happen
	MOVE	#DACS,R0		; Get starting address of DAC values
	JSR	<WR_DACS		; Update the DACs 

; Let the DAC voltages all ramp up before exiting
	MOVE	#400000,X0
	DO	X0,*+3			; 4 millisec delay
	NOP
	BCLR	#3,X:PCRD		; Turn the serial clock off
	RTS

; Read DAC values from a table, and write them to the DACs
WR_DACS	DO      Y:(R0)+,L_DAC		; Repeat Y:(R0)+ times
	MOVE	Y:(R0)+,A		; Read the table entry
	JSR	<XMIT_A_WORD		; Transmit it to TIM-A-STD
	NOP
L_DAC
	RTS
	
SET_BIAS_VOLTAGES
	JSR	<SET_BIASES
	JMP	<FINISH

CLR_SWS	JSR	<CLEAR_SWITCHES_AND_DACS
	JMP	<FINISH

CLEAR_SWITCHES_AND_DACS
	BCLR	#CDAC,X:<LATCH		; Clear all the DACs
	BCLR	#ENCK,X:<LATCH		; Disable all the output switches
	MOVEP	X:LATCH,Y:WRLATCH	; Write it to the hardware
	BSET	#3,X:PCRD	; Turn the serial clock on
	MOVE	#$0C3000,A	; Value of integrate speed and gain switches
	CLR	B
	MOVE	#$100000,X0	; Increment over board numbers for DAC writes
	MOVE	#$001000,X1	; Increment over board numbers for WRSS writes
	DO	#15,L_VIDEO	; Fifteen video processor boards maximum
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	ADD	X0,A
	MOVE	B,Y:WRSS
	JSR	<PAL_DLY	; Delay for the serial data transmission
	ADD	X1,B
L_VIDEO	
	BCLR	#3,X:PCRD		; Turn the serial clock off
	RTS

SET_SHUTTER_STATE
	MOVE	X:LATCH,A
	AND	#$FFEF,A
	OR	X0,A
	NOP
	MOVE	A1,X:LATCH
	MOVEP	A1,Y:WRLATCH	
	RTS	
	
; Open the shutter from the timing board, executed as a command
OPEN_SHUTTER
	MOVE	#0,X0
	JSR	<SET_SHUTTER_STATE
	JMP	<FINISH

; Close the shutter from the timing board, executed as a command
CLOSE_SHUTTER
	MOVE	#>$10,X0
	JSR	<SET_SHUTTER_STATE
	JMP	<FINISH

; Shutter subroutines
OSHUT	MOVE	#0,X0
	JSR	<SET_SHUTTER_STATE
	RTS

CSHUT	MOVE	#>$10,X0
	JSR	<SET_SHUTTER_STATE
	RTS

; Clear the CCD, executed as a command
CLEAR	JSR	<CLR_CCD
	JMP     <FINISH

; Default clearing routine with serial clocks inactive
; Fast clear image before each exposure, executed as a subroutine
CLR_CCD DO      Y:<NPCLR,LPCLR          ; Loop over number of lines in image
        MOVE    Y:<PARL,R0	        ; Address of parallel transfer waveform
        JSR     <CLOCK                  ; Go clock out the CCD charge
        NOP                             ; Do loop restriction
LPCLR
        RTS

; Start the exposure timer and monitor its progress
EXPOSE	MOVEP	#0,X:TLR0		; Load 0 into counter timer
	MOVE	X:<EXPOSURE_TIME,B
	TST	B			; Special test for zero exposure time
	JEQ	<END_EXP		; Don't even start an exposure
	SUB	#1,B			; Timer counts from X:TCPR0+1 to zero
	BSET	#TIM_BIT,X:TCSR0	; Enable the timer #0
	MOVE	B,X:TCPR0
CHK_RCV	JCLR    #EF,X:HDR,CHK_TIM		; Simple test for fast execution
	MOVE	#COM_BUF,R3		; The beginning of the command buffer
	JSR	<GET_RCV		; Check for an incoming command
	JCS	<PRC_RCV		; If command is received, go check it
CHK_TIM	JCLR	#TCF,X:TCSR0,CHK_RCV	; Wait for timer to equal compare value
END_EXP	BCLR	#TIM_BIT,X:TCSR0	; Disable the timer
	JMP	(R7)			; This contains the return address

; Start the exposure, operate the shutter, and initiate the CCD readout
START_EXPOSURE
	MOVE	#$020102,B		; Initialize the PCI image address
	JSR	<XMT_WRD
	MOVE	#'IIA',B
	JSR	<XMT_WRD

	MOVE	#<COM_BUF,R3
	JSR	<GET_RCV		; Check for FO command
	JCS	<PRC_RCV		; Process the command 
	MOVE	#TST_RCV,R0		; Process commands during the exposure
	MOVE	R0,X:<IDL_ADR
	JSR	<WAIT_TO_FINISH_CLOCKING

; Operate the shutter if needed and begin exposure
;	JCLR	#SHUT,X:STATUS,L_SEX0
;	JSR	<OSHUT			; Open the shutter if needed
L_SEX0	MOVE	#L_SEX1,R7		; Return address at end of exposure
	JMP	<EXPOSE			; Delay for specified exposure time
L_SEX1

;brought in 3/21/2011 r.a.
STR_RDC	JSR	<PCI_READ_IMAGE		; Get the PCI board reading the image

;	JCLR	#SHUT,X:STATUS,S_DEL0
;	JSR	<CSHUT			; Close the shutter if necessary
        MOVE    Y:<SH_DEL,A
        TST     A
        JLE     <S_DEL0
        MOVE    #100000,X0
        DO      A,S_DEL0                ; Delay by Y:SH_DEL milliseconds
        DO      X0,S_DEL1
        NOP
S_DEL1  NOP
S_DEL0

; this section brought in for the new roi code from leachEmail\lbnl_genIII\  3/21/2011 r.a.
;  must do some stuff b4 the jump. r.a.
;  shutter, waiting for it to close and then reading out
TST_SYN	JSET	#TST_IMG,X:STATUS,SYNTHETIC_IMAGE

	MOVE    #<PARALLELS_DURING_READOUT,R0
	JSR     <CLOCK
	JMP	<RDCCD			; Finally, go read out the CCD

; Set software to IDLE mode
IDL     MOVE    #IDLE,X0                ; Exercise clocks when idling
        MOVE    X0,X:<IDL_ADR
        BSET    #IDLMODE,X:<STATUS      ; Idle after readout
        JMP     <FINISH                 ; Need to send header and 'DON'

; Hold clocks during exposure, idle again afterwards
HLD     MOVE    #TST_RCV,X0             ; Wait for commands during exposure
        MOVE    X0,X:<IDL_ADR           ;  instead of exercising clocks
        JMP     <FINISH

; Set the desired exposure time
SET_EXPOSURE_TIME
	MOVE	X:(R3)+,Y0
	MOVE	Y0,X:EXPOSURE_TIME
	MOVEP	Y0,X:TCPR0
	JMP	<FINISH

; Set the desired Skipper repeat times
SET_SKIPPER_REPEAT
	MOVE	X:(R3)+,X0
	MOVE	X0,Y:PIT_SKREPEAT
	JMP	<FINISH

; Set the amplifier type
SEL_AT  MOVE    X:(R3)+,X0
        MOVE    X0,Y:AMPLTYPE
        JMP     <FINISH

;Set total number of columns to transmit
SET_TOTALCOL
        MOVE	X:(R3)+,X0
        MOVE	X0,Y:TOTALCOL
        JMP	<FINISH

; Read the time remaining until the exposure ends
READ_EXPOSURE_TIME
	MOVE	X:TCR0,Y1		; Read elapsed exposure time
	JMP	<FINISH1

; Pause the exposure - close the shutter and stop the timer
PAUSE_EXPOSURE
	MOVEP	X:TCR0,X:ELAPSED_TIME	; Save the elapsed exposure time
	BCLR    #TIM_BIT,X:TCSR0	; Disable the DSP exposure timer
	JSR	<CSHUT			; Close the shutter
	JMP	<FINISH

; Resume the exposure - open the shutter if needed and restart the timer
RESUME_EXPOSURE
	BSET	#TRM,X:TCSR0		; To be sure it will load TLR0
	MOVEP	X:TCR0,X:TLR0		; Restore elapsed exposure time
	BSET	#TIM_BIT,X:TCSR0	; Re-enable the DSP exposure timer
	JCLR	#SHUT,X:STATUS,L_RES
	JSR	<OSHUT			; Open the shutter if necessary
L_RES	JMP	<FINISH

; Abort exposure - close the shutter, stop the timer and resume idle mode
ABORT_EXPOSURE
	JSR	<CSHUT			; Close the shutter
	BCLR    #TIM_BIT,X:TCSR0	; Disable the DSP exposure timer
	JCLR	#IDLMODE,X:<STATUS,NO_IDL2 ; Don't idle after readout
	MOVE	#IDLE,R0
	MOVE	R0,X:<IDL_ADR
	JMP	<RDC_E2
NO_IDL2	MOVE	#TST_RCV,R0
	MOVE	R0,X:<IDL_ADR
RDC_E2	JSR	<WAIT_TO_FINISH_CLOCKING
	BCLR	#ST_RDC,X:<STATUS	; Set status to not reading out
	DO      #4000,*+3		; Wait 40 microsec for the fiber
	NOP				;  optic to clear out
	JMP	<FINISH

; Generate a synthetic image by simply incrementing the pixel counts
SYNTHETIC_IMAGE
	CLR	A
	DO      Y:<NPR,LPR_TST      	; Loop over each line readout
	DO      Y:<NSR,LSR_TST		; Loop over number of pixels per line
	REP	#20			; #20 => 1.0 microsec per pixel
	NOP
	ADD	#1,A			; Pixel data = Pixel data + 1
	NOP
	MOVE	A,B
	JSR	<XMT_PIX		;  transmit them
	NOP
LSR_TST	
	NOP
LPR_TST	
        JMP     <RDC_END		; Normal exit

; Transmit the 16-bit pixel datum in B1 to the host computer
XMT_PIX	ASL	#16,B,B
	NOP
	MOVE	B2,X1
	ASL	#8,B,B
	NOP
	MOVE	B2,X0
	NOP
	MOVEP	X1,Y:WRFO
	MOVEP	X0,Y:WRFO
	RTS

; Test the hardware to read A/D values directly into the DSP instead
;   of using the SXMIT option, A/Ds #2 and 3.
READ_AD	MOVE	X:(RDAD+2),B
	ASL	#16,B,B
	NOP
	MOVE	B2,X1
	ASL	#8,B,B
	NOP
	MOVE	B2,X0
	NOP
	MOVEP	X1,Y:WRFO
	MOVEP	X0,Y:WRFO
	REP	#10
	NOP
	MOVE	X:(RDAD+3),B
	ASL	#16,B,B
	NOP
	MOVE	B2,X1
	ASL	#8,B,B
	NOP
	MOVE	B2,X0
	NOP
	MOVEP	X1,Y:WRFO
	MOVEP	X0,Y:WRFO
	REP	#10
	NOP
	RTS

; Alert the PCI interface board that images are coming soon
PCI_READ_IMAGE
	MOVE	#$020104,B		; Send header word to the FO transmitter
	JSR	<XMT_WRD
	MOVE	#'RDA',B
	JSR	<XMT_WRD
        MOVE	Y:TOTALCOL,B			; Number of columns to read
	JSR	<XMT_WRD
	MOVE	Y:NPR,B			; Number of rows to read		
	JSR	<XMT_WRD
	RTS

; Wait for the clocking to be complete before proceeding
WAIT_TO_FINISH_CLOCKING
	JSET	#SSFEF,X:PDRD,*		; Wait for the SS FIFO to be empty	
	RTS

; This MOVEP instruction executes in 30 nanosec, 20 nanosec for the MOVEP,
;   and 10 nanosec for the wait state that is required for SRAM writes and 
;   FIFO setup times. It looks reliable, so will be used for now.

; Core subroutine for clocking out CCD charge
CLOCK	JCLR	#SSFHF,X:HDR,*		; Only write to FIFO if < half full
	NOP
	JCLR	#SSFHF,X:HDR,CLOCK	; Guard against metastability
	MOVE    Y:(R0)+,X0      	; # of waveform entries 
	DO      X0,CLK1                 ; Repeat X0 times
	MOVEP	Y:(R0)+,Y:WRSS		; 30 nsec Write the waveform to the SS 	
CLK1
	NOP
	RTS                     	; Return from subroutine

; Delay for serial writes to the PALs and DACs by 8 microsec
PAL_DLY	DO	#800,*+3		; Wait 8 usec for serial data xmit
	NOP
	RTS

; Test the analog serial word transmitter
TEST_XMIT
	MOVE	X:(R3)+,A
	JSR	<XMIT_A_WORD
	JMP	<FINISH

; Let the host computer read the controller configuration
READ_CONTROLLER_CONFIGURATION
	MOVE	Y:<CONFIG,Y1		; Just transmit the configuration
	JMP	<FINISH1

; Set the video processor gain and integrator speed for all video boards
;  Command syntax is  SGN  #GAIN  #SPEED, #GAIN = 1, 2, 5 or 10	
;					  #SPEED = 0 for slow, 1 for fast
ST_GAIN	BSET	#3,X:PCRD	; Turn on the serial clock
	MOVE	X:(R3)+,A	; Gain value (1,2,5 or 10)
	MOVE	#>1,X0
	CMP	X0,A		; Check for gain = x1
	JNE	<STG2
	MOVE	#>$77,B
	JMP	<STG_A
STG2	MOVE	#>2,X0		; Check for gain = x2
	CMP	X0,A
	JNE	<STG5
	MOVE	#>$BB,B
	JMP	<STG_A
STG5	MOVE	#>5,X0		; Check for gain = x5
	CMP	X0,A
	JNE	<STG10
	MOVE	#>$DD,B
	JMP	<STG_A
STG10	MOVE	#>10,X0		; Check for gain = x10
	CMP	X0,A
	JNE	<ERROR
	MOVE	#>$EE,B

STG_A	MOVE	X:(R3)+,A	; Integrator Speed (0 for slow, 1 for fast)
	NOP
	JCLR	#0,A1,STG_B
	BSET	#8,B1
	NOP
	BSET	#9,B1
STG_B	MOVE	#$0C3C00,X0
	OR	X0,B
	NOP
	MOVE	B,Y:<GAINRA	; Store the GAIN value for later use
		; 4/21/2011  this should/might send the gain to the vid board r.a.
		; from the sdc commmand... make sure we are not in diagnostic mode.
	BCLR	#10,Y:<GAINRA    ;make sure we are not in diagnostic mode r.a.
	BCLR	#11,Y:<GAINRA    ;make sure we are not in diagnostic mode r.a.
	MOVE   Y:<GAINRA,B1
; Send this same value to 15 video processor boards whether they exist or not
SDC_A	MOVE	#$100000,X0	; Increment value
	DO	#15,STG_LOOP
	MOVE    B,A           ; have to get things in A1 to be sent by xmit_a_word  r.a.
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Wait for SSI and PAL to be empty
	ADD     X0,B      ; Increment the video processor board number
	NOP
STG_LOOP
        NOP
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<FINISH
ERR_SGN	MOVE	X:(R3)+,A
	JMP	<ERROR


; Set a particular DAC numbers, for setting DC bias voltages, clock driver
;   voltages and video processor offset
; This is code for the ARC32 clock driver and ARC45 CCD video processor
;
; SBN  #BOARD  #DAC  ['CLK' or 'VID'] voltage
;
;				#BOARD is from 0 to 15
;				#DAC number
;				#voltage is from 0 to 4095

SET_BIAS_NUMBER			; Set bias number
	BSET	#3,X:PCRD	; Turn on the serial clock
	MOVE	X:(R3)+,A	; First argument is board number, 0 to 15
	REP	#20
	LSL	A
	NOP
	MOVE	A,X1		; Save the board number
	MOVE	X:(R3)+,A	; Second argument is DAC number
	NOP
	MOVE	A1,Y:0		; Save the DAC number for a little while
	MOVE	X:(R3),B	; Third argument is 'VID' or 'CLK' string
	CMP	#'VID',B
	JNE	<CLK_DRV
	REP	#14
	LSL	A
	NOP
	BSET	#19,A1		; Set bits to mean video processor DAC
	NOP
	BSET	#18,A1
	JMP	<BD_SET
CLK_DRV	CMP	#'CLK',B
	JNE	<ERR_SBN

; For ARC32 do some trickiness to set the chip select and address bits
	MOVE	A1,B
	REP	#14
	LSL	A
	MOVE	#$0E0000,X0
	AND	X0,A
	MOVE	#>7,X0
	AND	X0,B		; Get 3 least significant bits of clock #
	CMP	#0,B
	JNE	<CLK_1
	BSET	#8,A
	JMP	<BD_SET
CLK_1	CMP	#1,B
	JNE	<CLK_2
	BSET	#9,A
	JMP	<BD_SET
CLK_2	CMP	#2,B
	JNE	<CLK_3
	BSET	#10,A
	JMP	<BD_SET
CLK_3	CMP	#3,B
	JNE	<CLK_4
	BSET	#11,A
	JMP	<BD_SET
CLK_4	CMP	#4,B
	JNE	<CLK_5
	BSET	#13,A
	JMP	<BD_SET
CLK_5	CMP	#5,B
	JNE	<CLK_6
	BSET	#14,A
	JMP	<BD_SET
CLK_6	CMP	#6,B
	JNE	<CLK_7
	BSET	#15,A
	JMP	<BD_SET
CLK_7	CMP	#7,B
	JNE	<BD_SET
	BSET	#16,A

BD_SET	OR	X1,A		; Add on the board number
	NOP
	MOVE	A,X0
	MOVE	X:(R3)+,B	; Third argument (again) is 'VID' or 'CLK' string
	CMP	#'VID',B
	JEQ	<VID
	MOVE	X:(R3)+,A	; Fourth argument is voltage value, 0 to $fff
	REP	#4
	LSR	A		; Convert 12 bits to 8 bits for ARC32
	MOVE	#>$FF,Y0	; Mask off just 8 bits
	AND	Y0,A
	OR	X0,A
	JMP	<XMT_SBN
VID	MOVE	X:(R3)+,A	; Fourth argument is voltage value for ARC45, 12 bits
	OR	X0,A

XMT_SBN	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Wait for the number to be sent
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<FINISH
ERR_SBN	MOVE	X:(R3)+,A	; Read and discard the fourth argument
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<ERROR
	
; Specify the MUX value to be output on the clock driver board
; Command syntax is  SMX  #clock_driver_board #MUX1 #MUX2
;				#clock_driver_board from 0 to 15
;				#MUX1, #MUX2 from 0 to 23

SET_MUX	BSET	#3,X:PCRD	; Turn on the serial clock
	MOVE	X:(R3)+,A	; Clock driver board number
	REP	#20
	LSL	A
;!!!    MOVE	#$003000,X0   ; original code. does not work with newest timing board
        MOVE	#$001000,X0        ;leach patch for the newest 4/20/2011 timing board r.a.
	OR	X0,A
	NOP
	MOVE	A,X1		; Move here for storage

; Get the first MUX number
	MOVE	X:(R3)+,A	; Get the first MUX number
	JLT	ERR_SM1
	MOVE	#>24,X0		; Check for argument less than 32
	CMP	X0,A
	JGE	ERR_SM1
	MOVE	A,B
	MOVE	#>7,X0
	AND	X0,B
	MOVE	#>$18,X0
	AND	X0,A
	JNE	<SMX_1		; Test for 0 <= MUX number <= 7
	BSET	#3,B1
	JMP	<SMX_A
SMX_1	MOVE	#>$08,X0
	CMP	X0,A		; Test for 8 <= MUX number <= 15
	JNE	<SMX_2
	BSET	#4,B1
	JMP	<SMX_A
SMX_2	MOVE	#>$10,X0
	CMP	X0,A		; Test for 16 <= MUX number <= 23
	JNE	<ERR_SM1
	BSET	#5,B1
SMX_A	OR	X1,B1		; Add prefix to MUX numbers
	NOP
	MOVE	B1,Y1

; Add on the second MUX number
	MOVE	X:(R3)+,A	; Get the next MUX number
	JLT	<ERROR
	MOVE	#>24,X0		; Check for argument less than 32
	CMP	X0,A
	JGE	<ERROR
	REP	#6
	LSL	A
	NOP
	MOVE	A,B
	MOVE	#$1C0,X0
	AND	X0,B
	MOVE	#>$600,X0
	AND	X0,A
	JNE	<SMX_3		; Test for 0 <= MUX number <= 7
	BSET	#9,B1
	JMP	<SMX_B
SMX_3	MOVE	#>$200,X0
	CMP	X0,A		; Test for 8 <= MUX number <= 15
	JNE	<SMX_4
	BSET	#10,B1
	JMP	<SMX_B
SMX_4	MOVE	#>$400,X0
	CMP	X0,A		; Test for 16 <= MUX number <= 23
	JNE	<ERROR
	BSET	#11,B1
SMX_B	ADD	Y1,B		; Add prefix to MUX numbers
	NOP
	MOVE	B1,A
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Delay for all this to happen
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<FINISH
ERR_SM1	MOVE	X:(R3)+,A
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<ERROR

HOLD_CLK        ;no clocking during exposure (MASTER=UTIL)
        MOVE    #TST_RCV,X0             ; Wait for commands during exposure
        MOVE    X0,X:<IDL_ADR           ;  instead of exercising clocks
        JMP     <FINISH

ERASE                   ; Persistence erase
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<TIME1             ;var1 = erase time
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<TIME2             ;var3 = delay time

        MOVE    #ERHI,R0        ; Get starting address of DAC values
        JSR     <WR_DACS        ; Set clocks to 'high',vsub low
        DO      Y:<TIME1,ER_T1
        JSR     <LNG_DLY        ; Delay in units of 1 msec
        NOP
ER_T1   MOVE	Y:VSUBN,A
	JSR	<XMIT_A_WORD	; Set vsub normal
        JSR     <PAL_DLY        ; Wait for SSI and PAL to be empty
        DO      Y:<TIME2,ER_T2
        JSR     <LNG_DLY        ; Delay in units of 1 msec
        NOP
ER_T2   MOVE    #EREND,R0       ; Get starting address of DAC values
        JSR     <WR_DACS        ; Set clocks to 'normal'

        JMP     <FINISH



  ; Specify subarray readout coordinates, one rectangle only
SET_SUBARRAY_SIZES	
	BCLR	#ST_SA,X:<STATUS	; Subarray not yet activated
	MOVE    X:(R3)+,X0
	MOVE	X0,Y:<NRBIAS		; Number of bias pixels to read
	MOVE    X:(R3)+,X0
	MOVE	X0,Y:<NSREAD		; Number of columns in subimage read
	MOVE    X:(R3)+,X0
	MOVE	X0,Y:<NPREAD		; Number of rows in subimage read
	JMP	<FINISH

; Call this routine to activate subarray and specify positions of the subarray
SET_SUBARRAY_POSITIONS
	BSET	#ST_SA,X:<STATUS ; Subarray readout activated by this call
	MOVE	X:(R3)+,X0
	MOVE	X0,Y:<NP_SKIP	; Number of rows (parallels) to clear
	MOVE	X:(R3)+,X0
	MOVE	X0,Y:<NS_SKP1	; Number of columns (serials) clears before
	MOVE	X:(R3)+,X0	;  the subarray readout
	MOVE	X0,Y:<NS_SKP2	; Number of columns (serials) clears after	
	JMP	<FINISH		;  the subarray readout

	

;***********************   Delay 1 msec
LNG_DLY DO      #4050,LNGDLY     
        NOP
LNGDLY
        RTS

SEL_VDIR
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<OS
        MOVE    #$0,A
        CMP     X0,A
        JNE     <VCLK_I
        MOVE	#PARALLEL,X0
        MOVE	X0,Y:<PARL
	MOVE    #'DON',Y1
        JMP     <FINISH1
VCLK_I  MOVE    #PARALLEL_INV,X0
        MOVE	X0,Y:<PARL
	MOVE    #'DON',Y1
        JMP     <FINISH1

;;;;;;;;;;;;;;;;
;Select H-Clock directions

HCLK_DRXN
        MOVE    X:(R3)+,X0              ; Get amplifier(s) name
        MOVE    X0,Y:<HSEL
        MOVE    #'__L',A                ; LEFT Amplifier = readout #0
        CMP     X0,A
        JNE     <HCMP_R
        MOVE	#SERIAL_SKIP_L,X0
        MOVE	X0,Y:SERIAL_SKIP
        MOVE	#SERIAL_READ_L_STAGE1,X0
        MOVE	X0,Y:<SERIAL_READ
        BCLR    #SPLIT_S,X:STATUS
        JMP     <HMP_END
HCMP_R  MOVE    #'__R',A                ; RIGHT Amplifier = readout #1
        CMP     X0,A
        JNE     <HCMP_LR
        MOVE	#SERIAL_SKIP_R,X0
        MOVE	X0,Y:SERIAL_SKIP
        MOVE	#SERIAL_READ_R_STAGE1,X0
        MOVE	X0,Y:<SERIAL_READ
        BCLR    #SPLIT_S,X:STATUS
        JMP     <HMP_END
HCMP_LR MOVE    #'_LR',A                ; LEFT and RIGHT = readouts #0 and #1
        CMP     X0,A
        JNE     <HMP_ERROR
        MOVE	#SERIAL_SKIP_LR,X0
        MOVE	X0,Y:SERIAL_SKIP        ;
        MOVE	#SERIAL_READ_LR_STAGE1,X0
        MOVE	X0,Y:<SERIAL_READ
        BSET    #SPLIT_S,X:STATUS
        JMP     <HMP_END
HMP_ERROR
        MOVE    #'ERR',X0
        JMP     <FINISH1
HMP_END
        MOVE    #'DON',Y1
        JMP     <FINISH1

;---------------------
;I_DELAY Changer
;---------------------

CHG_IDL MOVE    X:(R3)+,X0
        MOVE	Y:DLY0,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:DLY0

        MOVE	Y:DLY1,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:DLY1

	MOVE	Y:DLY2,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:DLY2

	MOVE	Y:DLY3,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:DLY3

        JMP     <FINISH

;------------------------
;PRE_SET_DELAY changer
;------------------------

CH_PRD  MOVE    X:(R3)+,X0
        MOVE	Y:PRD0,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:PRD0

        MOVE	Y:PRD1,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:PRD1

        JMP     <FINISH


;------------------------
;POST_SET_DELAY changer
;------------------------

CH_POD  MOVE    X:(R3)+,X0
        MOVE	Y:POD0,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:POD0

        MOVE	Y:POD1,A
        AND	#$FFFF,A
        OR	X0,A
        NOP
        MOVE	A1,Y:POD1

        JMP     <FINISH


;------------------------
;Binning parameters changer
;------------------------
SNPBIN  MOVE    X:(R3)+,X0
        MOVE    X0,Y:NPBIN
        JMP     <FINISH

SNSBIN  MOVE    X:(R3)+,X0
        MOVE    X0,Y:NSBIN
        JMP     <FINISH



;;;;;;;;;;;;;;;;;;



; Select which readouts to process
;   'SOS'  Amplifier_name  
;       Amplifier_name = '__L', '__R', '_LR'

SEL_OS  MOVE    X:(R3)+,X0              ; Get amplifier(s) name
        MOVE    X0,Y:<OS
        JSR     <SELECT_OUTPUT_SOURCE
        JMP     <FINISH1


; A massive subroutine for setting all the addresses depending on the
;   output source(s) selection and binning parameter.
SELECT_OUTPUT_SOURCE

; Set all the waveform addresses depending on which readout mode
        MOVE    #'__L',A                ; LEFT Amplifier = readout #0
        CMP     X0,A
        JNE     <CMP_R
        BCLR    #SPLIT_P,X:STATUS
       	MOVE	#SERIAL_SKIP_L,X0
	MOVE	X0,Y:SERIAL_SKIP
        MOVE	#SERIAL_READ_L_STAGE1,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F000,X0             ; Transmit channel 1 - our cable is flipped  (PM)
CMP_RR  MOVE    X0,Y:SXA2
        BCLR    #SPLIT_S,X:STATUS
        JMP     <CMP_END

CMP_R   MOVE    #'__R',A                ; RIGHT Amplifier = readout #1
        CMP     X0,A
        JNE     <CMP_LR
        BCLR    #SPLIT_P,X:STATUS
       	MOVE	#SERIAL_SKIP_R,X0
	MOVE	X0,Y:SERIAL_SKIP
        MOVE	#SERIAL_READ_R_STAGE1,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F041,X0             ; Transmit channel 0  - our cable is flipped (PM) 
CMP_LL  MOVE    X0,Y:SXA2
        BCLR    #SPLIT_S,X:STATUS
        JMP     <CMP_END

CMP_LR  MOVE    #'_LR',A                ; LEFT and RIGHT = readouts #0 and #1
        CMP     X0,A
        JNE     <CMP_12
        BCLR    #SPLIT_P,X:STATUS
  	MOVE	#SERIAL_SKIP_LR,X0   
	MOVE	X0,Y:SERIAL_SKIP        ;  
        MOVE	#SERIAL_READ_LR_STAGE1,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F040,X0             ; Transmit channel 0&1
CMP_AR  MOVE    X0,Y:SXA2
        BSET    #SPLIT_S,X:STATUS
CMP_END MOVE    X0,Y:SXMIT
        MOVE    #'DON',Y1
        RTS

CMP_12  MOVE    #'_12',A
        CMP     X0,A
        JNE     <CMP_21
        BSET    #SPLIT_P,X:STATUS
        MOVE    #$00F081,X0             ; Transmit channel 2&1
        JMP     <CMP_LL

CMP_21  MOVE    #'_21',A
        CMP     X0,A
        JNE     <CMP_2L
        BSET    #SPLIT_P,X:STATUS
        MOVE    #$00F081,X0             ; Transmit channel 2&1
        JMP     <CMP_RR

CMP_2L  MOVE    #'_2L',A
        CMP     X0,A
        JNE     <CMP_2U
        BCLR    #SPLIT_P,X:STATUS
        MOVE    #$00F082,X0             ; Transmit channel 2
        JMP     <CMP_LL

CMP_2U  MOVE    #'_2R',A
        CMP     X0,A
        JNE     <CMP_RL
        BCLR    #SPLIT_P,X:STATUS
        MOVE    #$00F0C3,X0             ; Transmit channel 3
        JMP     <CMP_RR

CMP_RL  MOVE    #'_RL',A
        CMP     X0,A
        JNE     <CMP_ALL
        BCLR    #SPLIT_P,X:STATUS
        MOVE    #$00F0C2,X0             ; Transmit channel 2&3
        JMP     <CMP_AR

CMP_ALL MOVE    #'ALL',A
        CMP     X0,A
        JNE     <CMP_ERROR
        BSET    #SPLIT_P,X:STATUS
        MOVE    #$00F0C0,X0             ; Transmit channel 0&1&2&3
        JMP     <CMP_AR

CMP_ERROR
        MOVE    #'ERR',X0
        RTS
