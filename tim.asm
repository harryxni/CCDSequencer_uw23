       COMMENT *

This file is used to generate boot DSP code for the 250 MHz fiber optic
	timing board using a DSP56303 as its main processor. It was
	derived from Gen II files supplied by LBNL starting Jan. 2006.
	Assume - 	ARC32 clock driver board
			ARC45 video processor board
			no ARC50 utility board
	*
	PAGE    132     ; Printronix page width - 132 columns

; Include the boot and header files so addressing is easy
	INCLUDE "timhdr.asm"
	INCLUDE	"timboot.asm"

	ORG	P:,P:
; sg 2006-02-02 shouldn't the next line contain TIMREV5 (cf. timhdr.asm) ?!
; CC      EQU     CCDVIDREV3B+TIMREV4+UTILREV3+SHUTTER_CC+TEMP_POLY+SUBARRAY+SPLIT_SERIAL

CC      EQU     CCDVIDREV3B+TIMREV5+UTILREV3+SHUTTER_CC+TEMP_POLY+SUBARRAY+SPLIT_SERIAL



; Put number of words of application in P: for loading application from EEPROM
	DC	TIMBOOT_X_MEMORY-@LCV(L)-1

; Keep the CCD idling when not reading out

IDLE	DO      Y:<NSR,IDL1     	; Loop over number of pixels per line
	
	MOVE    #<SERIAL_IDLE_T,R0 	; Serial transfer on pixel
	JSR     <CLOCK  		; Go to it

	;DO	Y:<PIT_SKREPEAT,PIT_SK
	;	MOVE    #<PIT_SK_SERIAL_READ_LSUB,R0 	; Serial transfer on pixel
	;	JSR     <CLOCK  		; Go to it
	;NOP
;PIT_SK	NOP

	;MOVE    #<PIT_SK_SERIAL_READ_LSUB,R0 	; Serial transfer on pixel
	;JSR     <CLOCK  		; Go to it

	MOVE    #<PIT_SK_SERIAL_READ_LSUB,R0 	; Serial transfer on pixel
	JSR     <CLOCK  		; Go to it

	MOVE    #<SERIAL_IDLE_T2,R0 	; Serial transfer on pixel
	JSR     <CLOCK  		; Go to it


	MOVE	#COM_BUF,R3
	JSR	<GET_RCV		; Check for FO or SSI commands
	JCC	<NO_COM			; Continue IDLE if no commands received
	ENDDO
	JMP     <PRC_RCV		; Go process header and command
NO_COM	NOP
IDL1
	MOVE    #<PARALLEL,R0		; Address of parallel clocking waveform
	JSR     <CLOCK  		; Go clock out the CCD charge
	JMP     <IDLE	

	

;  *****************  Exposure and readout routines  *****************

; Overall loop - transfer and read NPR lines

; Parallel shift the image from the Imaging area into the Storage area
; Calculate some readout parameters
;this is pasted in from leachemail\lbnl\2kx4k\tim.asm r.a. 3/21/2011
RDCCD	CLR	A
	JSET	#ST_SA,X:STATUS,SUB_IMG
	MOVE	A1,Y:<NP_SKIP		; Zero these all out
	MOVE	A1,Y:<NS_SKP1
	MOVE	A1,Y:<NS_SKP2
	NOP
	MOVE	Y:<NSR,A		; Move NSR into Y which stores the value of numColumns
	;ASR	#3,A,A                    ; 3 byte shift or division by 8 for a skipper seq of 8	
	NOP                             ; else not for roi for __L or __R
	MOVE	A,Y:<NS_READ		; Number of columns in each subimage
	JMP	<WT_CLK

; Loop over the required number of subimage boxes
SUB_IMG	MOVE	Y:<NSREAD,A
; !!!	ASR	A			; Effectively split serial since there
	NOP				;   are two CCDs
	MOVE	A,Y:<NS_READ	; Number of columns in each subimage

; Start the loop for parallel shifting desired number of lines
WT_CLK

; Later	-->	JSR	<GENERATE_SERIAL_WAVEFORM

	JSR	<WAIT_TO_FINISH_CLOCKING

; Skip over the required number of rows for subimage readout
	MOVE	Y:<NP_SKIP,A		; Number of rows to skip
	TST	A
	JEQ	<CLR_SR
	DO      Y:<NP_SKIP,L_PSKP
	DO	Y:<NPBIN,L_PSKIP
	MOVE    #<PARALLEL,R0
	JSR     <CLOCK  		; Go clock out the CCD charge
        NOP
L_PSKIP	NOP
L_PSKP

; Clear out the accumulated charge from the serial shift register
CLR_SR	DO      Y:<NSCLR,L_CLRSR	; Loop over number of pixels to skip
	MOVE    Y:<SERIAL_SKIP,R0	; Address of serial skipping waveforms
	JSR     <CLOCK  		; Go clock out the CCD charge
	NOP
L_CLRSR		                     	; Do loop restriction

; This is the main loop over each line to be read out
	DO      Y:<NPR,LPR		; Number of rows to read out

; Exercise the parallel clocks, including binning if needed
	DO	Y:<NPBIN,L_PBIN
	MOVE    #<PARALLEL,R0
	JSR     <CLOCK  		; Go clock out the CCD charge
	NOP
L_PBIN

; Check for a command once per line. Only the ABORT command should be issued.
	MOVE	#COM_BUF,R3
	JSR	<GET_RCV		; Was a command received?
	JCC	<CONTINUE_READ		; If no, continue reading out
	JMP	<PRC_RCV		; If yes, go process it

; Abort the readout currently underway
ABR_RDC	JCLR	#ST_RDC,X:<STATUS,ABORT_EXPOSURE
	ENDDO				; Properly terminate readout loop
	JMP	<ABORT_EXPOSURE

; Skip over NS_SKP1 columns for subimage readout
CONTINUE_READ
	MOVE	Y:<NS_SKP1,A		; Number of columns to skip
	TST	A
	JLE	<L_READ
	DO	Y:<NS_SKP1,L_SKP1	; Number of waveform entries total
	MOVE	Y:<SERIAL_SKIP,R0	; Waveform table starting address
	JSR     <CLOCK  		; Go clock out the CCD charge			; Go clock out the CCD charge
	NOP
L_SKP1

; Finally read some real pixels
L_READ	DO	Y:<NS_READ,L_RD
	MOVE	#<SERIAL_READ_L1,R0
	JSR     <CLOCK  		; Go clock out the CCD charge			; Go clock out the CCD charge
	
	DO	Y:<PIT_SKREPEAT,PIT_SK
		MOVE    #<PIT_SK_SERIAL_READ_LSUB,R0 	; Serial transfer on pixel
		JSR     <CLOCK  		; Go to it
	NOP
PIT_SK	NOP

	MOVE	#<SERIAL_READ_L2,R0
	JSR     <CLOCK
	
	NOP
L_RD

; Skip over NS_SKP2 columns if needed for subimage readout
	MOVE	Y:<NS_SKP2,A		; Number of columns to skip
	TST	A
	JLE	<L_BIAS
	DO	Y:<NS_SKP2,L_SKP2
	MOVE	Y:<SERIAL_SKIP,R0	; Waveform table starting address
	JSR     <CLOCK  		; Go clock out the CCD charge			; Go clock out the CCD charge
	NOP
L_SKP2

; And read the bias pixels if in subimage readout mode
L_BIAS	JCLR	#ST_SA,X:STATUS,END_ROW	; ST_SA = 0 => full image readout
	TST	A
	JLE	<END_ROW
	MOVE	Y:<NRBIAS,A		; NR_BIAS = 0 => no bias pixels
	TST	A
	JLE	<END_ROW
	JCLR	#SPLIT_S,X:STATUS,*+3
	ASR	A			; Split serials require / 2
	NOP
	DO      A1,L_BRD		; Number of pixels to read out
	MOVE	Y:<SERIAL_READ,R0
	JSR     <CLOCK  		; Go clock out the CCD charge			; Go clock out the CCD charg
	NOP
L_BRD	NOP
END_ROW	NOP
LPR	NOP				; End of parallel loop

; Restore the controller to non-image data transfer and idling if necessary
RDC_END	JCLR	#IDLMODE,X:<STATUS,NO_IDL ; Don't idle after readout
	MOVE	#IDLE,R0
	MOVE	R0,X:<IDL_ADR
	JMP	<RDC_E
NO_IDL	MOVE	#TST_RCV,R0
	MOVE	R0,X:<IDL_ADR
RDC_E	JSR	<WAIT_TO_FINISH_CLOCKING
	BCLR	#ST_RDC,X:<STATUS	; Set status to not reading out
        JMP     <START
; back 2 normal time/space continum
        
	INCLUDE "timCCD1_8.asm"                 ; Generic 	

TIMBOOT_X_MEMORY	EQU	@LCV(L)

;  ****************  Setup memory tables in X: space ********************

; Define the address in P: space where the table of constants begins

	IF	@SCP("DOWNLOAD","HOST")
	ORG     X:END_COMMAND_TABLE,X:END_COMMAND_TABLE
	ENDIF

	IF	@SCP("DOWNLOAD","ROM")
	ORG     X:END_COMMAND_TABLE,P:
	ENDIF

; Application commands
	DC	'PON',POWER_ON
	DC	'POF',POWER_OFF
	DC	'SBV',SET_BIAS_VOLTAGES
	DC	'IDL',IDL
	DC	'OSH',OPEN_SHUTTER
	DC	'CSH',CLOSE_SHUTTER
	DC	'RDC',RDCCD 			; Begin CCD readout
	DC	'CLR',CLEAR  			; Fast clear the CCD   

; Exposure and readout control routines
	DC	'SET',SET_EXPOSURE_TIME
	DC	'RET',READ_EXPOSURE_TIME
	DC	'SEX',START_EXPOSURE
	DC	'PEX',PAUSE_EXPOSURE
	DC	'REX',RESUME_EXPOSURE
	DC	'AEX',ABORT_EXPOSURE
	DC	'ABR',ABR_RDC
	DC	'CRD',CONTINUE_READ
	DC	'SSR',SET_SKIPPER_REPEAT

; Support routines
	DC	'SGN',ST_GAIN      
	DC	'SBN',SET_BIAS_NUMBER
	DC	'SMX',SET_MUX
	DC	'CSW',CLR_SWS
	DC	'SOS',SEL_OS
	DC	'SSS',SET_SUBARRAY_SIZES
	DC	'SSP',SET_SUBARRAY_POSITIONS
	DC	'RCC',READ_CONTROLLER_CONFIGURATION 

; New LBNL commands
        DC      'ERS',ERASE             ; Persistent Image Erase        
        DC      'HLD',HOLD_CLK          ; Stop clocking during erase    
        ;DC      'SPP',SET_PK_PAR        ; Set pumping and EL_shutter parameters 
        ;DC      'PMP',POCKET            ; Start pocket pumping  
        
END_APPLICATON_COMMAND_TABLE	EQU	@LCV(L)

	IF	@SCP("DOWNLOAD","HOST")
NUM_COM			EQU	(@LCV(R)-COM_TBL_R)/2	; Number of boot + 
							;  application commands
EXPOSING		EQU	CHK_TIM			; Address if exposing
CONTINUE_READING	EQU	CONTINUE_READ 		; Address if reading out
	ENDIF

	IF	@SCP("DOWNLOAD","ROM")
	ORG     Y:0,P:
	ENDIF

; Now let's go for the timing waveform tables
	IF	@SCP("DOWNLOAD","HOST")
        ORG     Y:0,Y:0
	ENDIF

GAIN	DC	END_APPLICATON_Y_MEMORY-@LCV(L)-1
; sg 2005-02-6 why are these numbers even in here? Shouldn't they come from the
;              current.waveforms  file? 
; r.a. 3/1/2011 note 2 self:  these are dsp variables names that are hard wired to 
; dsp y memory locations via the org y:0, y:0 statement above so from the
; outside (say excel) we can read (or set) the value of "GAIN" at location 0x400000
; NSR is at 0x400001 and so on. some values are set via direct memory writes "commands" WRM
; and some are set via "routines (which then go on to do more initing of
; various hardware registers... somewhere.. (labels that are "jumped to" via the 3 letter
; command jump table at the top... so SOS is the command for setting, left
; right, or all ccd outputs and it is broken stuck to all in this source...
; supposed to be settable from the gui but the jump table lable appears hacked out...
; so SOS is supposed to go to asm code "SEL_OS" label but that's gone?
;  roi is similarly diminished in this.  roi commands are sss and ssp and are not
; even in this jump table.  (hacked to death)  r.a. 
;  so for example "ALL" could be sent down or '__L' for left ect.
; this is locked at "ALL" (could do a WRM, write memory to change it but the
; hardware would not be set appropriately so it would still be at all...
;   NSR, NPR are just
; DSP memory values that the readout code will look at later (when "SEX" is sent
; down as a command...) and use as a reference for the loops in the (sex) readout routines
; controls how many times the parallel and/or serial readout tables are "played" to
; the timing (output arc ??) board.
;NSR     DC      560   	 	; Number Serial Read, prescan + image + bias
;NPR     DC      512     	; Number Parallel Read
;GAINRA  DC      0               ; can not add new vars here or image will not complete being sent. r.a.
NSR     DC      10   	 	; Number Serial Read, prescan + image + bias
NPR     DC      10	     	; Number Parallel Read
;NS_CLR	DC      0	  	; To clear the serial register
NSCLR   DC      NS_CLR             ;see waveform file 4 this one and next
NPCLR   DC      NP_CLR    	; To clear the parallel register
NSBIN   DC      1       	; Serial binning parameter
NPBIN   DC      1       	; Parallel binning parameter
TST_DAT	DC	0		; Temporary definition for test images
SH_DEL	DC	10		; Delay in milliseconds between shutter closing 
				;   and image readout
CONFIG	DC	CC		; Controller configuration
NS_READ DC      0               ; brought in for roi r.a. 3/21/2011
OS	DC	'__L'		; Output Source selection (1side 9/25/07 JE) 



; Multiple readout addresses
;SERIAL_READ	DC	SERIAL_READ_LR	; Address of serial reading waveforms  (2sides)
;SERIAL_CLEAR	DC	SERIAL_SKIP_LR	; Address of serial skipping waveforms (2sides)

SERIAL_SKIP 	DC	SERIAL_SKIP_L	; Serial skipping waveforms was L
SERIAL_READ	DC	SERIAL_READ_L	; Address of serial reading waveforms (1side 9/25/07 JE) was L
SERIAL_CLEAR	DC	SERIAL_SKIP_L	; Address of serial skipping waveforms(1side 9/25/07 JE) was L



; These parameters are set in "timCCDmisc.asm"
NP_SKIP	DC	0	; Number of rows to skip
NS_SKP1	DC	0	; Number of serials to clear before read
NS_SKP2	DC	0	; Number of serials to clear after read
NRBIAS	DC	0	; Number of bias pixels to read
NSREAD	DC	0	; Number of columns in subimage read
NPREAD	DC	0	; Number of rows in subimage read



; Definitions for CCD HV erase
TIME1   DC      1000            ; Erase time
TIME2   DC      500             ; Delay for Vsub ramp-up
; Timing board shutter
CL_H    DC      100             ; El Shutter msec

; Pocket pumping parameters
PK_MULT DC      10      ; Multiplicater for Number of pumping  cycles
PK_SHF  DC      20      ; Number of lines to be shifted every cycle
PK_CY   DC      100     ; Number of pumping cycles
; EPER slit width. running pocket pumping with non zero EPER value will
EPER    DC      0       ; activate EPER code instead of pumping code.
GAINRA  DC      0       ; try it at the end this way.. sigh. r.a. 4/21/2011

PIT_SKREPEAT DC 8



; Include the waveform table for the designated type of CCD
	INCLUDE "WAVEFORM_FILE" ; Readout and clocking waveform file

END_APPLICATON_Y_MEMORY	EQU	@LCV(L)

; End of program
	END

