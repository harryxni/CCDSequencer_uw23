;*******************************************************************************
;This file is used to generate boot DSP code for the 250 MHz fiber optic
;timing board using a DSP56303 as its main processor. It was
;derived from Gen II files supplied by LBNL starting Jan. 2006.
;Assume - 	ARC32 clock driver board
;		ARC45 video processor board
;		no ARC50 utility board
;
;File changed quite a bit for Skipper CCD by Pitam Mitra for DAMIC-M
;Feb 8, 2019. pitamm@uw.edu
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
;*******************************************************************************

        PAGE    132     ; Printronix page width - 132 columns

; Include the boot and header files so addressing is easy
        INCLUDE "timhdr.asm"
        INCLUDE	"timboot.asm"

        ORG	P:,P:
CC      EQU     CCDVIDREV3B+TIMREV5+UTILREV3+SHUTTER_CC+TEMP_POLY+SUBARRAY+SPLIT_SERIAL


; Put number of words of application in P: for loading application from EEPROM
        DC	TIMBOOT_X_MEMORY-@LCV(L)-1


;*******************************************
;* IDLE - This is the IDLE mode
;* function to keep the CCD clocking
;* when not reading charges
;*******************************************

IDLE	MOVE	Y:<NSR,A		; Move NSR into Y which stores the value of numColumns. If SPLIT_S bit in X:STATUS is set, it means we have _LR. So serial register must be split in 2 since we have 2 amplifiers each reading half the number of pixels.
	JCLR    #SPLIT_S,X:STATUS,*+3   ; Test if SPLIT_S bit in X:STATUS is set. If not, PC <- PC+3
        ASR     A                       ; Split in 2
	NOP                             ;
	MOVE	A,Y:<NSIDLE		; Number of columns in each subimage
	DO      Y:<NSIDLE,IDL1     	; Loop over number of pixels per line
        MOVE    Y:<SERIAL_READ,R0 	; To be able to set SERIAL_READ dynamically, it needs to be assigned Y:<SERIAL_READ
        JSR     <CLOCK  		; Clock Stage 1

        MOVE	Y:<AMPLTYPE,X0
        MOVE    #$0,A 	;Probalby checks if reg A is 0?
        CMP	X0,A
        BNE     <DES

        DO	Y:<PIT_SKREPEAT,PIT_SK
                MOVE    #<PIT_SK_NDCR_SERIAL_READ,R0 	; Serial transfer on pixel
                JSR     <CLOCK  		; Go to it
        NOP
PIT_SK	NOP

        MOVE    #<SERIAL_READ_CLRCHG_STAGE_2,R0 	; Serial transfer on pixel
	JSR     <CLOCK  		; Go to it
        JMP     <CTN

DES     MOVE    #PIT_DESI_SERIAL_READ,R0
        JSR     <CLOCK
        MOVE	#FIRE_RESET_GATE,R0
      	JSR	<CLOCK

CTN	MOVE	#COM_BUF,R3
	JSR	<GET_RCV		; Check for FO or SSI commands
	JCC	<NO_COM			; Continue IDLE if no commands received
	ENDDO
	JMP     <PRC_RCV		; Go process header and command
NO_COM	NOP
IDL1
        MOVE    Y:<PARL,R0		; Address of parallel clocking waveform
	JSR     <CLOCK  		; Go clock out the CCD charge
        MOVE    #FIRE_RESET_GATE,R0
        JSR     <CLOCK
	JMP     <IDLE



;  *****************  Exposure and readout routines  *****************

; Overall loop - transfer and read NPR lines

; Parallel shift the image from the Imaging area into the Storage area
; Calculate some readout parameters
RDCCD	CLR	A
	JSET	#ST_SA,X:STATUS,SUB_IMG
	MOVE	A1,Y:<NP_SKIP		; Zero these all out
	MOVE	A1,Y:<NS_SKP1
	MOVE	A1,Y:<NS_SKP2
	NOP
	MOVE	Y:<NSR,A		; Move NSR into Y which stores the value of numColumns
;If SPLIT_S bit in X:STATUS is set, it means we have _LR. So serial register must be split in 2 since we have 2 amplifiers
;each reading half the number of pixels.
	JCLR    #SPLIT_S,X:STATUS,*+3   ; Test if SPLIT_S bit in X:STATUS is set. If not, PC <- PC+3
        ASR     A                       ; Split in 2
	NOP                             ;
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
        MOVE    Y:<PARL,R0
	JSR     <CLOCK  		; Go clock out the CCD charge
        MOVE    #FIRE_RESET_GATE,R0
        MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ; Update to clear charge for DAMIC CCD
	JSR     <CLOCK
        NOP
L_PSKIP	NOP
L_PSKP

; Clear out the accumulated charge from the serial shift register
CLR_SR	DO      Y:<NSCLR,L_CLRSR	; Loop over number of pixels to skip
	MOVE    Y:<SERIAL_SKIP,R0	; Address of serial skipping waveforms
	JSR     <CLOCK  		; Go clock out the CCD charge
	NOP				
	MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ;Update to clear charge for DAMIC CCD
	JSR     <CLOCK
	NOP
L_CLRSR		                     	; Do loop restriction

; This is the main loop over each line to be read out
	DO      Y:<NPR,LPR		; Number of rows to read out
;Lines below clean out charge every row, updated for DAMIC
;  Clear out the accumulated charge from the serial shift register
	DO      Y:<NSCLR,L_SRCLR ; Loop over number of pixels to skip
	MOVE    Y:<SERIAL_SKIP,R0 ; Address of serial skipping waveforms
	JSR     <CLOCK	  ; Go clock out the CCD charge
        NOP
	MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ; Update to clear charge for DAMIC CCD
	JSR     <CLOCK
        NOP
L_SRCLR
	
; Exercise the parallel clocks, including binning if needed
	DO	Y:<NPBIN,L_PBIN
        MOVE    Y:<PARL,R0
	JSR     <CLOCK  		; Go clock out the CCD charge
        MOVE    #FIRE_RESET_GATE,R0
        JSR     <CLOCK

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
	MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ; Update to clear charge for DAMIC CCD
	JSR	<CLOCK
	NOP
L_SKP1

; Finally read some real pixels
L_READ	DO	Y:<NS_READ,L_RD

;Serial binning goes here, since this is where the
;serial clocks are exercises
        DO	Y:<NSBIN,L_SBIN
        MOVE	Y:<SERIAL_READ,R0
        JSR     <CLOCK
        NOP
L_SBIN

        MOVE	Y:<AMPLTYPE,X0
        MOVE    #$0,A
        CMP	X0,A
        BNE     <DESR

        DO	Y:<PIT_SKREPEAT,PIT_SKR
        MOVE    #PIT_SK_NDCR_SERIAL_READ,R0 	;
        JSR     <CLOCK                          ; Write the clock waveforms to the output - i.e. run the clock
        MOVE    #SK_SEND_BUFFER,R0
        JSR     <CLOCK
	NOP
PIT_SKR	NOP

        MOVE	#SERIAL_READ_CLRCHG_STAGE_2,R0
	JSR     <CLOCK
        JMP     <CTNR

DESR    MOVE    #PIT_DESI_SERIAL_READ,R0
        JSR     <CLOCK
        MOVE    #SK_SEND_BUFFER,R0
        JSR     <CLOCK
	MOVE	#FIRE_RESET_GATE,R0
	JSR	<CLOCK

CTNR
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
	MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ; Update to clear charge for DAMIC CCD
	JSR	<CLOCK
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
	MOVE    #SERIAL_READ_CLRCHG_STAGE_2,R0 ; Update to clear charge for DAMIC CCD
	JSR	<CLOCK
	NOP

L_BRD	NOP
END_ROW	NOP
LPR	NOP				; End of parallel loop

; This is code for continuous readout - check if more frames are needed
CHKNXT	MOVE Y:N_FRAMES,A
	CMP #1,A
	JLE <RDC_END
	BCLR #ST_RDC,X:<STATUS		;Bit test #ST_RDC bit in X:<STATUS and clear 
	JSR <WAIT_TO_FINISH_CLOCKING
	JMP <NEXT_FRAME

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
	DC	'SSF',SET_SERIAL_FLUSH
		

; Support routines
	DC	'SGN',ST_GAIN
	DC	'SBN',SET_BIAS_NUMBER
	DC	'SMX',SET_MUX
	DC	'CSW',CLR_SWS
	DC	'SOS',SEL_OS
	DC	'SSS',SET_SUBARRAY_SIZES
	DC	'SSP',SET_SUBARRAY_POSITIONS
	DC	'RCC',READ_CONTROLLER_CONFIGURATION
        DC	'SAT',SEL_AT
        DC      'VDR',SEL_VDIR
        DC      'HDR',HCLK_DRXN
        DC      'CIT',CHG_IDL
        DC      'STC',SET_TOTALCOL
        DC      'CPO',CH_POD
        DC      'CPR',CH_PRD
        DC      'NPB',SNPBIN
        DC      'NSB',SNSBIN
        DC      'DGW',CHG_DGW
        DC      'RSW',CHG_RSW
        DC      'OGW',CHG_OGW
        DC      'SWW',CHG_SWW
	DC      'CSL',CH_SDL
	DC      'CSS',CH_SDO
	DC      'CPL',CH_PDL
	DC      'CPP',CH_PDO

;Continuous readout commands
	DC  	'SNF',SNFRMS
	DC  	'FPB',NF_BFR



; New LBNL commands
        DC      'ERS',ERASE             ; Persistent Image Erase
        DC      'HLD',HOLD_CLK          ; Stop clocking during erase


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
NSR     DC      10   	 	; Number Serial Read, prescan + image + bias
NPR     DC      10	     	; Number Parallel Read
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
PDIR    DC      0



; Multiple readout addresses
;SERIAL_READ	DC	SERIAL_READ_LR	; Address of serial reading waveforms  (2sides)
;SERIAL_CLEAR	DC	SERIAL_SKIP_LR	; Address of serial skipping waveforms (2sides)

SERIAL_SKIP 	DC	SERIAL_SKIP_L	; Serial skipping waveforms was L
SERIAL_READ	DC	SERIAL_READ_LR_STAGE1	; Address of serial reading waveforms (1side 9/25/07 JE) was L
SERIAL_CLEAR	DC	SERIAL_SKIP_LR	; Address of serial skipping waveforms(1side 9/25/07 JE) was L
PARL    	DC	PARALLEL_1
HSEL            DC      '_LR'           ;Direction of H-clocks

; These parameters are set in "timCCDmisc.asm"
NP_SKIP	DC	0	; Number of rows to skip
NS_SKP1	DC	0	; Number of serials to clear before read
NS_SKP2	DC	0	; Number of serials to clear after read
NRBIAS	DC	0	; Number of bias pixels to read
NSREAD	DC	0	; Number of columns in subimage read
NPREAD	DC	0	; Number of rows in subimage read
NSIDLE  DC	0	;


; Definitions for CCD HV erase
TIME1   DC      1000            ; Erase time
TIME2   DC      500             ; Delay for Vsub ramp-up
; Timing board shutter
CL_H    DC      100             ; El Shutter msec
;Dubious shit
GAINRA  DC      0
EPER    DC      0



PIT_SKREPEAT DC 8
AMPLTYPE    DC  0
TOTALCOL    DC  0

; Continuous readout parameters
N_FRAMES	DC	0	; Total number of frames to read out
I_FRAME	DC	0	; Number of frames read out so far
IBUFFER	DC	0	; Number of frames read into the PCI buffer
N_FPB		DC	0	; Number of frames per PCI image buffer


; Include the waveform table for the designated type of CCD
	INCLUDE "WAVEFORM_FILE" ; Readout and clocking waveform file

END_APPLICATON_Y_MEMORY	EQU	@LCV(L)

; End of program
	END
