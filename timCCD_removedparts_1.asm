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
	MOVE	#SERIAL_READ_L,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F041,X0             ; Transmit channel 0   6/16/2011 was 00f000 no work __L new cable
CMP_RR  MOVE    X0,Y:SXL
        BCLR    #SPLIT_S,X:STATUS
        JMP     <CMP_END

CMP_R   MOVE    #'__R',A                ; RIGHT Amplifier = readout #1
        CMP     X0,A
        JNE     <CMP_LR
        BCLR    #SPLIT_P,X:STATUS
       	MOVE	#SERIAL_SKIP_R,X0
	MOVE	X0,Y:SERIAL_SKIP
	MOVE	#SERIAL_READ_R,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F000,X0             ; Transmit channel 1  6/16/2011 fix was f041 no work __R new cable
CMP_LL  MOVE    X0,Y:SXR
        BCLR    #SPLIT_S,X:STATUS
        JMP     <CMP_END

CMP_LR  MOVE    #'_LR',A                ; LEFT and RIGHT = readouts #0 and #1
        CMP     X0,A
        JNE     <CMP_12
        BCLR    #SPLIT_P,X:STATUS
  	MOVE	#SERIAL_SKIP_LR,X0   ;added/changed 6/16/2011 r.a.
	MOVE	X0,Y:SERIAL_SKIP     ; "      "     "  "  "   " " 
	MOVE	#SERIAL_READ_LR,X0
	MOVE	X0,Y:<SERIAL_READ
        MOVE    #$00F040,X0             ; Transmit channel 0&1
CMP_AR  MOVE    X0,Y:SXRL
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


;***********************   EL Shutter   *************************
EL_SH   JSR     <OSHUT          ; open Timing board shutter
        DO      Y:<CL_H,LPEL
        JSR     <LNG_DLY        ; Delay in units of 1 msec
        NOP
LPEL    JSR     <CSHUT          ; close Timing board shutter
        JMP     <FINISH



;********** SET POCKET PUMPING PARAMETERS ************************

SET_PK_PAR      MOVE    X:(R3)+,X0
        MOVE    X0,Y:<PK_SHF
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<PK_CY
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<CL_H
        MOVE    X:(R3)+,X0
        MOVE    X0,Y:<EPER
        JMP     <FINISH

;  ***********************   POCKET PUMPING  **********************

POCKET  MOVE    Y:<EPER,A
        MOVE    #>0,X0
        CMP     X0,A            ; Check for EPER>0
        JNE     EP_SPL
        DO      Y:<PK_MULT,FINE1        ;Multiplicator for number of pumping cycles
        DO      Y:<PK_CY,FINE2          ;Loop over number of pumping cycles
        DO      Y:<PK_SHF,FINE21        ;loop over pixels to shift forward
        MOVE    #<P_PARAL,R0
        JSR     <CLOCK
	NOP
FINE21  DO      Y:<PK_SHF,FINE23        ;loop over pixels to shift reverse
        MOVE    #<P_PARAL_INV,R0
        JSR     <CLOCK                  
	NOP
FINE23          NOP                             
FINE2           NOP
FINE1   JMP     <FINISH
        
EP_SPL  DO Y:<EPER,EP_LP
        MOVE #<P_EPER,R0
        JSR     <CLOCK
	NOP
EP_LP   NOP
        JMP     <FINISH
	
