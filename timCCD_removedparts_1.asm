
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



;*********************Removed from current_sk.wf**************
;start binning waveforms
CCD_RESET       ;Used for binning only
        DC      SERIAL_CLOCK_L-CCD_RESET-1

SERIAL_CLOCK_L  ;"NORMAL" clocking
        DC      SERIAL_CLOCK_R-SERIAL_CLOCK_L-1
        DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+G1L ;h3->lo,SW->lo,Reset_On
        DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+G1L ;h2->hi
        DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+G1L ;h1->lo
        DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+G1L ;h3->hi
        DC      CLK3+S_DELAY+RH+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+G1L ;h2->lo
        DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+G1L ;h1->hi
        DC      CLK3+PRE_SET_DLY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+G1L ;Reset_Off+Delay

SERIAL_CLOCK_R  ;"REVERSE" clocking
        DC      SERIAL_CLOCK_LR-SERIAL_CLOCK_R-1

SERIAL_CLOCK_LR ;"SPLIT" clocking
        DC      VIDEO_PROCESS-SERIAL_CLOCK_LR-1

VIDEO_PROCESS
        DC      END_VIDEO-VIDEO_PROCESS-1
SXMIT   DC      $00F000                 ; Transmit A/D data to host
END_VIDEO

;end binning waveforms

	
