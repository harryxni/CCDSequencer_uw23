Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  tim.asm  Page 1



1                                 COMMENT *
2      
3                          This file is used to generate boot DSP code for the 250 MHz fiber optic
4                                  timing board using a DSP56303 as its main processor. It was
5                                  derived from Gen II files supplied by LBNL starting Jan. 2006.
6                                  Assume -        ARC32 clock driver board
7                                                  ARC45 video processor board
8                                                  no ARC50 utility board
9                                  *
10                                   PAGE    132                               ; Printronix page width - 132 columns
11     
12                         ; Include the boot and header files so addressing is easy
13                                   INCLUDE "timhdr.asm"
14                                COMMENT *
15     
16                         This is a header file that is shared between the fiber optic timing board
17                         boot and application code files for Rev. 5 = 250 MHz timing boards
18                                 *
19     
20                                   PAGE    132                               ; Printronix page width - 132 columns
21     
22                         ; Various addressing control registers
23        FFFFFB           BCR       EQU     $FFFFFB                           ; Bus Control Register
24        FFFFF9           AAR0      EQU     $FFFFF9                           ; Address Attribute Register, channel 0
25        FFFFF8           AAR1      EQU     $FFFFF8                           ; Address Attribute Register, channel 1
26        FFFFF7           AAR2      EQU     $FFFFF7                           ; Address Attribute Register, channel 2
27        FFFFF6           AAR3      EQU     $FFFFF6                           ; Address Attribute Register, channel 3
28        FFFFFD           PCTL      EQU     $FFFFFD                           ; PLL control register
29        FFFFFE           IPRP      EQU     $FFFFFE                           ; Interrupt Priority register - Peripheral
30        FFFFFF           IPRC      EQU     $FFFFFF                           ; Interrupt Priority register - Core
31     
32                         ; Port E is the Synchronous Communications Interface (SCI) port
33        FFFF9F           PCRE      EQU     $FFFF9F                           ; Port Control Register
34        FFFF9E           PRRE      EQU     $FFFF9E                           ; Port Direction Register
35        FFFF9D           PDRE      EQU     $FFFF9D                           ; Port Data Register
36        FFFF9C           SCR       EQU     $FFFF9C                           ; SCI Control Register
37        FFFF9B           SCCR      EQU     $FFFF9B                           ; SCI Clock Control Register
38     
39        FFFF9A           SRXH      EQU     $FFFF9A                           ; SCI Receive Data Register, High byte
40        FFFF99           SRXM      EQU     $FFFF99                           ; SCI Receive Data Register, Middle byte
41        FFFF98           SRXL      EQU     $FFFF98                           ; SCI Receive Data Register, Low byte
42     
43        FFFF97           STXH      EQU     $FFFF97                           ; SCI Transmit Data register, High byte
44        FFFF96           STXM      EQU     $FFFF96                           ; SCI Transmit Data register, Middle byte
45        FFFF95           STXL      EQU     $FFFF95                           ; SCI Transmit Data register, Low byte
46     
47        FFFF94           STXA      EQU     $FFFF94                           ; SCI Transmit Address Register
48        FFFF93           SSR       EQU     $FFFF93                           ; SCI Status Register
49     
50        000009           SCITE     EQU     9                                 ; X:SCR bit set to enable the SCI transmitter
51        000008           SCIRE     EQU     8                                 ; X:SCR bit set to enable the SCI receiver
52        000000           TRNE      EQU     0                                 ; This is set in X:SSR when the transmitter
53                                                                             ;  shift and data registers are both empty
54        000001           TDRE      EQU     1                                 ; This is set in X:SSR when the transmitter
55                                                                             ;  data register is empty
56        000002           RDRF      EQU     2                                 ; X:SSR bit set when receiver register is full
57        00000F           SELSCI    EQU     15                                ; 1 for SCI to backplane, 0 to front connector
58     
59     
60                         ; ESSI Flags
61        000006           TDE       EQU     6                                 ; Set when transmitter data register is empty
62        000007           RDF       EQU     7                                 ; Set when receiver is full of data
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timhdr.asm  Page 2



63        000010           TE        EQU     16                                ; Transmitter enable
64     
65                         ; Phase Locked Loop initialization
66        050003           PLL_INIT  EQU     $050003                           ; PLL = 25 MHz x 2 = 100 MHz
67     
68                         ; Port B general purpose I/O
69        FFFFC4           HPCR      EQU     $FFFFC4                           ; Control register (bits 1-6 cleared for GPIO)
70        FFFFC9           HDR       EQU     $FFFFC9                           ; Data register
71        FFFFC8           HDDR      EQU     $FFFFC8                           ; Data Direction Register bits (=1 for output)
72     
73                         ; Port C is Enhanced Synchronous Serial Port 0 = ESSI0
74        FFFFBF           PCRC      EQU     $FFFFBF                           ; Port C Control Register
75        FFFFBE           PRRC      EQU     $FFFFBE                           ; Port C Data direction Register
76        FFFFBD           PDRC      EQU     $FFFFBD                           ; Port C GPIO Data Register
77        FFFFBC           TX00      EQU     $FFFFBC                           ; Transmit Data Register #0
78        FFFFB8           RX0       EQU     $FFFFB8                           ; Receive data register
79        FFFFB7           SSISR0    EQU     $FFFFB7                           ; Status Register
80        FFFFB6           CRB0      EQU     $FFFFB6                           ; Control Register B
81        FFFFB5           CRA0      EQU     $FFFFB5                           ; Control Register A
82     
83                         ; Port D is Enhanced Synchronous Serial Port 1 = ESSI1
84        FFFFAF           PCRD      EQU     $FFFFAF                           ; Port D Control Register
85        FFFFAE           PRRD      EQU     $FFFFAE                           ; Port D Data direction Register
86        FFFFAD           PDRD      EQU     $FFFFAD                           ; Port D GPIO Data Register
87        FFFFAC           TX10      EQU     $FFFFAC                           ; Transmit Data Register 0
88        FFFFA7           SSISR1    EQU     $FFFFA7                           ; Status Register
89        FFFFA6           CRB1      EQU     $FFFFA6                           ; Control Register B
90        FFFFA5           CRA1      EQU     $FFFFA5                           ; Control Register A
91     
92                         ; Timer module addresses
93        FFFF8F           TCSR0     EQU     $FFFF8F                           ; Timer control and status register
94        FFFF8E           TLR0      EQU     $FFFF8E                           ; Timer load register = 0
95        FFFF8D           TCPR0     EQU     $FFFF8D                           ; Timer compare register = exposure time
96        FFFF8C           TCR0      EQU     $FFFF8C                           ; Timer count register = elapsed time
97        FFFF83           TPLR      EQU     $FFFF83                           ; Timer prescaler load register => milliseconds
98        FFFF82           TPCR      EQU     $FFFF82                           ; Timer prescaler count register
99        000000           TIM_BIT   EQU     0                                 ; Set to enable the timer
100       000009           TRM       EQU     9                                 ; Set to enable the timer preloading
101       000015           TCF       EQU     21                                ; Set when timer counter = compare register
102    
103                        ; Board specific addresses and constants
104       FFFFF1           RDFO      EQU     $FFFFF1                           ; Read incoming fiber optic data byte
105       FFFFF2           WRFO      EQU     $FFFFF2                           ; Write fiber optic data replies
106       FFFFF3           WRSS      EQU     $FFFFF3                           ; Write switch state
107       FFFFF5           WRLATCH   EQU     $FFFFF5                           ; Write to a latch
108       010000           RDAD      EQU     $010000                           ; Read A/D values into the DSP
109       000009           EF        EQU     9                                 ; Serial receiver empty flag
110    
111                        ; DSP port A bit equates
112       000000           PWROK     EQU     0                                 ; Power control board says power is OK
113       000001           LED1      EQU     1                                 ; Control one of two LEDs
114       000002           LVEN      EQU     2                                 ; Low voltage power enable
115       000003           HVEN      EQU     3                                 ; High voltage power enable
116       00000E           SSFHF     EQU     14                                ; Switch state FIFO half full flag
117       00000A           EXT_IN0   EQU     10                                ; External digital I/O to the timing board
118       00000B           EXT_IN1   EQU     11
119       00000C           EXT_OUT0  EQU     12
120       00000D           EXT_OUT1  EQU     13
121    
122                        ; Port D equates
123       000000           SLAVE     EQU     0                                 ; Set if master by not installing a jumper
124       000001           SSFEF     EQU     1                                 ; Switch state FIFO empty flag
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timhdr.asm  Page 3



125    
126                        ; Other equates
127       000002           WRENA     EQU     2                                 ; Enable writing to the EEPROM
128    
129                        ; Latch U25 bit equates
130       000000           CDAC      EQU     0                                 ; Clear the analog board DACs
131       000002           ENCK      EQU     2                                 ; Enable the clock outputs
132       000004           SHUTTER   EQU     4                                 ; Control the shutter
133       000005           TIM_U_RST EQU     5                                 ; Reset the utility board
134    
135                        ; Software status bits, defined at X:<STATUS = X:0
136       000000           ST_RCV    EQU     0                                 ; Set to indicate word is from SCI = utility board
137       000002           IDLMODE   EQU     2                                 ; Set if need to idle after readout
138       000003           ST_SHUT   EQU     3                                 ; Set to indicate shutter is closed, clear for open
139       000004           ST_RDC    EQU     4                                 ; Set if executing 'RDC' command - reading out
140       000005           SPLIT_S   EQU     5                                 ; Set if split serial
141       000006           SPLIT_P   EQU     6                                 ; Set if split parallel
142       000007           MPP       EQU     7                                 ; Set if parallels are in MPP mode
143       000008           NOT_CLR   EQU     8                                 ; Set if not to clear CCD before exposure
144       00000A           TST_IMG   EQU     10                                ; Set if controller is to generate a test image
145       00000B           SHUT      EQU     11                                ; Set if opening shutter at beginning of exposure
146       00000C           ST_DITH   EQU     12                                ; Set if to dither during exposure
147       00000D           ST_SYNC   EQU     13                                ; Set if synchronizing two controllers
148       00000E           ST_CNRD   EQU     14                                ; Set if in continous readout mode
149       000010           ST_SA     EQU     16                                ;  copied in for roi 3/16/2011 r.a.
150    
151                        ; Address for the table containing the incoming SCI words
152       000400           SCI_TABLE EQU     $400
153    
154    
155                        ; Specify controller configuration bits of the X:STATUS word
156                        ;   to describe the software capabilities of this application file
157                        ; The bit is set (=1) if the capability is supported by the controller
158    
159    
160                                COMMENT *
161    
162                        BIT #'s         FUNCTION
163                        2,1,0           Video Processor
164                                                000     CCD Rev. 3
165                                                001     CCD Gen I
166                                                010     IR Rev. 4
167                                                011     IR Coadder
168                                                100     CCD Rev. 5, Differential input
169                                                101     8x IR
170    
171                        4,3             Timing Board
172                                                00      Rev. 4, Gen II
173                                                01      Gen I
174                                                10      Rev. 5, Gen III, 250 MHz
175    
176                        6,5             Utility Board
177                                                00      No utility board
178                                                01      Utility Rev. 3
179    
180                        7               Shutter
181                                                0       No shutter support
182                                                1       Yes shutter support
183    
184                        9,8             Temperature readout
185                                                00      No temperature readout
186                                                01      Polynomial Diode calibration
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timhdr.asm  Page 4



187                                                10      Linear temperature sensor calibration
188    
189                        10              Subarray readout
190                                                0       Not supported
191                                                1       Yes supported
192    
193                        11              Binning
194                                                0       Not supported
195                                                1       Yes supported
196    
197                        12              Split-Serial readout
198                                                0       Not supported
199                                                1       Yes supported
200    
201                        13              Split-Parallel readout
202                                                0       Not supported
203                                                1       Yes supported
204    
205                        14              MPP = Inverted parallel clocks
206                                                0       Not supported
207                                                1       Yes supported
208    
209                        16,15           Clock Driver Board
210                                                00      Rev. 3
211                                                11      No clock driver board (Gen I)
212    
213                        19,18,17                Special implementations
214                                                000     Somewhere else
215                                                001     Mount Laguna Observatory
216                                                010     NGST Aladdin
217                                                xxx     Other
218                                *
219    
220                        CCDVIDREV3B
221       000000                     EQU     $000000                           ; CCD Video Processor Rev. 3
222       000001           VIDGENI   EQU     $000001                           ; CCD Video Processor Gen I
223       000002           IRREV4    EQU     $000002                           ; IR Video Processor Rev. 4
224       000003           COADDER   EQU     $000003                           ; IR Coadder
225       000004           CCDVIDREV5 EQU    $000004                           ; Differential input CCD video Rev. 5
226       000005           IRX8VP    EQU     $000005                           ; 8 X IR Video Processor
227       000000           TIMREV4   EQU     $000000                           ; Timing Revision 4 = 50 MHz
228       000008           TIMGENI   EQU     $000008                           ; Timing Gen I = 40 MHz
229       000010           TIMREV5   EQU     $000010                           ; Timing Revision 5 = 250 MHz
230       000020           UTILREV3  EQU     $000020                           ; Utility Rev. 3 supported
231       000080           SHUTTER_CC EQU    $000080                           ; Shutter supported
232       000100           TEMP_POLY EQU     $000100                           ; Polynomial calibration
233                        TEMP_LINEAR
234       000200                     EQU     $000200                           ; Linear calibration
235       000400           SUBARRAY  EQU     $000400                           ; Subarray readout supported
236       000800           BINNING   EQU     $000800                           ; Binning supported
237                        SPLIT_SERIAL
238       001000                     EQU     $001000                           ; Split serial supported
239                        SPLIT_PARALLEL
240       002000                     EQU     $002000                           ; Split parallel supported
241       004000           MPP_CC    EQU     $004000                           ; Inverted clocks supported
242       018000           CLKDRVGENI EQU    $018000                           ; No clock driver board - Gen I
243       020000           MLO       EQU     $020000                           ; Set if Mount Laguna Observatory
244       040000           NGST      EQU     $040000                           ; NGST Aladdin implementation
245       100000           CONT_RD   EQU     $100000                           ; Continuous readout implemented
246    
247                                  INCLUDE "timboot.asm"
248                               COMMENT *
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 5



249    
250                        This file is used to generate boot DSP code for the 250 MHz fiber optic
251                                timing board using a DSP56303 as its main processor.
252                        Added utility board support Dec. 2002
253                                *
254                                  PAGE    132                               ; Printronix page width - 132 columns
255    
256                        ; Special address for two words for the DSP to bootstrap code from the EEPROM
257                                  IF      @SCP("HOST","ROM")
264                                  ENDIF
265    
266                                  IF      @SCP("HOST","HOST")
267       P:000000 P:000000                   ORG     P:0,P:0
268       P:000000 P:000000 0C0190            JMP     <INIT
269       P:000001 P:000001 000000            NOP
270                                           ENDIF
271    
272                                 ;  This ISR receives serial words a byte at a time over the asynchronous
273                                 ;    serial link (SCI) and squashes them into a single 24-bit word
274       P:000002 P:000002 602400  SCI_RCV   MOVE              R0,X:<SAVE_R0           ; Save R0
275       P:000003 P:000003 052139            MOVEC             SR,X:<SAVE_SR           ; Save Status Register
276       P:000004 P:000004 60A700            MOVE              X:<SCI_R0,R0            ; Restore R0 = pointer to SCI receive regist
er
277       P:000005 P:000005 542300            MOVE              A1,X:<SAVE_A1           ; Save A1
278       P:000006 P:000006 452200            MOVE              X1,X:<SAVE_X1           ; Save X1
279       P:000007 P:000007 54A600            MOVE              X:<SCI_A1,A1            ; Get SRX value of accumulator contents
280       P:000008 P:000008 45E000            MOVE              X:(R0),X1               ; Get the SCI byte
281       P:000009 P:000009 0AD041            BCLR    #1,R0                             ; Test for the address being $FFF6 = last by
te
282       P:00000A P:00000A 000000            NOP
283       P:00000B P:00000B 000000            NOP
284       P:00000C P:00000C 000000            NOP
285       P:00000D P:00000D 205862            OR      X1,A      (R0)+                   ; Add the byte into the 24-bit word
286       P:00000E P:00000E 0E0013            JCC     <MID_BYT                          ; Not the last byte => only restore register
s
287       P:00000F P:00000F 545C00  END_BYT   MOVE              A1,X:(R4)+              ; Put the 24-bit word into the SCI buffer
288       P:000010 P:000010 60F400            MOVE              #SRXL,R0                ; Re-establish first address of SCI interfac
e
                            FFFF98
289       P:000012 P:000012 2C0000            MOVE              #0,A1                   ; For zeroing out SCI_A1
290       P:000013 P:000013 602700  MID_BYT   MOVE              R0,X:<SCI_R0            ; Save the SCI receiver address
291       P:000014 P:000014 542600            MOVE              A1,X:<SCI_A1            ; Save A1 for next interrupt
292       P:000015 P:000015 05A139            MOVEC             X:<SAVE_SR,SR           ; Restore Status Register
293       P:000016 P:000016 54A300            MOVE              X:<SAVE_A1,A1           ; Restore A1
294       P:000017 P:000017 45A200            MOVE              X:<SAVE_X1,X1           ; Restore X1
295       P:000018 P:000018 60A400            MOVE              X:<SAVE_R0,R0           ; Restore R0
296       P:000019 P:000019 000004            RTI                                       ; Return from interrupt service
297    
298                                 ; Clear error condition and interrupt on SCI receiver
299       P:00001A P:00001A 077013  CLR_ERR   MOVEP             X:SSR,X:RCV_ERR         ; Read SCI status register
                            000025
300       P:00001C P:00001C 077018            MOVEP             X:SRXL,X:RCV_ERR        ; This clears any error
                            000025
301       P:00001E P:00001E 000004            RTI
302    
303       P:00001F P:00001F                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
304       P:000030 P:000030                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
305       P:000040 P:000040                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
306    
307                                 ; Tune the table so the following instruction is at P:$50 exactly.
308       P:000050 P:000050 0D0002            JSR     SCI_RCV                           ; SCI receive data interrupt
309       P:000051 P:000051 000000            NOP
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 6



310       P:000052 P:000052 0D001A            JSR     CLR_ERR                           ; SCI receive error interrupt
311       P:000053 P:000053 000000            NOP
312    
313                                 ; *******************  Command Processing  ******************
314    
315                                 ; Read the header and check it for self-consistency
316       P:000054 P:000054 609F00  START     MOVE              X:<IDL_ADR,R0
317       P:000055 P:000055 018FA0            JSET    #TIM_BIT,X:TCSR0,EXPOSING         ; If exposing go check the timer
                            000315
318       P:000057 P:000057 0A00A4            JSET    #ST_RDC,X:<STATUS,CONTINUE_READING
                            00026A
319       P:000059 P:000059 0AE080            JMP     (R0)
320    
321       P:00005A P:00005A 330700  TST_RCV   MOVE              #<COM_BUF,R3
322       P:00005B P:00005B 0D00A5            JSR     <GET_RCV
323       P:00005C P:00005C 0E005B            JCC     *-1
324    
325                                 ; Check the header and read all the remaining words in the command
326       P:00005D P:00005D 0C00FF  PRC_RCV   JMP     <CHK_HDR                          ; Update HEADER and NWORDS
327       P:00005E P:00005E 578600  PR_RCV    MOVE              X:<NWORDS,B             ; Read this many words total in the command
328       P:00005F P:00005F 000000            NOP
329       P:000060 P:000060 01418C            SUB     #1,B                              ; We've already read the header
330       P:000061 P:000061 000000            NOP
331       P:000062 P:000062 06CF00            DO      B,RD_COM
                            00006A
332       P:000064 P:000064 205B00            MOVE              (R3)+                   ; Increment past what's been read already
333       P:000065 P:000065 0B0080  GET_WRD   JSCLR   #ST_RCV,X:STATUS,CHK_FO
                            0000A9
334       P:000067 P:000067 0B00A0            JSSET   #ST_RCV,X:STATUS,CHK_SCI
                            0000D5
335       P:000069 P:000069 0E0065            JCC     <GET_WRD
336       P:00006A P:00006A 000000            NOP
337       P:00006B P:00006B 330700  RD_COM    MOVE              #<COM_BUF,R3            ; Restore R3 = beginning of the command
338    
339                                 ; Is this command for the timing board?
340       P:00006C P:00006C 448500            MOVE              X:<HEADER,X0
341       P:00006D P:00006D 579B00            MOVE              X:<DMASK,B
342       P:00006E P:00006E 459A4E            AND     X0,B      X:<TIM_DRB,X1           ; Extract destination byte
343       P:00006F P:00006F 20006D            CMP     X1,B                              ; Does header = timing board number?
344       P:000070 P:000070 0EA080            JEQ     <COMMAND                          ; Yes, process it here
345       P:000071 P:000071 0E909D            JLT     <FO_XMT                           ; Send it to fiber optic transmitter
346    
347                                 ; Transmit the command to the utility board over the SCI port
348       P:000072 P:000072 060600            DO      X:<NWORDS,DON_XMT                 ; Transmit NWORDS
                            00007E
349       P:000074 P:000074 60F400            MOVE              #STXL,R0                ; SCI first byte address
                            FFFF95
350       P:000076 P:000076 44DB00            MOVE              X:(R3)+,X0              ; Get the 24-bit word to transmit
351       P:000077 P:000077 060380            DO      #3,SCI_SPT
                            00007D
352       P:000079 P:000079 019381            JCLR    #TDRE,X:SSR,*                     ; Continue ONLY if SCI XMT is empty
                            000079
353       P:00007B P:00007B 445800            MOVE              X0,X:(R0)+              ; Write to SCI, byte pointer + 1
354       P:00007C P:00007C 000000            NOP                                       ; Delay for the status flag to be set
355       P:00007D P:00007D 000000            NOP
356                                 SCI_SPT
357       P:00007E P:00007E 000000            NOP
358                                 DON_XMT
359       P:00007F P:00007F 0C0054            JMP     <START
360    
361                                 ; Process the receiver entry - is it in the command table ?
362       P:000080 P:000080 0203DF  COMMAND   MOVE              X:(R3+1),B              ; Get the command
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 7



363       P:000081 P:000081 205B00            MOVE              (R3)+
364       P:000082 P:000082 205B00            MOVE              (R3)+                   ; Point R3 to the first argument
365       P:000083 P:000083 302800            MOVE              #<COM_TBL,R0            ; Get the command table starting address
366       P:000084 P:000084 062380            DO      #NUM_COM,END_COM                  ; Loop over the command table
                            00008B
367       P:000086 P:000086 47D800            MOVE              X:(R0)+,Y1              ; Get the command table entry
368       P:000087 P:000087 62E07D            CMP     Y1,B      X:(R0),R2               ; Does receiver = table entries address?
369       P:000088 P:000088 0E208B            JNE     <NOT_COM                          ; No, keep looping
370       P:000089 P:000089 00008C            ENDDO                                     ; Restore the DO loop system registers
371       P:00008A P:00008A 0AE280            JMP     (R2)                              ; Jump execution to the command
372       P:00008B P:00008B 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table addr
ess
373                                 END_COM
374       P:00008C P:00008C 0C008D            JMP     <ERROR                            ; The command is not in the table
375    
376                                 ; It's not in the command table - send an error message
377       P:00008D P:00008D 479D00  ERROR     MOVE              X:<ERR,Y1               ; Send the message - there was an error
378       P:00008E P:00008E 0C0090            JMP     <FINISH1                          ; This protects against unknown commands
379    
380                                 ; Send a reply packet - header and reply
381       P:00008F P:00008F 479800  FINISH    MOVE              X:<DONE,Y1              ; Send 'DON' as the reply
382       P:000090 P:000090 578500  FINISH1   MOVE              X:<HEADER,B             ; Get header of incoming command
383       P:000091 P:000091 469C00            MOVE              X:<SMASK,Y0             ; This was the source byte, and is to
384       P:000092 P:000092 330700            MOVE              #<COM_BUF,R3            ;     become the destination byte
385       P:000093 P:000093 46935E            AND     Y0,B      X:<TWO,Y0
386       P:000094 P:000094 0C1ED1            LSR     #8,B                              ; Shift right eight bytes, add it to the
387       P:000095 P:000095 460600            MOVE              Y0,X:<NWORDS            ;     header, and put 2 as the number
388       P:000096 P:000096 469958            ADD     Y0,B      X:<SBRD,Y0              ;     of words in the string
389       P:000097 P:000097 200058            ADD     Y0,B                              ; Add source board's header, set Y1 for abov
e
390       P:000098 P:000098 000000            NOP
391       P:000099 P:000099 575B00            MOVE              B,X:(R3)+               ; Put the new header on the transmitter stac
k
392       P:00009A P:00009A 475B00            MOVE              Y1,X:(R3)+              ; Put the argument on the transmitter stack
393       P:00009B P:00009B 570500            MOVE              B,X:<HEADER
394       P:00009C P:00009C 0C006B            JMP     <RD_COM                           ; Decide where to send the reply, and do it
395    
396                                 ; Transmit words to the host computer over the fiber optics link
397       P:00009D P:00009D 63F400  FO_XMT    MOVE              #COM_BUF,R3
                            000007
398       P:00009F P:00009F 060600            DO      X:<NWORDS,DON_FFO                 ; Transmit all the words in the command
                            0000A3
399       P:0000A1 P:0000A1 57DB00            MOVE              X:(R3)+,B
400       P:0000A2 P:0000A2 0D00EB            JSR     <XMT_WRD
401       P:0000A3 P:0000A3 000000            NOP
402       P:0000A4 P:0000A4 0C0054  DON_FFO   JMP     <START
403    
404                                 ; Check for commands from the fiber optic FIFO and the utility board (SCI)
405       P:0000A5 P:0000A5 0D00A9  GET_RCV   JSR     <CHK_FO                           ; Check for fiber optic command from FIFO
406       P:0000A6 P:0000A6 0E80A8            JCS     <RCV_RTS                          ; If there's a command, check the header
407       P:0000A7 P:0000A7 0D00D5            JSR     <CHK_SCI                          ; Check for an SCI command
408       P:0000A8 P:0000A8 00000C  RCV_RTS   RTS
409    
410                                 ; Because of FIFO metastability require that EF be stable for two tests
411       P:0000A9 P:0000A9 0A8989  CHK_FO    JCLR    #EF,X:HDR,TST2                    ; EF = Low,  Low  => CLR SR, return
                            0000AC
412       P:0000AB P:0000AB 0C00AF            JMP     <TST3                             ;      High, Low  => try again
413       P:0000AC P:0000AC 0A8989  TST2      JCLR    #EF,X:HDR,CLR_CC                  ;      Low,  High => try again
                            0000D1
414       P:0000AE P:0000AE 0C00A9            JMP     <CHK_FO                           ;      High, High => read FIFO
415       P:0000AF P:0000AF 0A8989  TST3      JCLR    #EF,X:HDR,CHK_FO
                            0000A9
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 8



416    
417       P:0000B1 P:0000B1 08F4BB            MOVEP             #$028FE2,X:BCR          ; Slow down RDFO access
                            028FE2
418       P:0000B3 P:0000B3 000000            NOP
419       P:0000B4 P:0000B4 000000            NOP
420       P:0000B5 P:0000B5 5FF000            MOVE                          Y:RDFO,B
                            FFFFF1
421       P:0000B7 P:0000B7 2B0000            MOVE              #0,B2
422       P:0000B8 P:0000B8 0140CE            AND     #$FF,B
                            0000FF
423       P:0000BA P:0000BA 0140CD            CMP     #>$AC,B                           ; It must be $AC to be a valid word
                            0000AC
424       P:0000BC P:0000BC 0E20D1            JNE     <CLR_CC
425       P:0000BD P:0000BD 4EF000            MOVE                          Y:RDFO,Y0   ; Read the MS byte
                            FFFFF1
426       P:0000BF P:0000BF 0C1951            INSERT  #$008010,Y0,B
                            008010
427       P:0000C1 P:0000C1 4EF000            MOVE                          Y:RDFO,Y0   ; Read the middle byte
                            FFFFF1
428       P:0000C3 P:0000C3 0C1951            INSERT  #$008008,Y0,B
                            008008
429       P:0000C5 P:0000C5 4EF000            MOVE                          Y:RDFO,Y0   ; Read the LS byte
                            FFFFF1
430       P:0000C7 P:0000C7 0C1951            INSERT  #$008000,Y0,B
                            008000
431       P:0000C9 P:0000C9 000000            NOP
432       P:0000CA P:0000CA 516300            MOVE              B0,X:(R3)               ; Put the word into COM_BUF
433       P:0000CB P:0000CB 0A0000            BCLR    #ST_RCV,X:<STATUS                 ; Its a command from the host computer
434       P:0000CC P:0000CC 000000  SET_CC    NOP
435       P:0000CD P:0000CD 0AF960            BSET    #0,SR                             ; Valid word => SR carry bit = 1
436       P:0000CE P:0000CE 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
437       P:0000D0 P:0000D0 00000C            RTS
438       P:0000D1 P:0000D1 0AF940  CLR_CC    BCLR    #0,SR                             ; Not valid word => SR carry bit = 0
439       P:0000D2 P:0000D2 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
440       P:0000D4 P:0000D4 00000C            RTS
441    
442                                 ; Test the SCI (= synchronous communications interface) for new words
443       P:0000D5 P:0000D5 44F000  CHK_SCI   MOVE              X:(SCI_TABLE+33),X0
                            000421
444       P:0000D7 P:0000D7 228E00            MOVE              R4,A
445       P:0000D8 P:0000D8 209000            MOVE              X0,R0
446       P:0000D9 P:0000D9 200045            CMP     X0,A
447       P:0000DA P:0000DA 0EA0D1            JEQ     <CLR_CC                           ; There is no new SCI word
448       P:0000DB P:0000DB 44D800            MOVE              X:(R0)+,X0
449       P:0000DC P:0000DC 446300            MOVE              X0,X:(R3)
450       P:0000DD P:0000DD 220E00            MOVE              R0,A
451       P:0000DE P:0000DE 0140C5            CMP     #(SCI_TABLE+32),A                 ; Wrap it around the circular
                            000420
452       P:0000E0 P:0000E0 0EA0E4            JEQ     <INIT_PROCESSED_SCI               ;   buffer boundary
453       P:0000E1 P:0000E1 547000            MOVE              A1,X:(SCI_TABLE+33)
                            000421
454       P:0000E3 P:0000E3 0C00E9            JMP     <SCI_END
455                                 INIT_PROCESSED_SCI
456       P:0000E4 P:0000E4 56F400            MOVE              #SCI_TABLE,A
                            000400
457       P:0000E6 P:0000E6 000000            NOP
458       P:0000E7 P:0000E7 567000            MOVE              A,X:(SCI_TABLE+33)
                            000421
459       P:0000E9 P:0000E9 0A0020  SCI_END   BSET    #ST_RCV,X:<STATUS                 ; Its a utility board (SCI) word
460       P:0000EA P:0000EA 0C00CC            JMP     <SET_CC
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 9



461    
462                                 ; Transmit the word in B1 to the host computer over the fiber optic data link
463                                 XMT_WRD
464       P:0000EB P:0000EB 08F4BB            MOVEP             #$028FE2,X:BCR          ; Slow down RDFO access
                            028FE2
465       P:0000ED P:0000ED 60F400            MOVE              #FO_HDR+1,R0
                            000002
466       P:0000EF P:0000EF 060380            DO      #3,XMT_WRD1
                            0000F3
467       P:0000F1 P:0000F1 0C1D91            ASL     #8,B,B
468       P:0000F2 P:0000F2 000000            NOP
469       P:0000F3 P:0000F3 535800            MOVE              B2,X:(R0)+
470                                 XMT_WRD1
471       P:0000F4 P:0000F4 60F400            MOVE              #FO_HDR,R0
                            000001
472       P:0000F6 P:0000F6 61F400            MOVE              #WRFO,R1
                            FFFFF2
473       P:0000F8 P:0000F8 060480            DO      #4,XMT_WRD2
                            0000FB
474       P:0000FA P:0000FA 46D800            MOVE              X:(R0)+,Y0              ; Should be MOVEP  X:(R0)+,Y:WRFO
475       P:0000FB P:0000FB 4E6100            MOVE                          Y0,Y:(R1)
476                                 XMT_WRD2
477       P:0000FC P:0000FC 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
478       P:0000FE P:0000FE 00000C            RTS
479    
480                                 ; Check the command or reply header in X:(R3) for self-consistency
481       P:0000FF P:0000FF 46E300  CHK_HDR   MOVE              X:(R3),Y0
482       P:000100 P:000100 579600            MOVE              X:<MASK1,B              ; Test for S.LE.3 and D.LE.3 and N.LE.7
483       P:000101 P:000101 20005E            AND     Y0,B
484       P:000102 P:000102 0E208D            JNE     <ERROR                            ; Test failed
485       P:000103 P:000103 579700            MOVE              X:<MASK2,B              ; Test for either S.NE.0 or D.NE.0
486       P:000104 P:000104 20005E            AND     Y0,B
487       P:000105 P:000105 0EA08D            JEQ     <ERROR                            ; Test failed
488       P:000106 P:000106 579500            MOVE              X:<SEVEN,B
489       P:000107 P:000107 20005E            AND     Y0,B                              ; Extract NWORDS, must be > 0
490       P:000108 P:000108 0EA08D            JEQ     <ERROR
491       P:000109 P:000109 44E300            MOVE              X:(R3),X0
492       P:00010A P:00010A 440500            MOVE              X0,X:<HEADER            ; Its a correct header
493       P:00010B P:00010B 550600            MOVE              B1,X:<NWORDS            ; Number of words in the command
494       P:00010C P:00010C 0C005E            JMP     <PR_RCV
495    
496                                 ;  *****************  Boot Commands  *******************
497    
498                                 ; Test Data Link - simply return value received after 'TDL'
499       P:00010D P:00010D 47DB00  TDL       MOVE              X:(R3)+,Y1              ; Get the data value
500       P:00010E P:00010E 0C0090            JMP     <FINISH1                          ; Return from executing TDL command
501    
502                                 ; Read DSP or EEPROM memory ('RDM' address): read memory, reply with value
503       P:00010F P:00010F 47DB00  RDMEM     MOVE              X:(R3)+,Y1
504       P:000110 P:000110 20EF00            MOVE              Y1,B
505       P:000111 P:000111 0140CE            AND     #$0FFFFF,B                        ; Bits 23-20 need to be zeroed
                            0FFFFF
506       P:000113 P:000113 21B000            MOVE              B1,R0                   ; Need the address in an address register
507       P:000114 P:000114 20EF00            MOVE              Y1,B
508       P:000115 P:000115 000000            NOP
509       P:000116 P:000116 0ACF14            JCLR    #20,B,RDX                         ; Test address bit for Program memory
                            00011A
510       P:000118 P:000118 07E087            MOVE              P:(R0),Y1               ; Read from Program Memory
511       P:000119 P:000119 0C0090            JMP     <FINISH1                          ; Send out a header with the value
512       P:00011A P:00011A 0ACF15  RDX       JCLR    #21,B,RDY                         ; Test address bit for X: memory
                            00011E
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 10



513       P:00011C P:00011C 47E000            MOVE              X:(R0),Y1               ; Write to X data memory
514       P:00011D P:00011D 0C0090            JMP     <FINISH1                          ; Send out a header with the value
515       P:00011E P:00011E 0ACF16  RDY       JCLR    #22,B,RDR                         ; Test address bit for Y: memory
                            000122
516       P:000120 P:000120 4FE000            MOVE                          Y:(R0),Y1   ; Read from Y data memory
517       P:000121 P:000121 0C0090            JMP     <FINISH1                          ; Send out a header with the value
518       P:000122 P:000122 0ACF17  RDR       JCLR    #23,B,ERROR                       ; Test address bit for read from EEPROM memo
ry
                            00008D
519       P:000124 P:000124 479400            MOVE              X:<THREE,Y1             ; Convert to word address to a byte address
520       P:000125 P:000125 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
521       P:000126 P:000126 2000B8            MPY     Y0,Y1,B                           ; Multiply
522       P:000127 P:000127 20002A            ASR     B                                 ; Eliminate zero fill of fractional multiply
523       P:000128 P:000128 213000            MOVE              B0,R0                   ; Need to address memory
524       P:000129 P:000129 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
525       P:00012A P:00012A 0D0178            JSR     <RD_WORD                          ; Read word from EEPROM
526       P:00012B P:00012B 21A700            MOVE              B1,Y1                   ; FINISH1 transmits Y1 as its reply
527       P:00012C P:00012C 0C0090            JMP     <FINISH1
528    
529                                 ; Program WRMEM ('WRM' address datum): write to memory, reply 'DON'.
530       P:00012D P:00012D 47DB00  WRMEM     MOVE              X:(R3)+,Y1              ; Get the address to be written to
531       P:00012E P:00012E 20EF00            MOVE              Y1,B
532       P:00012F P:00012F 0140CE            AND     #$0FFFFF,B                        ; Bits 23-20 need to be zeroed
                            0FFFFF
533       P:000131 P:000131 21B000            MOVE              B1,R0                   ; Need the address in an address register
534       P:000132 P:000132 20EF00            MOVE              Y1,B
535       P:000133 P:000133 46DB00            MOVE              X:(R3)+,Y0              ; Get datum into Y0 so MOVE works easily
536       P:000134 P:000134 0ACF14            JCLR    #20,B,WRX                         ; Test address bit for Program memory
                            000138
537       P:000136 P:000136 076086            MOVE              Y0,P:(R0)               ; Write to Program memory
538       P:000137 P:000137 0C008F            JMP     <FINISH
539       P:000138 P:000138 0ACF15  WRX       JCLR    #21,B,WRY                         ; Test address bit for X: memory
                            00013C
540       P:00013A P:00013A 466000            MOVE              Y0,X:(R0)               ; Write to X: memory
541       P:00013B P:00013B 0C008F            JMP     <FINISH
542       P:00013C P:00013C 0ACF16  WRY       JCLR    #22,B,WRR                         ; Test address bit for Y: memory
                            000140
543       P:00013E P:00013E 4E6000            MOVE                          Y0,Y:(R0)   ; Write to Y: memory
544       P:00013F P:00013F 0C008F            JMP     <FINISH
545       P:000140 P:000140 0ACF17  WRR       JCLR    #23,B,ERROR                       ; Test address bit for write to EEPROM
                            00008D
546       P:000142 P:000142 013D02            BCLR    #WRENA,X:PDRC                     ; WR_ENA* = 0 to enable EEPROM writing
547       P:000143 P:000143 460E00            MOVE              Y0,X:<SV_A1             ; Save the datum to be written
548       P:000144 P:000144 479400            MOVE              X:<THREE,Y1             ; Convert word address to a byte address
549       P:000145 P:000145 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
550       P:000146 P:000146 2000B8            MPY     Y1,Y0,B                           ; Multiply
551       P:000147 P:000147 20002A            ASR     B                                 ; Eliminate zero fill of fractional multiply
552       P:000148 P:000148 213000            MOVE              B0,R0                   ; Need to address memory
553       P:000149 P:000149 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
554       P:00014A P:00014A 558E00            MOVE              X:<SV_A1,B1             ; Get the datum to be written
555       P:00014B P:00014B 060380            DO      #3,L1WRR                          ; Loop over three bytes of the word
                            000154
556       P:00014D P:00014D 07588D            MOVE              B1,P:(R0)+              ; Write each EEPROM byte
557       P:00014E P:00014E 0C1C91            ASR     #8,B,B
558       P:00014F P:00014F 469E00            MOVE              X:<C100K,Y0             ; Move right one byte, enter delay = 1 msec
559       P:000150 P:000150 06C600            DO      Y0,L2WRR                          ; Delay by 12 milliseconds for EEPROM write
                            000153
560       P:000152 P:000152 060CA0            REP     #12                               ; Assume 100 MHz DSP56303
561       P:000153 P:000153 000000            NOP
562                                 L2WRR
563       P:000154 P:000154 000000            NOP                                       ; DO loop nesting restriction
564                                 L1WRR
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 11



565       P:000155 P:000155 013D22            BSET    #WRENA,X:PDRC                     ; WR_ENA* = 1 to disable EEPROM writing
566       P:000156 P:000156 0C008F            JMP     <FINISH
567    
568                                 ; Load application code from P: memory into its proper locations
569       P:000157 P:000157 47DB00  LDAPPL    MOVE              X:(R3)+,Y1              ; Application number, not used yet
570       P:000158 P:000158 0D015A            JSR     <LOAD_APPLICATION
571       P:000159 P:000159 0C008F            JMP     <FINISH
572    
573                                 LOAD_APPLICATION
574       P:00015A P:00015A 60F400            MOVE              #$8000,R0               ; Starting EEPROM address
                            008000
575       P:00015C P:00015C 0D0178            JSR     <RD_WORD                          ; Number of words in boot code
576       P:00015D P:00015D 21A600            MOVE              B1,Y0
577       P:00015E P:00015E 479400            MOVE              X:<THREE,Y1
578       P:00015F P:00015F 2000B8            MPY     Y0,Y1,B
579       P:000160 P:000160 20002A            ASR     B
580       P:000161 P:000161 213000            MOVE              B0,R0                   ; EEPROM address of start of P: application
581       P:000162 P:000162 0AD06F            BSET    #15,R0                            ; To access EEPROM
582       P:000163 P:000163 0D0178            JSR     <RD_WORD                          ; Read number of words in application P:
583       P:000164 P:000164 61F400            MOVE              #(X_BOOT_START+1),R1    ; End of boot P: code that needs keeping
                            00022B
584       P:000166 P:000166 06CD00            DO      B1,RD_APPL_P
                            000169
585       P:000168 P:000168 0D0178            JSR     <RD_WORD
586       P:000169 P:000169 07598D            MOVE              B1,P:(R1)+
587                                 RD_APPL_P
588       P:00016A P:00016A 0D0178            JSR     <RD_WORD                          ; Read number of words in application X:
589       P:00016B P:00016B 61F400            MOVE              #END_COMMAND_TABLE,R1
                            000036
590       P:00016D P:00016D 06CD00            DO      B1,RD_APPL_X
                            000170
591       P:00016F P:00016F 0D0178            JSR     <RD_WORD
592       P:000170 P:000170 555900            MOVE              B1,X:(R1)+
593                                 RD_APPL_X
594       P:000171 P:000171 0D0178            JSR     <RD_WORD                          ; Read number of words in application Y:
595       P:000172 P:000172 310100            MOVE              #1,R1                   ; There is no Y: memory in the boot code
596       P:000173 P:000173 06CD00            DO      B1,RD_APPL_Y
                            000176
597       P:000175 P:000175 0D0178            JSR     <RD_WORD
598       P:000176 P:000176 5D5900            MOVE                          B1,Y:(R1)+
599                                 RD_APPL_Y
600       P:000177 P:000177 00000C            RTS
601    
602                                 ; Read one word from EEPROM location R0 into accumulator B1
603       P:000178 P:000178 060380  RD_WORD   DO      #3,L_RDBYTE
                            00017B
604       P:00017A P:00017A 07D88B            MOVE              P:(R0)+,B2
605       P:00017B P:00017B 0C1C91            ASR     #8,B,B
606                                 L_RDBYTE
607       P:00017C P:00017C 00000C            RTS
608    
609                                 ; Come to here on a 'STP' command so 'DON' can be sent
610                                 STOP_IDLE_CLOCKING
611       P:00017D P:00017D 305A00            MOVE              #<TST_RCV,R0            ; Execution address when idle => when not
612       P:00017E P:00017E 601F00            MOVE              R0,X:<IDL_ADR           ;   processing commands or reading out
613       P:00017F P:00017F 0A0002            BCLR    #IDLMODE,X:<STATUS                ; Don't idle after readout
614       P:000180 P:000180 0C008F            JMP     <FINISH
615    
616                                 ; Routines executed after the DSP boots and initializes
617       P:000181 P:000181 305A00  STARTUP   MOVE              #<TST_RCV,R0            ; Execution address when idle => when not
618       P:000182 P:000182 601F00            MOVE              R0,X:<IDL_ADR           ;   processing commands or reading out
619       P:000183 P:000183 44F400            MOVE              #50000,X0               ; Delay by 500 milliseconds
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 12



                            00C350
620       P:000185 P:000185 06C400            DO      X0,L_DELAY
                            000188
621       P:000187 P:000187 06E8A3            REP     #1000
622       P:000188 P:000188 000000            NOP
623                                 L_DELAY
624       P:000189 P:000189 57F400            MOVE              #$020002,B              ; Normal reply after booting is 'SYR'
                            020002
625       P:00018B P:00018B 0D00EB            JSR     <XMT_WRD
626       P:00018C P:00018C 57F400            MOVE              #'SYR',B
                            535952
627       P:00018E P:00018E 0D00EB            JSR     <XMT_WRD
628    
629       P:00018F P:00018F 0C0054            JMP     <START                            ; Start normal command processing
630    
631                                 ; *******************  DSP  INITIALIZATION  CODE  **********************
632                                 ; This code initializes the DSP right after booting, and is overwritten
633                                 ;   by application code
634       P:000190 P:000190 08F4BD  INIT      MOVEP             #PLL_INIT,X:PCTL        ; Initialize PLL to 100 MHz
                            050003
635       P:000192 P:000192 000000            NOP
636    
637                                 ; Set operation mode register OMR to normal expanded
638       P:000193 P:000193 0500BA            MOVEC             #$0000,OMR              ; Operating Mode Register = Normal Expanded
639       P:000194 P:000194 0500BB            MOVEC             #0,SP                   ; Reset the Stack Pointer SP
640    
641                                 ; Program the AA = address attribute pins
642       P:000195 P:000195 08F4B9            MOVEP             #$FFFC21,X:AAR0         ; Y = $FFF000 to $FFFFFF asserts commands
                            FFFC21
643       P:000197 P:000197 08F4B8            MOVEP             #$008909,X:AAR1         ; P = $008000 to $00FFFF accesses the EEPROM
                            008909
644       P:000199 P:000199 08F4B7            MOVEP             #$010C11,X:AAR2         ; X = $010000 to $010FFF reads A/D values
                            010C11
645       P:00019B P:00019B 08F4B6            MOVEP             #$080621,X:AAR3         ; Y = $080000 to $0BFFFF R/W from SRAM
                            080621
646    
647                                 ; Program the DRAM memory access and addressing
648       P:00019D P:00019D 08F4BB            MOVEP             #$028FE1,X:BCR          ; Bus Control Register
                            028FE1
649    
650                                 ; Program the Host port B for parallel I/O
651       P:00019F P:00019F 08F484            MOVEP             #>1,X:HPCR              ; All pins enabled as GPIO
                            000001
652       P:0001A1 P:0001A1 08F489            MOVEP             #$910C,X:HDR
                            00910C
653       P:0001A3 P:0001A3 08F488            MOVEP             #$B10E,X:HDDR           ; Data Direction Register
                            00B10E
654                                                                                     ;  (1 for Output, 0 for Input)
655    
656                                 ; Port B conversion from software bits to schematic labels
657                                 ;       PB0 = PWROK             PB08 = PRSFIFO*
658                                 ;       PB1 = LED1              PB09 = EF*
659                                 ;       PB2 = LVEN              PB10 = EXT-IN0
660                                 ;       PB3 = HVEN              PB11 = EXT-IN1
661                                 ;       PB4 = STATUS0           PB12 = EXT-OUT0
662                                 ;       PB5 = STATUS1           PB13 = EXT-OUT1
663                                 ;       PB6 = STATUS2           PB14 = SSFHF*
664                                 ;       PB7 = STATUS3           PB15 = SELSCI
665    
666                                 ; Program the serial port ESSI0 = Port C for serial communication with
667                                 ;   the utility board
668       P:0001A5 P:0001A5 07F43F            MOVEP             #>0,X:PCRC              ; Software reset of ESSI0
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 13



                            000000
669       P:0001A7 P:0001A7 07F435            MOVEP             #$180809,X:CRA0         ; Divide 100 MHz by 20 to get 5.0 MHz
                            180809
670                                                                                     ; DC[4:0] = 0 for non-network operation
671                                                                                     ; WL0-WL2 = 3 for 24-bit data words
672                                                                                     ; SSC1 = 0 for SC1 not used
673       P:0001A9 P:0001A9 07F436            MOVEP             #$020020,X:CRB0         ; SCKD = 1 for internally generated clock
                            020020
674                                                                                     ; SCD2 = 0 so frame sync SC2 is an output
675                                                                                     ; SHFD = 0 for MSB shifted first
676                                                                                     ; FSL = 0, frame sync length not used
677                                                                                     ; CKP = 0 for rising clock edge transitions
678                                                                                     ; SYN = 0 for asynchronous
679                                                                                     ; TE0 = 1 to enable transmitter #0
680                                                                                     ; MOD = 0 for normal, non-networked mode
681                                                                                     ; TE0 = 0 to NOT enable transmitter #0 yet
682                                                                                     ; RE = 1 to enable receiver
683       P:0001AB P:0001AB 07F43F            MOVEP             #%111001,X:PCRC         ; Control Register (0 for GPIO, 1 for ESSI)
                            000039
684       P:0001AD P:0001AD 07F43E            MOVEP             #%000110,X:PRRC         ; Data Direction Register (0 for In, 1 for O
ut)
                            000006
685       P:0001AF P:0001AF 07F43D            MOVEP             #%000100,X:PDRC         ; Data Register - WR_ENA* = 1
                            000004
686    
687                                 ; Port C version = Analog boards
688                                 ;       MOVEP   #$000809,X:CRA0 ; Divide 100 MHz by 20 to get 5.0 MHz
689                                 ;       MOVEP   #$000030,X:CRB0 ; SCKD = 1 for internally generated clock
690                                 ;       MOVEP   #%100000,X:PCRC ; Control Register (0 for GPIO, 1 for ESSI)
691                                 ;       MOVEP   #%000100,X:PRRC ; Data Direction Register (0 for In, 1 for Out)
692                                 ;       MOVEP   #%000000,X:PDRC ; Data Register: 'not used' = 0 outputs
693    
694       P:0001B1 P:0001B1 07F43C            MOVEP             #0,X:TX00               ; Initialize the transmitter to zero
                            000000
695       P:0001B3 P:0001B3 000000            NOP
696       P:0001B4 P:0001B4 000000            NOP
697       P:0001B5 P:0001B5 013630            BSET    #TE,X:CRB0                        ; Enable the SSI transmitter
698    
699                                 ; Conversion from software bits to schematic labels for Port C
700                                 ;       PC0 = SC00 = UTL-T-SCK
701                                 ;       PC1 = SC01 = 2_XMT = SYNC on prototype
702                                 ;       PC2 = SC02 = WR_ENA*
703                                 ;       PC3 = SCK0 = TIM-U-SCK
704                                 ;       PC4 = SRD0 = UTL-T-STD
705                                 ;       PC5 = STD0 = TIM-U-STD
706    
707                                 ; Program the serial port ESSI1 = Port D for serial transmission to
708                                 ;   the analog boards and two parallel I/O input pins
709       P:0001B6 P:0001B6 07F42F            MOVEP             #>0,X:PCRD              ; Software reset of ESSI0
                            000000
710       P:0001B8 P:0001B8 07F425            MOVEP             #$000809,X:CRA1         ; Divide 100 MHz by 20 to get 5.0 MHz
                            000809
711                                                                                     ; DC[4:0] = 0
712                                                                                     ; WL[2:0] = ALC = 0 for 8-bit data words
713                                                                                     ; SSC1 = 0 for SC1 not used
714       P:0001BA P:0001BA 07F426            MOVEP             #$000030,X:CRB1         ; SCKD = 1 for internally generated clock
                            000030
715                                                                                     ; SCD2 = 1 so frame sync SC2 is an output
716                                                                                     ; SHFD = 0 for MSB shifted first
717                                                                                     ; CKP = 0 for rising clock edge transitions
718                                                                                     ; TE0 = 0 to NOT enable transmitter #0 yet
719                                                                                     ; MOD = 0 so its not networked mode
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 14



720       P:0001BC P:0001BC 07F42F            MOVEP             #%100000,X:PCRD         ; Control Register (0 for GPIO, 1 for ESSI)
                            000020
721                                                                                     ; PD3 = SCK1, PD5 = STD1 for ESSI
722       P:0001BE P:0001BE 07F42E            MOVEP             #%000100,X:PRRD         ; Data Direction Register (0 for In, 1 for O
ut)
                            000004
723       P:0001C0 P:0001C0 07F42D            MOVEP             #%000100,X:PDRD         ; Data Register: 'not used' = 0 outputs
                            000004
724       P:0001C2 P:0001C2 07F42C            MOVEP             #0,X:TX10               ; Initialize the transmitter to zero
                            000000
725       P:0001C4 P:0001C4 000000            NOP
726       P:0001C5 P:0001C5 000000            NOP
727       P:0001C6 P:0001C6 012630            BSET    #TE,X:CRB1                        ; Enable the SSI transmitter
728    
729                                 ; Conversion from software bits to schematic labels for Port D
730                                 ; PD0 = SC10 = 2_XMT_? input
731                                 ; PD1 = SC11 = SSFEF* input
732                                 ; PD2 = SC12 = PWR_EN
733                                 ; PD3 = SCK1 = TIM-A-SCK
734                                 ; PD4 = SRD1 = PWRRST
735                                 ; PD5 = STD1 = TIM-A-STD
736    
737                                 ; Program the SCI port to communicate with the utility board
738       P:0001C7 P:0001C7 07F41C            MOVEP             #$0B04,X:SCR            ; SCI programming: 11-bit asynchronous
                            000B04
739                                                                                     ;   protocol (1 start, 8 data, 1 even parity
,
740                                                                                     ;   1 stop); LSB before MSB; enable receiver
741                                                                                     ;   and its interrupts; transmitter interrup
ts
742                                                                                     ;   disabled.
743       P:0001C9 P:0001C9 07F41B            MOVEP             #$0003,X:SCCR           ; SCI clock: utility board data rate =
                            000003
744                                                                                     ;   (390,625 kbits/sec); internal clock.
745       P:0001CB P:0001CB 07F41F            MOVEP             #%011,X:PCRE            ; Port Control Register = RXD, TXD enabled
                            000003
746       P:0001CD P:0001CD 07F41E            MOVEP             #%000,X:PRRE            ; Port Direction Register (0 = Input)
                            000000
747    
748                                 ;       PE0 = RXD
749                                 ;       PE1 = TXD
750                                 ;       PE2 = SCLK
751    
752                                 ; Program one of the three timers as an exposure timer
753       P:0001CF P:0001CF 07F403            MOVEP             #$C34F,X:TPLR           ; Prescaler to generate millisecond timer,
                            00C34F
754                                                                                     ;  counting from the system clock / 2 = 50 M
Hz
755       P:0001D1 P:0001D1 07F40F            MOVEP             #$208200,X:TCSR0        ; Clear timer complete bit and enable presca
ler
                            208200
756       P:0001D3 P:0001D3 07F40E            MOVEP             #0,X:TLR0               ; Timer load register
                            000000
757    
758                                 ; Enable interrupts for the SCI port only
759       P:0001D5 P:0001D5 08F4BF            MOVEP             #$000000,X:IPRC         ; No interrupts allowed
                            000000
760       P:0001D7 P:0001D7 08F4BE            MOVEP             #>$80,X:IPRP            ; Enable SCI interrupt only, IPR = 1
                            000080
761       P:0001D9 P:0001D9 00FCB8            ANDI    #$FC,MR                           ; Unmask all interrupt levels
762    
763                                 ; Initialize the fiber optic serial receiver circuitry
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 15



764       P:0001DA P:0001DA 061480            DO      #20,L_FO_INIT
                            0001DF
765       P:0001DC P:0001DC 5FF000            MOVE                          Y:RDFO,B
                            FFFFF1
766       P:0001DE P:0001DE 0605A0            REP     #5
767       P:0001DF P:0001DF 000000            NOP
768                                 L_FO_INIT
769    
770                                 ; Pulse PRSFIFO* low to revive the CMDRST* instruction and reset the FIFO
771       P:0001E0 P:0001E0 44F400            MOVE              #1000000,X0             ; Delay by 10 milliseconds
                            0F4240
772       P:0001E2 P:0001E2 06C400            DO      X0,*+3
                            0001E4
773       P:0001E4 P:0001E4 000000            NOP
774       P:0001E5 P:0001E5 0A8908            BCLR    #8,X:HDR
775       P:0001E6 P:0001E6 0614A0            REP     #20
776       P:0001E7 P:0001E7 000000            NOP
777       P:0001E8 P:0001E8 0A8928            BSET    #8,X:HDR
778    
779                                 ; Reset the utility board
780       P:0001E9 P:0001E9 0A0F05            BCLR    #5,X:<LATCH
781       P:0001EA P:0001EA 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                            00000F
782       P:0001EC P:0001EC 06C8A0            REP     #200                              ; Delay by RESET* low time
783       P:0001ED P:0001ED 000000            NOP
784       P:0001EE P:0001EE 0A0F25            BSET    #5,X:<LATCH
785       P:0001EF P:0001EF 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                            00000F
786       P:0001F1 P:0001F1 56F400            MOVE              #200000,A               ; Delay 2 msec for utility boot
                            030D40
787       P:0001F3 P:0001F3 06CE00            DO      A,*+3
                            0001F5
788       P:0001F5 P:0001F5 000000            NOP
789    
790                                 ; Put all the analog switch inputs to low so they draw minimum current
791       P:0001F6 P:0001F6 012F23            BSET    #3,X:PCRD                         ; Turn the serial clock on
792       P:0001F7 P:0001F7 56F400            MOVE              #$0C3000,A              ; Value of integrate speed and gain switches
                            0C3000
793       P:0001F9 P:0001F9 20001B            CLR     B
794       P:0001FA P:0001FA 241000            MOVE              #$100000,X0             ; Increment over board numbers for DAC write
s
795       P:0001FB P:0001FB 45F400            MOVE              #$001000,X1             ; Increment over board numbers for WRSS writ
es
                            001000
796       P:0001FD P:0001FD 060F80            DO      #15,L_ANALOG                      ; Fifteen video processor boards maximum
                            000205
797       P:0001FF P:0001FF 0D020C            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
798       P:000200 P:000200 200040            ADD     X0,A
799       P:000201 P:000201 5F7000            MOVE                          B,Y:WRSS    ; This is for the fast analog switches
                            FFFFF3
800       P:000203 P:000203 0620A3            REP     #800                              ; Delay for the serial data transmission
801       P:000204 P:000204 000000            NOP
802       P:000205 P:000205 200068            ADD     X1,B                              ; Increment the video and clock driver numbe
rs
803                                 L_ANALOG
804       P:000206 P:000206 0A0F00            BCLR    #CDAC,X:<LATCH                    ; Enable clearing of DACs
805       P:000207 P:000207 0A0F02            BCLR    #ENCK,X:<LATCH                    ; Disable clock and DAC output switches
806       P:000208 P:000208 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Execute these two operations
                            00000F
807       P:00020A P:00020A 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
808       P:00020B P:00020B 0C0223            JMP     <SKIP
809    
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 16



810                                 ; Transmit contents of accumulator A1 over the synchronous serial transmitter
811                                 XMIT_A_WORD
812       P:00020C P:00020C 07F42C            MOVEP             #0,X:TX10               ; This helps, don't know why
                            000000
813       P:00020E P:00020E 547000            MOVE              A1,X:SV_A1
                            00000E
814       P:000210 P:000210 000000            NOP
815       P:000211 P:000211 01A786            JCLR    #TDE,X:SSISR1,*                   ; Start bit
                            000211
816       P:000213 P:000213 07F42C            MOVEP             #$010000,X:TX10
                            010000
817       P:000215 P:000215 060380            DO      #3,L_X
                            00021B
818       P:000217 P:000217 01A786            JCLR    #TDE,X:SSISR1,*                   ; Three data bytes
                            000217
819       P:000219 P:000219 04CCCC            MOVEP             A1,X:TX10
820       P:00021A P:00021A 0C1E90            LSL     #8,A
821       P:00021B P:00021B 000000            NOP
822                                 L_X
823       P:00021C P:00021C 01A786            JCLR    #TDE,X:SSISR1,*                   ; Zeroes to bring transmitter low
                            00021C
824       P:00021E P:00021E 07F42C            MOVEP             #0,X:TX10
                            000000
825       P:000220 P:000220 54F000            MOVE              X:SV_A1,A1
                            00000E
826       P:000222 P:000222 00000C            RTS
827    
828                                 SKIP
829    
830                                 ; Set up the circular SCI buffer, 32 words in size
831       P:000223 P:000223 64F400            MOVE              #SCI_TABLE,R4
                            000400
832       P:000225 P:000225 051FA4            MOVE              #31,M4
833       P:000226 P:000226 647000            MOVE              R4,X:(SCI_TABLE+33)
                            000421
834    
835                                           IF      @SCP("HOST","ROM")
843                                           ENDIF
844    
845       P:000228 P:000228 44F400            MOVE              #>$AC,X0
                            0000AC
846       P:00022A P:00022A 440100            MOVE              X0,X:<FO_HDR
847    
848       P:00022B P:00022B 0C0181            JMP     <STARTUP
849    
850                                 ;  ****************  X: Memory tables  ********************
851    
852                                 ; Define the address in P: space where the table of constants begins
853    
854                                  X_BOOT_START
855       00022A                              EQU     @LCV(L)-2
856    
857                                           IF      @SCP("HOST","ROM")
859                                           ENDIF
860                                           IF      @SCP("HOST","HOST")
861       X:000000 X:000000                   ORG     X:0,X:0
862                                           ENDIF
863    
864                                 ; Special storage area - initialization constants and scratch space
865       X:000000 X:000000         STATUS    DC      4                                 ; Controller status bits
866    
867       000001                    FO_HDR    EQU     STATUS+1                          ; Fiber optic write bytes
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 17



868       000005                    HEADER    EQU     FO_HDR+4                          ; Command header
869       000006                    NWORDS    EQU     HEADER+1                          ; Number of words in the command
870       000007                    COM_BUF   EQU     NWORDS+1                          ; Command buffer
871       00000E                    SV_A1     EQU     COM_BUF+7                         ; Save accumulator A1
872    
873                                           IF      @SCP("HOST","ROM")
878                                           ENDIF
879    
880                                           IF      @SCP("HOST","HOST")
881       X:00000F X:00000F                   ORG     X:$F,X:$F
882                                           ENDIF
883    
884                                 ; Parameter table in P: space to be copied into X: space during
885                                 ;   initialization, and is copied from ROM by the DSP boot
886       X:00000F X:00000F         LATCH     DC      $7A                               ; Starting value in latch chip U25
887                                  EXPOSURE_TIME
888       X:000010 X:000010                   DC      0                                 ; Exposure time in milliseconds
889                                  ELAPSED_TIME
890       X:000011 X:000011                   DC      0                                 ; Time elapsed so far in the exposure
891       X:000012 X:000012         ONE       DC      1                                 ; One
892       X:000013 X:000013         TWO       DC      2                                 ; Two
893       X:000014 X:000014         THREE     DC      3                                 ; Three
894       X:000015 X:000015         SEVEN     DC      7                                 ; Seven
895       X:000016 X:000016         MASK1     DC      $FCFCF8                           ; Mask for checking header
896       X:000017 X:000017         MASK2     DC      $030300                           ; Mask for checking header
897       X:000018 X:000018         DONE      DC      'DON'                             ; Standard reply
898       X:000019 X:000019         SBRD      DC      $020000                           ; Source Identification number
899       X:00001A X:00001A         TIM_DRB   DC      $000200                           ; Destination = timing board number
900       X:00001B X:00001B         DMASK     DC      $00FF00                           ; Mask to get destination board number
901       X:00001C X:00001C         SMASK     DC      $FF0000                           ; Mask to get source board number
902       X:00001D X:00001D         ERR       DC      'ERR'                             ; An error occurred
903       X:00001E X:00001E         C100K     DC      100000                            ; Delay for WRROM = 1 millisec
904       X:00001F X:00001F         IDL_ADR   DC      TST_RCV                           ; Address of idling routine
905       X:000020 X:000020         EXP_ADR   DC      0                                 ; Jump to this address during exposures
906    
907                                 ; Places for saving register values
908       X:000021 X:000021         SAVE_SR   DC      0                                 ; Status Register
909       X:000022 X:000022         SAVE_X1   DC      0
910       X:000023 X:000023         SAVE_A1   DC      0
911       X:000024 X:000024         SAVE_R0   DC      0
912       X:000025 X:000025         RCV_ERR   DC      0
913       X:000026 X:000026         SCI_A1    DC      0                                 ; Contents of accumulator A1 in RCV ISR
914       X:000027 X:000027         SCI_R0    DC      SRXL
915    
916                                 ; Command table
917       000028                    COM_TBL_R EQU     @LCV(R)
918       X:000028 X:000028         COM_TBL   DC      'TDL',TDL                         ; Test Data Link
919       X:00002A X:00002A                   DC      'RDM',RDMEM                       ; Read from DSP or EEPROM memory
920       X:00002C X:00002C                   DC      'WRM',WRMEM                       ; Write to DSP memory
921       X:00002E X:00002E                   DC      'LDA',LDAPPL                      ; Load application from EEPROM to DSP
922       X:000030 X:000030                   DC      'STP',STOP_IDLE_CLOCKING
923       X:000032 X:000032                   DC      'DON',START                       ; Nothing special
924       X:000034 X:000034                   DC      'ERR',START                       ; Nothing special
925    
926                                  END_COMMAND_TABLE
927       000036                              EQU     @LCV(R)
928    
929                                 ; The table at SCI_TABLE is for words received from the utility board, written by
930                                 ;   the interrupt service routine SCI_RCV. Note that it is 32 words long,
931                                 ;   hard coded, and the 33rd location contains the pointer to words that have
932                                 ;   been processed by moving them from the SCI_TABLE to the COM_BUF.
933    
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timboot.asm  Page 18



934                                           IF      @SCP("HOST","ROM")
936                                           ENDIF
937    
938       000036                    END_ADR   EQU     @LCV(L)                           ; End address of P: code written to ROM
939    
940       P:00022C P:00022C                   ORG     P:,P:
941                                 ; sg 2006-02-02 shouldn't the next line contain TIMREV5 (cf. timhdr.asm) ?!
942                                 ; CC      EQU     CCDVIDREV3B+TIMREV4+UTILREV3+SHUTTER_CC+TEMP_POLY+SUBARRAY+SPLIT_SERIAL
943    
944       0015B0                    CC        EQU     CCDVIDREV3B+TIMREV5+UTILREV3+SHUTTER_CC+TEMP_POLY+SUBARRAY+SPLIT_SERIAL
945    
946                                 ; Put number of words of application in P: for loading application from EEPROM
947       P:00022C P:00022C                   DC      TIMBOOT_X_MEMORY-@LCV(L)-1
948    
949                                 ; Keep the CCD idling when not reading out
950       P:00022D P:00022D 060140  IDLE      DO      Y:<NSR,IDL1                       ; Loop over number of pixels per line
                            000236
951       P:00022F P:00022F 304600            MOVE              #<SERIAL_IDLE,R0        ; Serial transfer on pixel
952       P:000230 P:000230 0D03A8            JSR     <CLOCK                            ; Go to it
953       P:000231 P:000231 330700            MOVE              #COM_BUF,R3
954       P:000232 P:000232 0D00A5            JSR     <GET_RCV                          ; Check for FO or SSI commands
955       P:000233 P:000233 0E0236            JCC     <NO_COM                           ; Continue IDLE if no commands received
956       P:000234 P:000234 00008C            ENDDO
957       P:000235 P:000235 0C005D            JMP     <PRC_RCV                          ; Go process header and command
958       P:000236 P:000236 000000  NO_COM    NOP
959                                 IDL1
960       P:000237 P:000237 301F00            MOVE              #<PARALLEL,R0           ; Address of parallel clocking waveform
961       P:000238 P:000238 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge
962       P:000239 P:000239 0C022D            JMP     <IDLE
963    
964                                 ;  *****************  Exposure and readout routines  *****************
965    
966                                 ; Overall loop - transfer and read NPR lines
967    
968                                 ; Parallel shift the image from the Imaging area into the Storage area
969                                 ; Calculate some readout parameters
970                                 ;this is pasted in from leachemail\lbnl\2kx4k\tim.asm r.a. 3/21/2011
971       P:00023A P:00023A 200013  RDCCD     CLR     A
972       P:00023B P:00023B 0A00B0            JSET    #ST_SA,X:STATUS,SUB_IMG
                            000247
973       P:00023D P:00023D 5C1100            MOVE                          A1,Y:<NP_SKIP ; Zero these all out
974       P:00023E P:00023E 5C1200            MOVE                          A1,Y:<NS_SKP1
975       P:00023F P:00023F 5C1300            MOVE                          A1,Y:<NS_SKP2
976       P:000240 P:000240 5E8100            MOVE                          Y:<NSR,A    ; NS_READ = NSR / 2
977                                 ; !!!   ASR     A                       ; Effectively split serial since there
978                                                                                     ; if _LR readout then split the serial for f
ull images (garbage for roi)
979       P:000241 P:000241 0A0085            JCLR    #SPLIT_S,X:STATUS,*+3
                            000244
980       P:000243 P:000243 200022            ASR     A                                 ; Split serials requires / 2
981       P:000244 P:000244 000000            NOP                                       ; else not for roi for __L or __R
982       P:000245 P:000245 5E0A00            MOVE                          A,Y:<NS_READ ; Number of columns in each subimage
983       P:000246 P:000246 0C024A            JMP     <WT_CLK
984    
985                                 ; Loop over the required number of subimage boxes
986       P:000247 P:000247 5E9500  SUB_IMG   MOVE                          Y:<NSREAD,A
987                                 ; !!!   ASR     A                       ; Effectively split serial since there
988       P:000248 P:000248 000000            NOP                                       ;   are two CCDs
989       P:000249 P:000249 5E0A00            MOVE                          A,Y:<NS_READ ; Number of columns in each subimage
990    
991                                 ; Start the loop for parallel shifting desired number of lines
992                                 WT_CLK
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  tim.asm  Page 19



993    
994                                 ; Later -->     JSR     <GENERATE_SERIAL_WAVEFORM
995    
996       P:00024A P:00024A 0D03A5            JSR     <WAIT_TO_FINISH_CLOCKING
997    
998                                 ; Skip over the required number of rows for subimage readout
999       P:00024B P:00024B 5E9100            MOVE                          Y:<NP_SKIP,A ; Number of rows to skip
1000      P:00024C P:00024C 200003            TST     A
1001      P:00024D P:00024D 0EA256            JEQ     <CLR_SR
1002      P:00024E P:00024E 061140            DO      Y:<NP_SKIP,L_PSKP
                            000255
1003      P:000250 P:000250 060640            DO      Y:<NPBIN,L_PSKIP
                            000254
1004      P:000252 P:000252 301F00            MOVE              #<PARALLEL,R0
1005      P:000253 P:000253 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge
1006      P:000254 P:000254 000000            NOP
1007      P:000255 P:000255 000000  L_PSKIP   NOP
1008                                L_PSKP
1009   
1010                                ; Clear out the accumulated charge from the serial shift register
1011      P:000256 P:000256 060340  CLR_SR    DO      Y:<NSCLR,L_CLRSR                  ; Loop over number of pixels to skip
                            00025A
1012      P:000258 P:000258 688E00            MOVE                          Y:<SERIAL_SKIP,R0 ; Address of serial skipping waveforms
1013      P:000259 P:000259 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge
1014      P:00025A P:00025A 000000            NOP
1015                                L_CLRSR                                             ; Do loop restriction
1016   
1017                                ; This is the main loop over each line to be read out
1018      P:00025B P:00025B 060240            DO      Y:<NPR,LPR                        ; Number of rows to read out
                            000290
1019   
1020                                ; Exercise the parallel clocks, including binning if needed
1021      P:00025D P:00025D 060640            DO      Y:<NPBIN,L_PBIN
                            000261
1022      P:00025F P:00025F 301F00            MOVE              #<PARALLEL,R0
1023      P:000260 P:000260 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge
1024      P:000261 P:000261 000000            NOP
1025                                L_PBIN
1026   
1027                                ; Check for a command once per line. Only the ABORT command should be issued.
1028      P:000262 P:000262 330700            MOVE              #COM_BUF,R3
1029      P:000263 P:000263 0D00A5            JSR     <GET_RCV                          ; Was a command received?
1030      P:000264 P:000264 0E026A            JCC     <CONTINUE_READ                    ; If no, continue reading out
1031      P:000265 P:000265 0C005D            JMP     <PRC_RCV                          ; If yes, go process it
1032   
1033                                ; Abort the readout currently underway
1034      P:000266 P:000266 0A0084  ABR_RDC   JCLR    #ST_RDC,X:<STATUS,ABORT_EXPOSURE
                            000355
1035      P:000268 P:000268 00008C            ENDDO                                     ; Properly terminate readout loop
1036      P:000269 P:000269 0C0355            JMP     <ABORT_EXPOSURE
1037   
1038                                ; Skip over NS_SKP1 columns for subimage readout
1039                                CONTINUE_READ
1040      P:00026A P:00026A 5E9200            MOVE                          Y:<NS_SKP1,A ; Number of columns to skip
1041      P:00026B P:00026B 200003            TST     A
1042      P:00026C P:00026C 0EF272            JLE     <L_READ
1043      P:00026D P:00026D 061240            DO      Y:<NS_SKP1,L_SKP1                 ; Number of waveform entries total
                            000271
1044      P:00026F P:00026F 688E00            MOVE                          Y:<SERIAL_SKIP,R0 ; Waveform table starting address
1045      P:000270 P:000270 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge               
    ; Go clock out the CCD charge
1046      P:000271 P:000271 000000            NOP
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  tim.asm  Page 20



1047                                L_SKP1
1048   
1049                                ; Finally read some real pixels
1050      P:000272 P:000272 060A40  L_READ    DO      Y:<NS_READ,L_RD
                            000276
1051      P:000274 P:000274 688F00            MOVE                          Y:<SERIAL_READ,R0
1052      P:000275 P:000275 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge               
    ; Go clock out the CCD charge
1053      P:000276 P:000276 000000            NOP
1054                                L_RD
1055   
1056                                ; Skip over NS_SKP2 columns if needed for subimage readout
1057      P:000277 P:000277 5E9300            MOVE                          Y:<NS_SKP2,A ; Number of columns to skip
1058      P:000278 P:000278 200003            TST     A
1059      P:000279 P:000279 0EF27F            JLE     <L_BIAS
1060      P:00027A P:00027A 061340            DO      Y:<NS_SKP2,L_SKP2
                            00027E
1061      P:00027C P:00027C 688E00            MOVE                          Y:<SERIAL_SKIP,R0 ; Waveform table starting address
1062      P:00027D P:00027D 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge               
    ; Go clock out the CCD charge
1063      P:00027E P:00027E 000000            NOP
1064                                L_SKP2
1065   
1066                                ; And read the bias pixels if in subimage readout mode
1067      P:00027F P:00027F 0A0090  L_BIAS    JCLR    #ST_SA,X:STATUS,END_ROW           ; ST_SA = 0 => full image readout
                            000290
1068      P:000281 P:000281 200003            TST     A
1069      P:000282 P:000282 0EF290            JLE     <END_ROW
1070      P:000283 P:000283 5E9400            MOVE                          Y:<NRBIAS,A ; NR_BIAS = 0 => no bias pixels
1071      P:000284 P:000284 200003            TST     A
1072      P:000285 P:000285 0EF290            JLE     <END_ROW
1073      P:000286 P:000286 0A0085            JCLR    #SPLIT_S,X:STATUS,*+3
                            000289
1074      P:000288 P:000288 200022            ASR     A                                 ; Split serials require / 2
1075      P:000289 P:000289 000000            NOP
1076      P:00028A P:00028A 06CC00            DO      A1,L_BRD                          ; Number of pixels to read out
                            00028E
1077      P:00028C P:00028C 688F00            MOVE                          Y:<SERIAL_READ,R0
1078      P:00028D P:00028D 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge               
    ; Go clock out the CCD charg
1079      P:00028E P:00028E 000000            NOP
1080      P:00028F P:00028F 000000  L_BRD     NOP
1081      P:000290 P:000290 000000  END_ROW   NOP
1082      P:000291 P:000291 000000  LPR       NOP                                       ; End of parallel loop
1083   
1084                                ; Restore the controller to non-image data transfer and idling if necessary
1085      P:000292 P:000292 0A0082  RDC_END   JCLR    #IDLMODE,X:<STATUS,NO_IDL         ; Don't idle after readout
                            000298
1086      P:000294 P:000294 60F400            MOVE              #IDLE,R0
                            00022D
1087      P:000296 P:000296 601F00            MOVE              R0,X:<IDL_ADR
1088      P:000297 P:000297 0C029A            JMP     <RDC_E
1089      P:000298 P:000298 305A00  NO_IDL    MOVE              #TST_RCV,R0
1090      P:000299 P:000299 601F00            MOVE              R0,X:<IDL_ADR
1091      P:00029A P:00029A 0D03A5  RDC_E     JSR     <WAIT_TO_FINISH_CLOCKING
1092      P:00029B P:00029B 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; Set status to not reading out
1093      P:00029C P:00029C 0C0054            JMP     <START
1094                                ; back 2 normal time/space continum
1095   
1096                                          INCLUDE "timCCD1_8.asm"                   ; Generic
1097                                ; Miscellaneous CCD control routines, common to all detector types
1098   
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 21



1099                                POWER_OFF
1100      P:00029D P:00029D 0D02D3            JSR     <CLEAR_SWITCHES_AND_DACS          ; Clear all analog switches
1101      P:00029E P:00029E 0A8922            BSET    #LVEN,X:HDR
1102      P:00029F P:00029F 0A8923            BSET    #HVEN,X:HDR
1103      P:0002A0 P:0002A0 0C008F            JMP     <FINISH
1104   
1105                                ; Execute the power-on cycle, as a command
1106                                POWER_ON
1107      P:0002A1 P:0002A1 0D02D3            JSR     <CLEAR_SWITCHES_AND_DACS          ; Clear switches and DACs
1108   
1109                                ; Turn on the low voltages (+/- 6.5V, +/- 16.5V) and delay
1110      P:0002A2 P:0002A2 0A8902            BCLR    #LVEN,X:HDR                       ; Set these signals to DSP outputs
1111      P:0002A3 P:0002A3 44F400            MOVE              #2000000,X0
                            1E8480
1112      P:0002A5 P:0002A5 06C400            DO      X0,*+3                            ; Wait 20 millisec for settling
                            0002A7
1113      P:0002A7 P:0002A7 000000            NOP
1114   
1115                                ; Turn on the high +36 volt power line and delay
1116      P:0002A8 P:0002A8 0A8903            BCLR    #HVEN,X:HDR                       ; HVEN = Low => Turn on +36V
1117      P:0002A9 P:0002A9 44F400            MOVE              #2000000,X0
                            1E8480
1118      P:0002AB P:0002AB 06C400            DO      X0,*+3                            ; Wait 20 millisec for settling
                            0002AD
1119      P:0002AD P:0002AD 000000            NOP
1120   
1121      P:0002AE P:0002AE 0A8980            JCLR    #PWROK,X:HDR,PWR_ERR              ; Test if the power turned on properly
                            0002B5
1122      P:0002B0 P:0002B0 0D02B8            JSR     <SET_BIASES                       ; Turn on the DC bias supplies
1123      P:0002B1 P:0002B1 60F400            MOVE              #IDLE,R0                ; Put controller in IDLE state
                            00022D
1124      P:0002B3 P:0002B3 601F00            MOVE              R0,X:<IDL_ADR
1125      P:0002B4 P:0002B4 0C008F            JMP     <FINISH
1126   
1127                                ; The power failed to turn on because of an error on the power control board
1128      P:0002B5 P:0002B5 0A8922  PWR_ERR   BSET    #LVEN,X:HDR                       ; Turn off the low voltage emable line
1129      P:0002B6 P:0002B6 0A8923            BSET    #HVEN,X:HDR                       ; Turn off the high voltage emable line
1130      P:0002B7 P:0002B7 0C008D            JMP     <ERROR
1131   
1132                                ; Set all the DC bias voltages and video processor offset values, reading
1133                                ;   them from the 'DACS' table
1134                                SET_BIASES
1135      P:0002B8 P:0002B8 012F23            BSET    #3,X:PCRD                         ; Turn on the serial clock
1136      P:0002B9 P:0002B9 0A0F01            BCLR    #1,X:<LATCH                       ; Separate updates of clock driver
1137      P:0002BA P:0002BA 0A0F20            BSET    #CDAC,X:<LATCH                    ; Disable clearing of DACs
1138      P:0002BB P:0002BB 0A0F22            BSET    #ENCK,X:<LATCH                    ; Enable clock and DAC output switches
1139      P:0002BC P:0002BC 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1140      P:0002BE P:0002BE 0D03B3            JSR     <PAL_DLY                          ; Delay for all this to happen
1141      P:0002BF P:0002BF 60F400            MOVE              #DACS,R0                ; Get starting address of DAC values
                            0000BF
1142      P:0002C1 P:0002C1 0D02C9            JSR     <WR_DACS                          ; Update the DACs
1143   
1144                                ; Let the DAC voltages all ramp up before exiting
1145      P:0002C2 P:0002C2 44F400            MOVE              #400000,X0
                            061A80
1146      P:0002C4 P:0002C4 06C400            DO      X0,*+3                            ; 4 millisec delay
                            0002C6
1147      P:0002C6 P:0002C6 000000            NOP
1148      P:0002C7 P:0002C7 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1149      P:0002C8 P:0002C8 00000C            RTS
1150   
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 22



1151                                ; Read DAC values from a table, and write them to the DACs
1152      P:0002C9 P:0002C9 065840  WR_DACS   DO      Y:(R0)+,L_DAC                     ; Repeat Y:(R0)+ times
                            0002CD
1153      P:0002CB P:0002CB 5ED800            MOVE                          Y:(R0)+,A   ; Read the table entry
1154      P:0002CC P:0002CC 0D020C            JSR     <XMIT_A_WORD                      ; Transmit it to TIM-A-STD
1155      P:0002CD P:0002CD 000000            NOP
1156                                L_DAC
1157      P:0002CE P:0002CE 00000C            RTS
1158   
1159                                SET_BIAS_VOLTAGES
1160      P:0002CF P:0002CF 0D02B8            JSR     <SET_BIASES
1161      P:0002D0 P:0002D0 0C008F            JMP     <FINISH
1162   
1163      P:0002D1 P:0002D1 0D02D3  CLR_SWS   JSR     <CLEAR_SWITCHES_AND_DACS
1164      P:0002D2 P:0002D2 0C008F            JMP     <FINISH
1165   
1166                                CLEAR_SWITCHES_AND_DACS
1167      P:0002D3 P:0002D3 0A0F00            BCLR    #CDAC,X:<LATCH                    ; Clear all the DACs
1168      P:0002D4 P:0002D4 0A0F02            BCLR    #ENCK,X:<LATCH                    ; Disable all the output switches
1169      P:0002D5 P:0002D5 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1170      P:0002D7 P:0002D7 012F23            BSET    #3,X:PCRD                         ; Turn the serial clock on
1171      P:0002D8 P:0002D8 56F400            MOVE              #$0C3000,A              ; Value of integrate speed and gain switches
                            0C3000
1172      P:0002DA P:0002DA 20001B            CLR     B
1173      P:0002DB P:0002DB 241000            MOVE              #$100000,X0             ; Increment over board numbers for DAC write
s
1174      P:0002DC P:0002DC 45F400            MOVE              #$001000,X1             ; Increment over board numbers for WRSS writ
es
                            001000
1175      P:0002DE P:0002DE 060F80            DO      #15,L_VIDEO                       ; Fifteen video processor boards maximum
                            0002E5
1176      P:0002E0 P:0002E0 0D020C            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1177      P:0002E1 P:0002E1 200040            ADD     X0,A
1178      P:0002E2 P:0002E2 5F7000            MOVE                          B,Y:WRSS
                            FFFFF3
1179      P:0002E4 P:0002E4 0D03B3            JSR     <PAL_DLY                          ; Delay for the serial data transmission
1180      P:0002E5 P:0002E5 200068            ADD     X1,B
1181                                L_VIDEO
1182      P:0002E6 P:0002E6 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1183      P:0002E7 P:0002E7 00000C            RTS
1184   
1185                                SET_SHUTTER_STATE
1186      P:0002E8 P:0002E8 568F00            MOVE              X:LATCH,A
1187      P:0002E9 P:0002E9 0140C6            AND     #$FFEF,A
                            00FFEF
1188      P:0002EB P:0002EB 200042            OR      X0,A
1189      P:0002EC P:0002EC 000000            NOP
1190      P:0002ED P:0002ED 540F00            MOVE              A1,X:LATCH
1191      P:0002EE P:0002EE 09CC35            MOVEP             A1,Y:WRLATCH
1192      P:0002EF P:0002EF 00000C            RTS
1193   
1194                                ; Open the shutter from the timing board, executed as a command
1195                                OPEN_SHUTTER
1196      P:0002F0 P:0002F0 240000            MOVE              #0,X0
1197      P:0002F1 P:0002F1 0D02E8            JSR     <SET_SHUTTER_STATE
1198      P:0002F2 P:0002F2 0C008F            JMP     <FINISH
1199   
1200                                ; Close the shutter from the timing board, executed as a command
1201                                CLOSE_SHUTTER
1202      P:0002F3 P:0002F3 44F400            MOVE              #>$10,X0
                            000010
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 23



1203      P:0002F5 P:0002F5 0D02E8            JSR     <SET_SHUTTER_STATE
1204      P:0002F6 P:0002F6 0C008F            JMP     <FINISH
1205   
1206                                ; Shutter subroutines
1207      P:0002F7 P:0002F7 240000  OSHUT     MOVE              #0,X0
1208      P:0002F8 P:0002F8 0D02E8            JSR     <SET_SHUTTER_STATE
1209      P:0002F9 P:0002F9 00000C            RTS
1210   
1211      P:0002FA P:0002FA 44F400  CSHUT     MOVE              #>$10,X0
                            000010
1212      P:0002FC P:0002FC 0D02E8            JSR     <SET_SHUTTER_STATE
1213      P:0002FD P:0002FD 00000C            RTS
1214   
1215                                ; Clear the CCD, executed as a command
1216      P:0002FE P:0002FE 0D0300  CLEAR     JSR     <CLR_CCD
1217      P:0002FF P:0002FF 0C008F            JMP     <FINISH
1218   
1219                                ; Default clearing routine with serial clocks inactive
1220                                ; Fast clear image before each exposure, executed as a subroutine
1221      P:000300 P:000300 060440  CLR_CCD   DO      Y:<NPCLR,LPCLR                    ; Loop over number of lines in image
                            000305
1222      P:000302 P:000302 60F400            MOVE              #PARALLEL_CLEAR,R0      ; Address of parallel transfer waveform
                            000027
1223      P:000304 P:000304 0D03A8            JSR     <CLOCK                            ; Go clock out the CCD charge
1224      P:000305 P:000305 000000            NOP                                       ; Do loop restriction
1225                                LPCLR
1226      P:000306 P:000306 00000C            RTS
1227   
1228                                ; Start the exposure timer and monitor its progress
1229      P:000307 P:000307 07F40E  EXPOSE    MOVEP             #0,X:TLR0               ; Load 0 into counter timer
                            000000
1230      P:000309 P:000309 579000            MOVE              X:<EXPOSURE_TIME,B
1231      P:00030A P:00030A 20000B            TST     B                                 ; Special test for zero exposure time
1232      P:00030B P:00030B 0EA317            JEQ     <END_EXP                          ; Don't even start an exposure
1233      P:00030C P:00030C 01418C            SUB     #1,B                              ; Timer counts from X:TCPR0+1 to zero
1234      P:00030D P:00030D 010F20            BSET    #TIM_BIT,X:TCSR0                  ; Enable the timer #0
1235      P:00030E P:00030E 577000            MOVE              B,X:TCPR0
                            FFFF8D
1236      P:000310 P:000310 0A8989  CHK_RCV   JCLR    #EF,X:HDR,CHK_TIM                 ; Simple test for fast execution
                            000315
1237      P:000312 P:000312 330700            MOVE              #COM_BUF,R3             ; The beginning of the command buffer
1238      P:000313 P:000313 0D00A5            JSR     <GET_RCV                          ; Check for an incoming command
1239      P:000314 P:000314 0E805D            JCS     <PRC_RCV                          ; If command is received, go check it
1240      P:000315 P:000315 018F95  CHK_TIM   JCLR    #TCF,X:TCSR0,CHK_RCV              ; Wait for timer to equal compare value
                            000310
1241      P:000317 P:000317 010F00  END_EXP   BCLR    #TIM_BIT,X:TCSR0                  ; Disable the timer
1242      P:000318 P:000318 0AE780            JMP     (R7)                              ; This contains the return address
1243   
1244                                ; Start the exposure, operate the shutter, and initiate the CCD readout
1245                                START_EXPOSURE
1246      P:000319 P:000319 57F400            MOVE              #$020102,B              ; Initialize the PCI image address
                            020102
1247      P:00031B P:00031B 0D00EB            JSR     <XMT_WRD
1248      P:00031C P:00031C 57F400            MOVE              #'IIA',B
                            494941
1249      P:00031E P:00031E 0D00EB            JSR     <XMT_WRD
1250   
1251                                ; Clear out the whole array
1252                                ;       JSR     <CLR_CCD                ; Clear the CCD charge
1253                                                                                    ; 4/7/2011 from leach's email.  nec?  r.a.
1254                                                                                    ;MOVE    #<PARALLELS_DURING_EXPOSURE,R0
1255                                                                                    ;CLOCK
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 24



1256                                                                                    ;JSR    <WAIT_TO_FINISH_CLOCKING
1257                                                                                    ; back 2 normal continumn
1258      P:00031F P:00031F 330700            MOVE              #<COM_BUF,R3
1259      P:000320 P:000320 0D00A5            JSR     <GET_RCV                          ; Check for FO command
1260      P:000321 P:000321 0E805D            JCS     <PRC_RCV                          ; Process the command
1261      P:000322 P:000322 305A00            MOVE              #TST_RCV,R0             ; Process commands during the exposure
1262      P:000323 P:000323 601F00            MOVE              R0,X:<IDL_ADR
1263      P:000324 P:000324 0D03A5            JSR     <WAIT_TO_FINISH_CLOCKING
1264   
1265                                ; Operate the shutter if needed and begin exposure
1266                                ;       JCLR    #SHUT,X:STATUS,L_SEX0
1267                                ;       JSR     <OSHUT                  ; Open the shutter if needed
1268      P:000325 P:000325 67F400  L_SEX0    MOVE              #L_SEX1,R7              ; Return address at end of exposure
                            000328
1269      P:000327 P:000327 0C0307            JMP     <EXPOSE                           ; Delay for specified exposure time
1270                                L_SEX1
1271   
1272                                ;brought in 3/21/2011 r.a.
1273      P:000328 P:000328 0D0398  STR_RDC   JSR     <PCI_READ_IMAGE                   ; Get the PCI board reading the image
1274   
1275                                ;       JCLR    #SHUT,X:STATUS,S_DEL0
1276                                ;       JSR     <CSHUT                  ; Close the shutter if necessary
1277      P:000329 P:000329 5E8800            MOVE                          Y:<SH_DEL,A
1278      P:00032A P:00032A 200003            TST     A
1279      P:00032B P:00032B 0EF334            JLE     <S_DEL0
1280      P:00032C P:00032C 44F400            MOVE              #100000,X0
                            0186A0
1281      P:00032E P:00032E 06CE00            DO      A,S_DEL0                          ; Delay by Y:SH_DEL milliseconds
                            000333
1282      P:000330 P:000330 06C400            DO      X0,S_DEL1
                            000332
1283      P:000332 P:000332 000000            NOP
1284      P:000333 P:000333 000000  S_DEL1    NOP
1285                                S_DEL0
1286   
1287                                ; this section brought in for the new roi code from leachEmail\lbnl_genIII\  3/21/2011 r.a.
1288                                ;  must do some stuff b4 the jump. r.a.
1289                                ;  shutter, waiting for it to close and then reading out
1290      P:000334 P:000334 0A00AA  TST_SYN   JSET    #TST_IMG,X:STATUS,SYNTHETIC_IMAGE
                            000365
1291   
1292      P:000336 P:000336 30BB00            MOVE              #<PARALLELS_DURING_READOUT,R0
1293      P:000337 P:000337 0D03A8            JSR     <CLOCK
1294      P:000338 P:000338 0C023A            JMP     <RDCCD                            ; Finally, go read out the CCD
1295   
1296                                ; Set software to IDLE mode
1297      P:000339 P:000339 44F400  IDL       MOVE              #IDLE,X0                ; Exercise clocks when idling
                            00022D
1298      P:00033B P:00033B 441F00            MOVE              X0,X:<IDL_ADR
1299      P:00033C P:00033C 0A0022            BSET    #IDLMODE,X:<STATUS                ; Idle after readout
1300      P:00033D P:00033D 0C008F            JMP     <FINISH                           ; Need to send header and 'DON'
1301   
1302                                ; Hold clocks during exposure, idle again afterwards
1303      P:00033E P:00033E 245A00  HLD       MOVE              #TST_RCV,X0             ; Wait for commands during exposure
1304      P:00033F P:00033F 441F00            MOVE              X0,X:<IDL_ADR           ;  instead of exercising clocks
1305      P:000340 P:000340 0C008F            JMP     <FINISH
1306   
1307                                ; Set the desired exposure time
1308                                SET_EXPOSURE_TIME
1309      P:000341 P:000341 46DB00            MOVE              X:(R3)+,Y0
1310      P:000342 P:000342 461000            MOVE              Y0,X:EXPOSURE_TIME
1311      P:000343 P:000343 04C68D            MOVEP             Y0,X:TCPR0
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 25



1312      P:000344 P:000344 0C008F            JMP     <FINISH
1313   
1314                                ; Read the time remaining until the exposure ends
1315                                READ_EXPOSURE_TIME
1316      P:000345 P:000345 47F000            MOVE              X:TCR0,Y1               ; Read elapsed exposure time
                            FFFF8C
1317      P:000347 P:000347 0C0090            JMP     <FINISH1
1318   
1319                                ; Pause the exposure - close the shutter and stop the timer
1320                                PAUSE_EXPOSURE
1321      P:000348 P:000348 07700C            MOVEP             X:TCR0,X:ELAPSED_TIME   ; Save the elapsed exposure time
                            000011
1322      P:00034A P:00034A 010F00            BCLR    #TIM_BIT,X:TCSR0                  ; Disable the DSP exposure timer
1323      P:00034B P:00034B 0D02FA            JSR     <CSHUT                            ; Close the shutter
1324      P:00034C P:00034C 0C008F            JMP     <FINISH
1325   
1326                                ; Resume the exposure - open the shutter if needed and restart the timer
1327                                RESUME_EXPOSURE
1328      P:00034D P:00034D 010F29            BSET    #TRM,X:TCSR0                      ; To be sure it will load TLR0
1329      P:00034E P:00034E 07700C            MOVEP             X:TCR0,X:TLR0           ; Restore elapsed exposure time
                            FFFF8E
1330      P:000350 P:000350 010F20            BSET    #TIM_BIT,X:TCSR0                  ; Re-enable the DSP exposure timer
1331      P:000351 P:000351 0A008B            JCLR    #SHUT,X:STATUS,L_RES
                            000354
1332      P:000353 P:000353 0D02F7            JSR     <OSHUT                            ; Open the shutter if necessary
1333      P:000354 P:000354 0C008F  L_RES     JMP     <FINISH
1334   
1335                                ; Abort exposure - close the shutter, stop the timer and resume idle mode
1336                                ABORT_EXPOSURE
1337      P:000355 P:000355 0D02FA            JSR     <CSHUT                            ; Close the shutter
1338      P:000356 P:000356 010F00            BCLR    #TIM_BIT,X:TCSR0                  ; Disable the DSP exposure timer
1339      P:000357 P:000357 0A0082            JCLR    #IDLMODE,X:<STATUS,NO_IDL2        ; Don't idle after readout
                            00035D
1340      P:000359 P:000359 60F400            MOVE              #IDLE,R0
                            00022D
1341      P:00035B P:00035B 601F00            MOVE              R0,X:<IDL_ADR
1342      P:00035C P:00035C 0C035F            JMP     <RDC_E2
1343      P:00035D P:00035D 305A00  NO_IDL2   MOVE              #TST_RCV,R0
1344      P:00035E P:00035E 601F00            MOVE              R0,X:<IDL_ADR
1345      P:00035F P:00035F 0D03A5  RDC_E2    JSR     <WAIT_TO_FINISH_CLOCKING
1346      P:000360 P:000360 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; Set status to not reading out
1347      P:000361 P:000361 06A08F            DO      #4000,*+3                         ; Wait 40 microsec for the fiber
                            000363
1348      P:000363 P:000363 000000            NOP                                       ;  optic to clear out
1349      P:000364 P:000364 0C008F            JMP     <FINISH
1350   
1351                                ; Generate a synthetic image by simply incrementing the pixel counts
1352                                SYNTHETIC_IMAGE
1353      P:000365 P:000365 200013            CLR     A
1354      P:000366 P:000366 060240            DO      Y:<NPR,LPR_TST                    ; Loop over each line readout
                            000371
1355      P:000368 P:000368 060140            DO      Y:<NSR,LSR_TST                    ; Loop over number of pixels per line
                            000370
1356      P:00036A P:00036A 0614A0            REP     #20                               ; #20 => 1.0 microsec per pixel
1357      P:00036B P:00036B 000000            NOP
1358      P:00036C P:00036C 014180            ADD     #1,A                              ; Pixel data = Pixel data + 1
1359      P:00036D P:00036D 000000            NOP
1360      P:00036E P:00036E 21CF00            MOVE              A,B
1361      P:00036F P:00036F 0D0373            JSR     <XMT_PIX                          ;  transmit them
1362      P:000370 P:000370 000000            NOP
1363                                LSR_TST
1364      P:000371 P:000371 000000            NOP
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 26



1365                                LPR_TST
1366      P:000372 P:000372 0C0292            JMP     <RDC_END                          ; Normal exit
1367   
1368                                ; Transmit the 16-bit pixel datum in B1 to the host computer
1369      P:000373 P:000373 0C1DA1  XMT_PIX   ASL     #16,B,B
1370      P:000374 P:000374 000000            NOP
1371      P:000375 P:000375 216500            MOVE              B2,X1
1372      P:000376 P:000376 0C1D91            ASL     #8,B,B
1373      P:000377 P:000377 000000            NOP
1374      P:000378 P:000378 216400            MOVE              B2,X0
1375      P:000379 P:000379 000000            NOP
1376      P:00037A P:00037A 09C532            MOVEP             X1,Y:WRFO
1377      P:00037B P:00037B 09C432            MOVEP             X0,Y:WRFO
1378      P:00037C P:00037C 00000C            RTS
1379   
1380                                ; Test the hardware to read A/D values directly into the DSP instead
1381                                ;   of using the SXMIT option, A/Ds #2 and 3.
1382      P:00037D P:00037D 57F000  READ_AD   MOVE              X:(RDAD+2),B
                            010002
1383      P:00037F P:00037F 0C1DA1            ASL     #16,B,B
1384      P:000380 P:000380 000000            NOP
1385      P:000381 P:000381 216500            MOVE              B2,X1
1386      P:000382 P:000382 0C1D91            ASL     #8,B,B
1387      P:000383 P:000383 000000            NOP
1388      P:000384 P:000384 216400            MOVE              B2,X0
1389      P:000385 P:000385 000000            NOP
1390      P:000386 P:000386 09C532            MOVEP             X1,Y:WRFO
1391      P:000387 P:000387 09C432            MOVEP             X0,Y:WRFO
1392      P:000388 P:000388 060AA0            REP     #10
1393      P:000389 P:000389 000000            NOP
1394      P:00038A P:00038A 57F000            MOVE              X:(RDAD+3),B
                            010003
1395      P:00038C P:00038C 0C1DA1            ASL     #16,B,B
1396      P:00038D P:00038D 000000            NOP
1397      P:00038E P:00038E 216500            MOVE              B2,X1
1398      P:00038F P:00038F 0C1D91            ASL     #8,B,B
1399      P:000390 P:000390 000000            NOP
1400      P:000391 P:000391 216400            MOVE              B2,X0
1401      P:000392 P:000392 000000            NOP
1402      P:000393 P:000393 09C532            MOVEP             X1,Y:WRFO
1403      P:000394 P:000394 09C432            MOVEP             X0,Y:WRFO
1404      P:000395 P:000395 060AA0            REP     #10
1405      P:000396 P:000396 000000            NOP
1406      P:000397 P:000397 00000C            RTS
1407   
1408                                ; Alert the PCI interface board that images are coming soon
1409                                PCI_READ_IMAGE
1410      P:000398 P:000398 57F400            MOVE              #$020104,B              ; Send header word to the FO transmitter
                            020104
1411      P:00039A P:00039A 0D00EB            JSR     <XMT_WRD
1412      P:00039B P:00039B 57F400            MOVE              #'RDA',B
                            524441
1413      P:00039D P:00039D 0D00EB            JSR     <XMT_WRD
1414      P:00039E P:00039E 5FF000            MOVE                          Y:NSR,B     ; Number of columns to read
                            000001
1415      P:0003A0 P:0003A0 0D00EB            JSR     <XMT_WRD
1416      P:0003A1 P:0003A1 5FF000            MOVE                          Y:NPR,B     ; Number of rows to read
                            000002
1417      P:0003A3 P:0003A3 0D00EB            JSR     <XMT_WRD
1418      P:0003A4 P:0003A4 00000C            RTS
1419   
1420                                ; Wait for the clocking to be complete before proceeding
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 27



1421                                WAIT_TO_FINISH_CLOCKING
1422      P:0003A5 P:0003A5 01ADA1            JSET    #SSFEF,X:PDRD,*                   ; Wait for the SS FIFO to be empty
                            0003A5
1423      P:0003A7 P:0003A7 00000C            RTS
1424   
1425                                ; This MOVEP instruction executes in 30 nanosec, 20 nanosec for the MOVEP,
1426                                ;   and 10 nanosec for the wait state that is required for SRAM writes and
1427                                ;   FIFO setup times. It looks reliable, so will be used for now.
1428   
1429                                ; Core subroutine for clocking out CCD charge
1430      P:0003A8 P:0003A8 0A898E  CLOCK     JCLR    #SSFHF,X:HDR,*                    ; Only write to FIFO if < half full
                            0003A8
1431      P:0003AA P:0003AA 000000            NOP
1432      P:0003AB P:0003AB 0A898E            JCLR    #SSFHF,X:HDR,CLOCK                ; Guard against metastability
                            0003A8
1433      P:0003AD P:0003AD 4CD800            MOVE                          Y:(R0)+,X0  ; # of waveform entries
1434      P:0003AE P:0003AE 06C400            DO      X0,CLK1                           ; Repeat X0 times
                            0003B0
1435      P:0003B0 P:0003B0 09D8F3            MOVEP             Y:(R0)+,Y:WRSS          ; 30 nsec Write the waveform to the SS
1436                                CLK1
1437      P:0003B1 P:0003B1 000000            NOP
1438      P:0003B2 P:0003B2 00000C            RTS                                       ; Return from subroutine
1439   
1440                                ; Delay for serial writes to the PALs and DACs by 8 microsec
1441      P:0003B3 P:0003B3 062083  PAL_DLY   DO      #800,*+3                          ; Wait 8 usec for serial data xmit
                            0003B5
1442      P:0003B5 P:0003B5 000000            NOP
1443      P:0003B6 P:0003B6 00000C            RTS
1444   
1445                                ; Test the analog serial word transmitter
1446                                TEST_XMIT
1447      P:0003B7 P:0003B7 56DB00            MOVE              X:(R3)+,A
1448      P:0003B8 P:0003B8 0D020C            JSR     <XMIT_A_WORD
1449      P:0003B9 P:0003B9 0C008F            JMP     <FINISH
1450   
1451                                ; Let the host computer read the controller configuration
1452                                READ_CONTROLLER_CONFIGURATION
1453      P:0003BA P:0003BA 4F8900            MOVE                          Y:<CONFIG,Y1 ; Just transmit the configuration
1454      P:0003BB P:0003BB 0C0090            JMP     <FINISH1
1455   
1456                                ; Set the video processor gain and integrator speed for all video boards
1457                                ;  Command syntax is  SGN  #GAIN  #SPEED, #GAIN = 1, 2, 5 or 10
1458                                ;                                         #SPEED = 0 for slow, 1 for fast
1459      P:0003BC P:0003BC 012F23  ST_GAIN   BSET    #3,X:PCRD                         ; Turn on the serial clock
1460      P:0003BD P:0003BD 56DB00            MOVE              X:(R3)+,A               ; Gain value (1,2,5 or 10)
1461      P:0003BE P:0003BE 44F400            MOVE              #>1,X0
                            000001
1462      P:0003C0 P:0003C0 200045            CMP     X0,A                              ; Check for gain = x1
1463      P:0003C1 P:0003C1 0E23C5            JNE     <STG2
1464      P:0003C2 P:0003C2 57F400            MOVE              #>$77,B
                            000077
1465      P:0003C4 P:0003C4 0C03D9            JMP     <STG_A
1466      P:0003C5 P:0003C5 44F400  STG2      MOVE              #>2,X0                  ; Check for gain = x2
                            000002
1467      P:0003C7 P:0003C7 200045            CMP     X0,A
1468      P:0003C8 P:0003C8 0E23CC            JNE     <STG5
1469      P:0003C9 P:0003C9 57F400            MOVE              #>$BB,B
                            0000BB
1470      P:0003CB P:0003CB 0C03D9            JMP     <STG_A
1471      P:0003CC P:0003CC 44F400  STG5      MOVE              #>5,X0                  ; Check for gain = x5
                            000005
1472      P:0003CE P:0003CE 200045            CMP     X0,A
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 28



1473      P:0003CF P:0003CF 0E23D3            JNE     <STG10
1474      P:0003D0 P:0003D0 57F400            MOVE              #>$DD,B
                            0000DD
1475      P:0003D2 P:0003D2 0C03D9            JMP     <STG_A
1476      P:0003D3 P:0003D3 44F400  STG10     MOVE              #>10,X0                 ; Check for gain = x10
                            00000A
1477      P:0003D5 P:0003D5 200045            CMP     X0,A
1478      P:0003D6 P:0003D6 0E208D            JNE     <ERROR
1479      P:0003D7 P:0003D7 57F400            MOVE              #>$EE,B
                            0000EE
1480   
1481      P:0003D9 P:0003D9 56DB00  STG_A     MOVE              X:(R3)+,A               ; Integrator Speed (0 for slow, 1 for fast)
1482      P:0003DA P:0003DA 000000            NOP
1483      P:0003DB P:0003DB 0ACC00            JCLR    #0,A1,STG_B
                            0003E0
1484      P:0003DD P:0003DD 0ACD68            BSET    #8,B1
1485      P:0003DE P:0003DE 000000            NOP
1486      P:0003DF P:0003DF 0ACD69            BSET    #9,B1
1487      P:0003E0 P:0003E0 44F400  STG_B     MOVE              #$0C3C00,X0
                            0C3C00
1488      P:0003E2 P:0003E2 20004A            OR      X0,B
1489      P:0003E3 P:0003E3 000000            NOP
1490      P:0003E4 P:0003E4 5F1E00            MOVE                          B,Y:<GAINRA ; Store the GAIN value for later use
1491                                                                                    ; 4/21/2011  this should/might send the gain
 to the vid board r.a.
1492                                                                                    ; from the sdc commmand... make sure we are 
not in diagnostic mode.
1493      P:0003E5 P:0003E5 0A1E4A            BCLR    #10,Y:<GAINRA                     ;make sure we are not in diagnostic mode r.a
.
1494      P:0003E6 P:0003E6 0A1E4B            BCLR    #11,Y:<GAINRA                     ;make sure we are not in diagnostic mode r.a
.
1495      P:0003E7 P:0003E7 5D9E00            MOVE                          Y:<GAINRA,B1
1496                                ; Send this same value to 15 video processor boards whether they exist or not
1497      P:0003E8 P:0003E8 241000  SDC_A     MOVE              #$100000,X0             ; Increment value
1498      P:0003E9 P:0003E9 060F80            DO      #15,STG_LOOP
                            0003EF
1499      P:0003EB P:0003EB 21EE00            MOVE              B,A                     ; have to get things in A1 to be sent by xmi
t_a_word  r.a.
1500      P:0003EC P:0003EC 0D020C            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1501      P:0003ED P:0003ED 0D03B3            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
1502      P:0003EE P:0003EE 200048            ADD     X0,B                              ; Increment the video processor board number
1503      P:0003EF P:0003EF 000000            NOP
1504                                STG_LOOP
1505      P:0003F0 P:0003F0 000000            NOP
1506      P:0003F1 P:0003F1 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1507      P:0003F2 P:0003F2 0C008F            JMP     <FINISH
1508      P:0003F3 P:0003F3 56DB00  ERR_SGN   MOVE              X:(R3)+,A
1509      P:0003F4 P:0003F4 0C008D            JMP     <ERROR
1510   
1511   
1512                                ; Set a particular DAC numbers, for setting DC bias voltages, clock driver
1513                                ;   voltages and video processor offset
1514                                ; This is code for the ARC32 clock driver and ARC45 CCD video processor
1515                                ;
1516                                ; SBN  #BOARD  #DAC  ['CLK' or 'VID'] voltage
1517                                ;
1518                                ;                               #BOARD is from 0 to 15
1519                                ;                               #DAC number
1520                                ;                               #voltage is from 0 to 4095
1521   
1522                                SET_BIAS_NUMBER                                     ; Set bias number
1523      P:0003F5 P:0003F5 012F23            BSET    #3,X:PCRD                         ; Turn on the serial clock
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 29



1524      P:0003F6 P:0003F6 56DB00            MOVE              X:(R3)+,A               ; First argument is board number, 0 to 15
1525      P:0003F7 P:0003F7 0614A0            REP     #20
1526      P:0003F8 P:0003F8 200033            LSL     A
1527      P:0003F9 P:0003F9 000000            NOP
1528      P:0003FA P:0003FA 21C500            MOVE              A,X1                    ; Save the board number
1529      P:0003FB P:0003FB 56DB00            MOVE              X:(R3)+,A               ; Second argument is DAC number
1530      P:0003FC P:0003FC 000000            NOP
1531      P:0003FD P:0003FD 5C0000            MOVE                          A1,Y:0      ; Save the DAC number for a little while
1532      P:0003FE P:0003FE 57E300            MOVE              X:(R3),B                ; Third argument is 'VID' or 'CLK' string
1533      P:0003FF P:0003FF 0140CD            CMP     #'VID',B
                            564944
1534      P:000401 P:000401 0E2409            JNE     <CLK_DRV
1535      P:000402 P:000402 060EA0            REP     #14
1536      P:000403 P:000403 200033            LSL     A
1537      P:000404 P:000404 000000            NOP
1538      P:000405 P:000405 0ACC73            BSET    #19,A1                            ; Set bits to mean video processor DAC
1539      P:000406 P:000406 000000            NOP
1540      P:000407 P:000407 0ACC72            BSET    #18,A1
1541      P:000408 P:000408 0C0433            JMP     <BD_SET
1542      P:000409 P:000409 0140CD  CLK_DRV   CMP     #'CLK',B
                            434C4B
1543      P:00040B P:00040B 0E2448            JNE     <ERR_SBN
1544   
1545                                ; For ARC32 do some trickiness to set the chip select and address bits
1546      P:00040C P:00040C 218F00            MOVE              A1,B
1547      P:00040D P:00040D 060EA0            REP     #14
1548      P:00040E P:00040E 200033            LSL     A
1549      P:00040F P:00040F 240E00            MOVE              #$0E0000,X0
1550      P:000410 P:000410 200046            AND     X0,A
1551      P:000411 P:000411 44F400            MOVE              #>7,X0
                            000007
1552      P:000413 P:000413 20004E            AND     X0,B                              ; Get 3 least significant bits of clock #
1553      P:000414 P:000414 01408D            CMP     #0,B
1554      P:000415 P:000415 0E2418            JNE     <CLK_1
1555      P:000416 P:000416 0ACE68            BSET    #8,A
1556      P:000417 P:000417 0C0433            JMP     <BD_SET
1557      P:000418 P:000418 01418D  CLK_1     CMP     #1,B
1558      P:000419 P:000419 0E241C            JNE     <CLK_2
1559      P:00041A P:00041A 0ACE69            BSET    #9,A
1560      P:00041B P:00041B 0C0433            JMP     <BD_SET
1561      P:00041C P:00041C 01428D  CLK_2     CMP     #2,B
1562      P:00041D P:00041D 0E2420            JNE     <CLK_3
1563      P:00041E P:00041E 0ACE6A            BSET    #10,A
1564      P:00041F P:00041F 0C0433            JMP     <BD_SET
1565      P:000420 P:000420 01438D  CLK_3     CMP     #3,B
1566      P:000421 P:000421 0E2424            JNE     <CLK_4
1567      P:000422 P:000422 0ACE6B            BSET    #11,A
1568      P:000423 P:000423 0C0433            JMP     <BD_SET
1569      P:000424 P:000424 01448D  CLK_4     CMP     #4,B
1570      P:000425 P:000425 0E2428            JNE     <CLK_5
1571      P:000426 P:000426 0ACE6D            BSET    #13,A
1572      P:000427 P:000427 0C0433            JMP     <BD_SET
1573      P:000428 P:000428 01458D  CLK_5     CMP     #5,B
1574      P:000429 P:000429 0E242C            JNE     <CLK_6
1575      P:00042A P:00042A 0ACE6E            BSET    #14,A
1576      P:00042B P:00042B 0C0433            JMP     <BD_SET
1577      P:00042C P:00042C 01468D  CLK_6     CMP     #6,B
1578      P:00042D P:00042D 0E2430            JNE     <CLK_7
1579      P:00042E P:00042E 0ACE6F            BSET    #15,A
1580      P:00042F P:00042F 0C0433            JMP     <BD_SET
1581      P:000430 P:000430 01478D  CLK_7     CMP     #7,B
1582      P:000431 P:000431 0E2433            JNE     <BD_SET
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 30



1583      P:000432 P:000432 0ACE70            BSET    #16,A
1584   
1585      P:000433 P:000433 200062  BD_SET    OR      X1,A                              ; Add on the board number
1586      P:000434 P:000434 000000            NOP
1587      P:000435 P:000435 21C400            MOVE              A,X0
1588      P:000436 P:000436 57DB00            MOVE              X:(R3)+,B               ; Third argument (again) is 'VID' or 'CLK' s
tring
1589      P:000437 P:000437 0140CD            CMP     #'VID',B
                            564944
1590      P:000439 P:000439 0EA442            JEQ     <VID
1591      P:00043A P:00043A 56DB00            MOVE              X:(R3)+,A               ; Fourth argument is voltage value, 0 to $ff
f
1592      P:00043B P:00043B 0604A0            REP     #4
1593      P:00043C P:00043C 200023            LSR     A                                 ; Convert 12 bits to 8 bits for ARC32
1594      P:00043D P:00043D 46F400            MOVE              #>$FF,Y0                ; Mask off just 8 bits
                            0000FF
1595      P:00043F P:00043F 200056            AND     Y0,A
1596      P:000440 P:000440 200042            OR      X0,A
1597      P:000441 P:000441 0C0444            JMP     <XMT_SBN
1598      P:000442 P:000442 56DB00  VID       MOVE              X:(R3)+,A               ; Fourth argument is voltage value for ARC45
, 12 bits
1599      P:000443 P:000443 200042            OR      X0,A
1600   
1601      P:000444 P:000444 0D020C  XMT_SBN   JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1602      P:000445 P:000445 0D03B3            JSR     <PAL_DLY                          ; Wait for the number to be sent
1603      P:000446 P:000446 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1604      P:000447 P:000447 0C008F            JMP     <FINISH
1605      P:000448 P:000448 56DB00  ERR_SBN   MOVE              X:(R3)+,A               ; Read and discard the fourth argument
1606      P:000449 P:000449 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1607      P:00044A P:00044A 0C008D            JMP     <ERROR
1608   
1609                                ; Specify the MUX value to be output on the clock driver board
1610                                ; Command syntax is  SMX  #clock_driver_board #MUX1 #MUX2
1611                                ;                               #clock_driver_board from 0 to 15
1612                                ;                               #MUX1, #MUX2 from 0 to 23
1613   
1614      P:00044B P:00044B 012F23  SET_MUX   BSET    #3,X:PCRD                         ; Turn on the serial clock
1615      P:00044C P:00044C 56DB00            MOVE              X:(R3)+,A               ; Clock driver board number
1616      P:00044D P:00044D 0614A0            REP     #20
1617      P:00044E P:00044E 200033            LSL     A
1618                                ;!!!    MOVE    #$003000,X0   ; original code. does not work with newest timing board
1619      P:00044F P:00044F 44F400            MOVE              #$001000,X0             ;leach patch for the newest 4/20/2011 timing
 board r.a.
                            001000
1620      P:000451 P:000451 200042            OR      X0,A
1621      P:000452 P:000452 000000            NOP
1622      P:000453 P:000453 21C500            MOVE              A,X1                    ; Move here for storage
1623   
1624                                ; Get the first MUX number
1625      P:000454 P:000454 56DB00            MOVE              X:(R3)+,A               ; Get the first MUX number
1626      P:000455 P:000455 0AF0A9            JLT     ERR_SM1
                            000499
1627      P:000457 P:000457 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                            000018
1628      P:000459 P:000459 200045            CMP     X0,A
1629      P:00045A P:00045A 0AF0A1            JGE     ERR_SM1
                            000499
1630      P:00045C P:00045C 21CF00            MOVE              A,B
1631      P:00045D P:00045D 44F400            MOVE              #>7,X0
                            000007
1632      P:00045F P:00045F 20004E            AND     X0,B
1633      P:000460 P:000460 44F400            MOVE              #>$18,X0
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 31



                            000018
1634      P:000462 P:000462 200046            AND     X0,A
1635      P:000463 P:000463 0E2466            JNE     <SMX_1                            ; Test for 0 <= MUX number <= 7
1636      P:000464 P:000464 0ACD63            BSET    #3,B1
1637      P:000465 P:000465 0C0471            JMP     <SMX_A
1638      P:000466 P:000466 44F400  SMX_1     MOVE              #>$08,X0
                            000008
1639      P:000468 P:000468 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
1640      P:000469 P:000469 0E246C            JNE     <SMX_2
1641      P:00046A P:00046A 0ACD64            BSET    #4,B1
1642      P:00046B P:00046B 0C0471            JMP     <SMX_A
1643      P:00046C P:00046C 44F400  SMX_2     MOVE              #>$10,X0
                            000010
1644      P:00046E P:00046E 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
1645      P:00046F P:00046F 0E2499            JNE     <ERR_SM1
1646      P:000470 P:000470 0ACD65            BSET    #5,B1
1647      P:000471 P:000471 20006A  SMX_A     OR      X1,B1                             ; Add prefix to MUX numbers
1648      P:000472 P:000472 000000            NOP
1649      P:000473 P:000473 21A700            MOVE              B1,Y1
1650   
1651                                ; Add on the second MUX number
1652      P:000474 P:000474 56DB00            MOVE              X:(R3)+,A               ; Get the next MUX number
1653      P:000475 P:000475 0E908D            JLT     <ERROR
1654      P:000476 P:000476 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                            000018
1655      P:000478 P:000478 200045            CMP     X0,A
1656      P:000479 P:000479 0E108D            JGE     <ERROR
1657      P:00047A P:00047A 0606A0            REP     #6
1658      P:00047B P:00047B 200033            LSL     A
1659      P:00047C P:00047C 000000            NOP
1660      P:00047D P:00047D 21CF00            MOVE              A,B
1661      P:00047E P:00047E 44F400            MOVE              #$1C0,X0
                            0001C0
1662      P:000480 P:000480 20004E            AND     X0,B
1663      P:000481 P:000481 44F400            MOVE              #>$600,X0
                            000600
1664      P:000483 P:000483 200046            AND     X0,A
1665      P:000484 P:000484 0E2487            JNE     <SMX_3                            ; Test for 0 <= MUX number <= 7
1666      P:000485 P:000485 0ACD69            BSET    #9,B1
1667      P:000486 P:000486 0C0492            JMP     <SMX_B
1668      P:000487 P:000487 44F400  SMX_3     MOVE              #>$200,X0
                            000200
1669      P:000489 P:000489 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
1670      P:00048A P:00048A 0E248D            JNE     <SMX_4
1671      P:00048B P:00048B 0ACD6A            BSET    #10,B1
1672      P:00048C P:00048C 0C0492            JMP     <SMX_B
1673      P:00048D P:00048D 44F400  SMX_4     MOVE              #>$400,X0
                            000400
1674      P:00048F P:00048F 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
1675      P:000490 P:000490 0E208D            JNE     <ERROR
1676      P:000491 P:000491 0ACD6B            BSET    #11,B1
1677      P:000492 P:000492 200078  SMX_B     ADD     Y1,B                              ; Add prefix to MUX numbers
1678      P:000493 P:000493 000000            NOP
1679      P:000494 P:000494 21AE00            MOVE              B1,A
1680      P:000495 P:000495 0D020C            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1681      P:000496 P:000496 0D03B3            JSR     <PAL_DLY                          ; Delay for all this to happen
1682      P:000497 P:000497 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1683      P:000498 P:000498 0C008F            JMP     <FINISH
1684      P:000499 P:000499 56DB00  ERR_SM1   MOVE              X:(R3)+,A
1685      P:00049A P:00049A 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1686      P:00049B P:00049B 0C008D            JMP     <ERROR
1687   
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 32



1688                                HOLD_CLK                                            ;no clocking during exposure (MASTER=UTIL)
1689      P:00049C P:00049C 245A00            MOVE              #TST_RCV,X0             ; Wait for commands during exposure
1690      P:00049D P:00049D 441F00            MOVE              X0,X:<IDL_ADR           ;  instead of exercising clocks
1691      P:00049E P:00049E 0C008F            JMP     <FINISH
1692   
1693   
1694                                ; Select which readouts to process
1695                                ;   'SOS'  Amplifier_name
1696                                ;       Amplifier_name = '__L', '__R', '_LR'
1697   
1698      P:00049F P:00049F 44DB00  SEL_OS    MOVE              X:(R3)+,X0              ; Get amplifier(s) name
1699      P:0004A0 P:0004A0 4C0B00            MOVE                          X0,Y:<OS
1700      P:0004A1 P:0004A1 0D04A3            JSR     <SELECT_OUTPUT_SOURCE
1701      P:0004A2 P:0004A2 0C0090            JMP     <FINISH1
1702   
1703                                ; A massive subroutine for setting all the addresses depending on the
1704                                ;   output source(s) selection and binning parameter.
1705                                SELECT_OUTPUT_SOURCE
1706   
1707                                ; Set all the waveform addresses depending on which readout mode
1708      P:0004A3 P:0004A3 56F400            MOVE              #'__L',A                ; LEFT Amplifier = readout #0
                            5F5F4C
1709      P:0004A5 P:0004A5 200045            CMP     X0,A
1710      P:0004A6 P:0004A6 0E24B5            JNE     <CMP_R
1711      P:0004A7 P:0004A7 0A0006            BCLR    #SPLIT_P,X:STATUS
1712      P:0004A8 P:0004A8 44F400            MOVE              #SERIAL_SKIP_L,X0
                            00009E
1713      P:0004AA P:0004AA 4C7000            MOVE                          X0,Y:SERIAL_SKIP
                            00000E
1714      P:0004AC P:0004AC 44F400            MOVE              #SERIAL_READ_L,X0
                            000068
1715      P:0004AE P:0004AE 4C0F00            MOVE                          X0,Y:<SERIAL_READ
1716      P:0004AF P:0004AF 44F400            MOVE              #$00F041,X0             ; Transmit channel 0   6/16/2011 was 00f000 
no work __L new cable
                            00F041
1717      P:0004B1 P:0004B1 4C7000  CMP_RR    MOVE                          X0,Y:SXL
                            000071
1718      P:0004B3 P:0004B3 0A0005            BCLR    #SPLIT_S,X:STATUS
1719      P:0004B4 P:0004B4 0C04D8            JMP     <CMP_END
1720   
1721      P:0004B5 P:0004B5 56F400  CMP_R     MOVE              #'__R',A                ; RIGHT Amplifier = readout #1
                            5F5F52
1722      P:0004B7 P:0004B7 200045            CMP     X0,A
1723      P:0004B8 P:0004B8 0E24C7            JNE     <CMP_LR
1724      P:0004B9 P:0004B9 0A0006            BCLR    #SPLIT_P,X:STATUS
1725      P:0004BA P:0004BA 44F400            MOVE              #SERIAL_SKIP_R,X0
                            0000A7
1726      P:0004BC P:0004BC 4C7000            MOVE                          X0,Y:SERIAL_SKIP
                            00000E
1727      P:0004BE P:0004BE 44F400            MOVE              #SERIAL_READ_R,X0
                            00007A
1728      P:0004C0 P:0004C0 4C0F00            MOVE                          X0,Y:<SERIAL_READ
1729      P:0004C1 P:0004C1 44F400            MOVE              #$00F000,X0             ; Transmit channel 1  6/16/2011 fix was f041
 no work __R new cable
                            00F000
1730      P:0004C3 P:0004C3 4C7000  CMP_LL    MOVE                          X0,Y:SXR
                            000083
1731      P:0004C5 P:0004C5 0A0005            BCLR    #SPLIT_S,X:STATUS
1732      P:0004C6 P:0004C6 0C04D8            JMP     <CMP_END
1733   
1734      P:0004C7 P:0004C7 56F400  CMP_LR    MOVE              #'_LR',A                ; LEFT and RIGHT = readouts #0 and #1
                            5F4C52
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 33



1735      P:0004C9 P:0004C9 200045            CMP     X0,A
1736      P:0004CA P:0004CA 0E24DD            JNE     <CMP_12
1737      P:0004CB P:0004CB 0A0006            BCLR    #SPLIT_P,X:STATUS
1738      P:0004CC P:0004CC 44F400            MOVE              #SERIAL_SKIP_LR,X0      ;added/changed 6/16/2011 r.a.
                            0000B0
1739      P:0004CE P:0004CE 4C7000            MOVE                          X0,Y:SERIAL_SKIP ; "      "     "  "  "   " "
                            00000E
1740      P:0004D0 P:0004D0 44F400            MOVE              #SERIAL_READ_LR,X0
                            00008C
1741      P:0004D2 P:0004D2 4C0F00            MOVE                          X0,Y:<SERIAL_READ
1742      P:0004D3 P:0004D3 44F400            MOVE              #$00F040,X0             ; Transmit channel 0&1
                            00F040
1743      P:0004D5 P:0004D5 4C7000  CMP_AR    MOVE                          X0,Y:SXRL
                            000095
1744      P:0004D7 P:0004D7 0A0025            BSET    #SPLIT_S,X:STATUS
1745      P:0004D8 P:0004D8 4C7000  CMP_END   MOVE                          X0,Y:SXMIT
                            000064
1746      P:0004DA P:0004DA 47F400            MOVE              #'DON',Y1
                            444F4E
1747      P:0004DC P:0004DC 00000C            RTS
1748   
1749      P:0004DD P:0004DD 56F400  CMP_12    MOVE              #'_12',A
                            5F3132
1750      P:0004DF P:0004DF 200045            CMP     X0,A
1751      P:0004E0 P:0004E0 0E24E5            JNE     <CMP_21
1752      P:0004E1 P:0004E1 0A0026            BSET    #SPLIT_P,X:STATUS
1753      P:0004E2 P:0004E2 44F400            MOVE              #$00F081,X0             ; Transmit channel 2&1
                            00F081
1754      P:0004E4 P:0004E4 0C04C3            JMP     <CMP_LL
1755   
1756      P:0004E5 P:0004E5 56F400  CMP_21    MOVE              #'_21',A
                            5F3231
1757      P:0004E7 P:0004E7 200045            CMP     X0,A
1758      P:0004E8 P:0004E8 0E24ED            JNE     <CMP_2L
1759      P:0004E9 P:0004E9 0A0026            BSET    #SPLIT_P,X:STATUS
1760      P:0004EA P:0004EA 44F400            MOVE              #$00F081,X0             ; Transmit channel 2&1
                            00F081
1761      P:0004EC P:0004EC 0C04B1            JMP     <CMP_RR
1762   
1763      P:0004ED P:0004ED 56F400  CMP_2L    MOVE              #'_2L',A
                            5F324C
1764      P:0004EF P:0004EF 200045            CMP     X0,A
1765      P:0004F0 P:0004F0 0E24F5            JNE     <CMP_2U
1766      P:0004F1 P:0004F1 0A0006            BCLR    #SPLIT_P,X:STATUS
1767      P:0004F2 P:0004F2 44F400            MOVE              #$00F082,X0             ; Transmit channel 2
                            00F082
1768      P:0004F4 P:0004F4 0C04C3            JMP     <CMP_LL
1769   
1770      P:0004F5 P:0004F5 56F400  CMP_2U    MOVE              #'_2R',A
                            5F3252
1771      P:0004F7 P:0004F7 200045            CMP     X0,A
1772      P:0004F8 P:0004F8 0E24FD            JNE     <CMP_RL
1773      P:0004F9 P:0004F9 0A0006            BCLR    #SPLIT_P,X:STATUS
1774      P:0004FA P:0004FA 44F400            MOVE              #$00F0C3,X0             ; Transmit channel 3
                            00F0C3
1775      P:0004FC P:0004FC 0C04B1            JMP     <CMP_RR
1776   
1777      P:0004FD P:0004FD 56F400  CMP_RL    MOVE              #'_RL',A
                            5F524C
1778      P:0004FF P:0004FF 200045            CMP     X0,A
1779      P:000500 P:000500 0E2505            JNE     <CMP_ALL
1780      P:000501 P:000501 0A0006            BCLR    #SPLIT_P,X:STATUS
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 34



1781      P:000502 P:000502 44F400            MOVE              #$00F0C2,X0             ; Transmit channel 2&3
                            00F0C2
1782      P:000504 P:000504 0C04D5            JMP     <CMP_AR
1783   
1784      P:000505 P:000505 56F400  CMP_ALL   MOVE              #'ALL',A
                            414C4C
1785      P:000507 P:000507 200045            CMP     X0,A
1786      P:000508 P:000508 0E250D            JNE     <CMP_ERROR
1787      P:000509 P:000509 0A0026            BSET    #SPLIT_P,X:STATUS
1788      P:00050A P:00050A 44F400            MOVE              #$00F0C0,X0             ; Transmit channel 0&1&2&3
                            00F0C0
1789      P:00050C P:00050C 0C04D5            JMP     <CMP_AR
1790   
1791                                CMP_ERROR
1792      P:00050D P:00050D 44F400            MOVE              #'ERR',X0
                            455252
1793      P:00050F P:00050F 00000C            RTS
1794   
1795                                ERASE                                               ; Persistence erase
1796      P:000510 P:000510 44DB00            MOVE              X:(R3)+,X0
1797      P:000511 P:000511 4C1700            MOVE                          X0,Y:<TIME1 ;var1 = erase time
1798      P:000512 P:000512 44DB00            MOVE              X:(R3)+,X0
1799      P:000513 P:000513 4C1800            MOVE                          X0,Y:<TIME2 ;var3 = delay time
1800   
1801      P:000514 P:000514 60F400            MOVE              #ERHI,R0                ; Get starting address of DAC values
                            0000BD
1802      P:000516 P:000516 0D02C9            JSR     <WR_DACS                          ; Set clocks to 'high',vsub low
1803      P:000517 P:000517 061740            DO      Y:<TIME1,ER_T1
                            00051A
1804      P:000519 P:000519 0D052E            JSR     <LNG_DLY                          ; Delay in units of 1 msec
1805      P:00051A P:00051A 000000            NOP
1806      P:00051B P:00051B 5EF000  ER_T1     MOVE                          Y:VSUBN,A
                            0000BD
1807      P:00051D P:00051D 0D020C            JSR     <XMIT_A_WORD                      ; Set vsub normal
1808      P:00051E P:00051E 0D03B3            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
1809      P:00051F P:00051F 061840            DO      Y:<TIME2,ER_T2
                            000522
1810      P:000521 P:000521 0D052E            JSR     <LNG_DLY                          ; Delay in units of 1 msec
1811      P:000522 P:000522 000000            NOP
1812      P:000523 P:000523 60F400  ER_T2     MOVE              #EREND,R0               ; Get starting address of DAC values
                            0000BE
1813      P:000525 P:000525 0D02C9            JSR     <WR_DACS                          ; Set clocks to 'normal'
1814   
1815      P:000526 P:000526 0C008F            JMP     <FINISH
1816   
1817                                ;***********************   EL Shutter   *************************
1818      P:000527 P:000527 0D02F7  EL_SH     JSR     <OSHUT                            ; open Timing board shutter
1819      P:000528 P:000528 061940            DO      Y:<CL_H,LPEL
                            00052B
1820      P:00052A P:00052A 0D052E            JSR     <LNG_DLY                          ; Delay in units of 1 msec
1821      P:00052B P:00052B 000000            NOP
1822      P:00052C P:00052C 0D02FA  LPEL      JSR     <CSHUT                            ; close Timing board shutter
1823      P:00052D P:00052D 0C008F            JMP     <FINISH
1824   
1825                                ;***********************   Delay 1 msec
1826      P:00052E P:00052E 06D28F  LNG_DLY   DO      #4050,LNGDLY
                            000530
1827      P:000530 P:000530 000000            NOP
1828                                LNGDLY
1829      P:000531 P:000531 00000C            RTS
1830   
1831                                ;********** SET POCKET PUMPING PARAMETERS ************************
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 35



1832   
1833      P:000532 P:000532 44DB00  SET_PK_PAR MOVE             X:(R3)+,X0
1834      P:000533 P:000533 4C1B00            MOVE                          X0,Y:<PK_SHF
1835      P:000534 P:000534 44DB00            MOVE              X:(R3)+,X0
1836      P:000535 P:000535 4C1C00            MOVE                          X0,Y:<PK_CY
1837      P:000536 P:000536 44DB00            MOVE              X:(R3)+,X0
1838      P:000537 P:000537 4C1900            MOVE                          X0,Y:<CL_H
1839      P:000538 P:000538 44DB00            MOVE              X:(R3)+,X0
1840      P:000539 P:000539 4C1D00            MOVE                          X0,Y:<EPER
1841      P:00053A P:00053A 0C008F            JMP     <FINISH
1842   
1843                                ;  ***********************   POCKET PUMPING  **********************
1844   
1845      P:00053B P:00053B 5E9D00  POCKET    MOVE                          Y:<EPER,A
1846      P:00053C P:00053C 44F400            MOVE              #>0,X0
                            000000
1847      P:00053E P:00053E 200045            CMP     X0,A                              ; Check for EPER>0
1848      P:00053F P:00053F 0AF0A2            JNE     EP_SPL
                            000552
1849      P:000541 P:000541 061A40            DO      Y:<PK_MULT,FINE1                  ;Multiplicator for number of pumping cycles
                            000550
1850      P:000543 P:000543 061C40            DO      Y:<PK_CY,FINE2                    ;Loop over number of pumping cycles
                            00054F
1851      P:000545 P:000545 061B40            DO      Y:<PK_SHF,FINE21                  ;loop over pixels to shift forward
                            000549
1852      P:000547 P:000547 302F00            MOVE              #<P_PARAL,R0
1853      P:000548 P:000548 0D03A8            JSR     <CLOCK
1854      P:000549 P:000549 000000            NOP
1855      P:00054A P:00054A 061B40  FINE21    DO      Y:<PK_SHF,FINE23                  ;loop over pixels to shift reverse
                            00054E
1856      P:00054C P:00054C 303600            MOVE              #<P_PARAL_INV,R0
1857      P:00054D P:00054D 0D03A8            JSR     <CLOCK
1858      P:00054E P:00054E 000000            NOP
1859      P:00054F P:00054F 000000  FINE23    NOP
1860      P:000550 P:000550 000000  FINE2     NOP
1861      P:000551 P:000551 0C008F  FINE1     JMP     <FINISH
1862   
1863      P:000552 P:000552 061D40  EP_SPL    DO      Y:<EPER,EP_LP
                            000556
1864      P:000554 P:000554 303D00            MOVE              #<P_EPER,R0
1865      P:000555 P:000555 0D03A8            JSR     <CLOCK
1866      P:000556 P:000556 000000            NOP
1867      P:000557 P:000557 000000  EP_LP     NOP
1868      P:000558 P:000558 0C008F            JMP     <FINISH
1869   
1870                                                                                    ; Specify subarray readout coordinates, one 
rectangle only
1871                                SET_SUBARRAY_SIZES
1872      P:000559 P:000559 0A0010            BCLR    #ST_SA,X:<STATUS                  ; Subarray not yet activated
1873      P:00055A P:00055A 44DB00            MOVE              X:(R3)+,X0
1874      P:00055B P:00055B 4C1400            MOVE                          X0,Y:<NRBIAS ; Number of bias pixels to read
1875      P:00055C P:00055C 44DB00            MOVE              X:(R3)+,X0
1876      P:00055D P:00055D 4C1500            MOVE                          X0,Y:<NSREAD ; Number of columns in subimage read
1877      P:00055E P:00055E 44DB00            MOVE              X:(R3)+,X0
1878      P:00055F P:00055F 4C1600            MOVE                          X0,Y:<NPREAD ; Number of rows in subimage read
1879      P:000560 P:000560 0C008F            JMP     <FINISH
1880   
1881                                ; Call this routine to activate subarray and specify positions of the subarray
1882                                SET_SUBARRAY_POSITIONS
1883      P:000561 P:000561 0A0030            BSET    #ST_SA,X:<STATUS                  ; Subarray readout activated by this call
1884      P:000562 P:000562 44DB00            MOVE              X:(R3)+,X0
1885      P:000563 P:000563 4C1100            MOVE                          X0,Y:<NP_SKIP ; Number of rows (parallels) to clear
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  timCCD1_8.asm  Page 36



1886      P:000564 P:000564 44DB00            MOVE              X:(R3)+,X0
1887      P:000565 P:000565 4C1200            MOVE                          X0,Y:<NS_SKP1 ; Number of columns (serials) clears befor
e
1888      P:000566 P:000566 44DB00            MOVE              X:(R3)+,X0              ;  the subarray readout
1889      P:000567 P:000567 4C1300            MOVE                          X0,Y:<NS_SKP2 ; Number of columns (serials) clears after
1890      P:000568 P:000568 0C008F            JMP     <FINISH                           ;  the subarray readout
1891   
1892   
1893   
1894                                 TIMBOOT_X_MEMORY
1895      000569                              EQU     @LCV(L)
1896   
1897                                ;  ****************  Setup memory tables in X: space ********************
1898   
1899                                ; Define the address in P: space where the table of constants begins
1900   
1901                                          IF      @SCP("HOST","HOST")
1902      X:000036 X:000036                   ORG     X:END_COMMAND_TABLE,X:END_COMMAND_TABLE
1903                                          ENDIF
1904   
1905                                          IF      @SCP("HOST","ROM")
1907                                          ENDIF
1908   
1909                                ; Application commands
1910      X:000036 X:000036                   DC      'PON',POWER_ON
1911      X:000038 X:000038                   DC      'POF',POWER_OFF
1912      X:00003A X:00003A                   DC      'SBV',SET_BIAS_VOLTAGES
1913      X:00003C X:00003C                   DC      'IDL',IDL
1914      X:00003E X:00003E                   DC      'OSH',OPEN_SHUTTER
1915      X:000040 X:000040                   DC      'CSH',CLOSE_SHUTTER
1916      X:000042 X:000042                   DC      'RDC',RDCCD                       ; Begin CCD readout
1917      X:000044 X:000044                   DC      'CLR',CLEAR                       ; Fast clear the CCD
1918   
1919                                ; Exposure and readout control routines
1920      X:000046 X:000046                   DC      'SET',SET_EXPOSURE_TIME
1921      X:000048 X:000048                   DC      'RET',READ_EXPOSURE_TIME
1922      X:00004A X:00004A                   DC      'SEX',START_EXPOSURE
1923      X:00004C X:00004C                   DC      'PEX',PAUSE_EXPOSURE
1924      X:00004E X:00004E                   DC      'REX',RESUME_EXPOSURE
1925      X:000050 X:000050                   DC      'AEX',ABORT_EXPOSURE
1926      X:000052 X:000052                   DC      'ABR',ABR_RDC
1927      X:000054 X:000054                   DC      'CRD',CONTINUE_READ
1928   
1929                                ; Support routines
1930      X:000056 X:000056                   DC      'SGN',ST_GAIN
1931      X:000058 X:000058                   DC      'SBN',SET_BIAS_NUMBER
1932      X:00005A X:00005A                   DC      'SMX',SET_MUX
1933      X:00005C X:00005C                   DC      'CSW',CLR_SWS
1934      X:00005E X:00005E                   DC      'SOS',SEL_OS
1935      X:000060 X:000060                   DC      'SSS',SET_SUBARRAY_SIZES
1936      X:000062 X:000062                   DC      'SSP',SET_SUBARRAY_POSITIONS
1937      X:000064 X:000064                   DC      'RCC',READ_CONTROLLER_CONFIGURATION
1938   
1939                                ; New LBNL commands
1940      X:000066 X:000066                   DC      'ERS',ERASE                       ; Persistent Image Erase
1941      X:000068 X:000068                   DC      'HLD',HOLD_CLK                    ; Stop clocking during erase
1942      X:00006A X:00006A                   DC      'SPP',SET_PK_PAR                  ; Set pumping and EL_shutter parameters
1943      X:00006C X:00006C                   DC      'PMP',POCKET                      ; Start pocket pumping
1944   
1945                                 END_APPLICATON_COMMAND_TABLE
1946      00006E                              EQU     @LCV(L)
1947   
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  tim.asm  Page 37



1948                                          IF      @SCP("HOST","HOST")
1949      000023                    NUM_COM   EQU     (@LCV(R)-COM_TBL_R)/2             ; Number of boot +
1950                                                                                    ;  application commands
1951      000315                    EXPOSING  EQU     CHK_TIM                           ; Address if exposing
1952                                 CONTINUE_READING
1953      00026A                              EQU     CONTINUE_READ                     ; Address if reading out
1954                                          ENDIF
1955   
1956                                          IF      @SCP("HOST","ROM")
1958                                          ENDIF
1959   
1960                                ; Now let's go for the timing waveform tables
1961                                          IF      @SCP("HOST","HOST")
1962      Y:000000 Y:000000                   ORG     Y:0,Y:0
1963                                          ENDIF
1964   
1965      Y:000000 Y:000000         GAIN      DC      END_APPLICATON_Y_MEMORY-@LCV(L)-1
1966                                ; sg 2005-02-6 why are these numbers even in here? Shouldn't they come from the
1967                                ;              current.waveforms  file?
1968                                ; r.a. 3/1/2011 note 2 self:  these are dsp variables names that are hard wired to
1969                                ; dsp y memory locations via the org y:0, y:0 statement above so from the
1970                                ; outside (say excel) we can read (or set) the value of "GAIN" at location 0x400000
1971                                ; NSR is at 0x400001 and so on. some values are set via direct memory writes "commands" WRM
1972                                ; and some are set via "routines (which then go on to do more initing of
1973                                ; various hardware registers... somewhere.. (labels that are "jumped to" via the 3 letter
1974                                ; command jump table at the top... so SOS is the command for setting, left
1975                                ; right, or all ccd outputs and it is broken stuck to all in this source...
1976                                ; supposed to be settable from the gui but the jump table lable appears hacked out...
1977                                ; so SOS is supposed to go to asm code "SEL_OS" label but that's gone?
1978                                ;  roi is similarly diminished in this.  roi commands are sss and ssp and are not
1979                                ; even in this jump table.  (hacked to death)  r.a.
1980                                ;  so for example "ALL" could be sent down or '__L' for left ect.
1981                                ; this is locked at "ALL" (could do a WRM, write memory to change it but the
1982                                ; hardware would not be set appropriately so it would still be at all...
1983                                ;   NSR, NPR are just
1984                                ; DSP memory values that the readout code will look at later (when "SEX" is sent
1985                                ; down as a command...) and use as a reference for the loops in the (sex) readout routines
1986                                ; controls how many times the parallel and/or serial readout tables are "played" to
1987                                ; the timing (output arc ??) board.
1988                                ;NSR     DC      560            ; Number Serial Read, prescan + image + bias
1989                                ;NPR     DC      512            ; Number Parallel Read
1990                                ;GAINRA  DC      0               ; can not add new vars here or image will not complete being se
nt. r.a.
1991      Y:000001 Y:000001         NSR       DC      300                               ; Number Serial Read, prescan + image + bias
1992      Y:000002 Y:000002         NPR       DC      300                               ; Number Parallel Read
1993                                ;NS_CLR DC      1120            ; To clear the serial register
1994      Y:000003 Y:000003         NSCLR     DC      NS_CLR                            ;see waveform file 4 this one and next
1995      Y:000004 Y:000004         NPCLR     DC      NP_CLR                            ; To clear the parallel register
1996      Y:000005 Y:000005         NSBIN     DC      1                                 ; Serial binning parameter
1997      Y:000006 Y:000006         NPBIN     DC      1                                 ; Parallel binning parameter
1998      Y:000007 Y:000007         TST_DAT   DC      0                                 ; Temporary definition for test images
1999      Y:000008 Y:000008         SH_DEL    DC      10                                ; Delay in milliseconds between shutter clos
ing
2000                                                                                    ;   and image readout
2001      Y:000009 Y:000009         CONFIG    DC      CC                                ; Controller configuration
2002      Y:00000A Y:00000A         NS_READ   DC      0                                 ; brought in for roi r.a. 3/21/2011
2003      Y:00000B Y:00000B         OS        DC      'ALL'                             ; Output Source selection (1side 9/25/07 JE)
2004                                ;OS     DC      'LR'            ; Output Source selection (2sides)
2005                                ; RCOLS DC      300             ; Real # of cols to read in array
2006                                ; RROWS DC      300            ; Real # of rows to read in array
2007      Y:00000C Y:00000C         RCOLS     DC      2180                              ;2060      ;320            ; Real # of cols 
to read in array
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  tim.asm  Page 38



2008      Y:00000D Y:00000D         RROWS     DC      2200                              ;1100            ; Real # of rows to read in
 array
2009                                ;
2016   
2017                                ; Multiple readout addresses
2018                                ;SERIAL_READ    DC      SERIAL_READ_LR  ; Address of serial reading waveforms  (2sides)
2019                                ;SERIAL_CLEAR   DC      SERIAL_SKIP_LR  ; Address of serial skipping waveforms (2sides)
2020   
2021                                 SERIAL_SKIP
2022      Y:00000E Y:00000E                   DC      SERIAL_SKIP_L                     ; Serial skipping waveforms
2023                                 SERIAL_READ
2024      Y:00000F Y:00000F                   DC      SERIAL_READ_L                     ; Address of serial reading waveforms (1side
 9/25/07 JE)
2025                                 SERIAL_CLEAR
2026      Y:000010 Y:000010                   DC      SERIAL_SKIP_L                     ; Address of serial skipping waveforms(1side
 9/25/07 JE)
2027   
2028                                ; These parameters are set in "timCCDmisc.asm"
2029      Y:000011 Y:000011         NP_SKIP   DC      0                                 ; Number of rows to skip
2030      Y:000012 Y:000012         NS_SKP1   DC      0                                 ; Number of serials to clear before read
2031      Y:000013 Y:000013         NS_SKP2   DC      0                                 ; Number of serials to clear after read
2032      Y:000014 Y:000014         NRBIAS    DC      0                                 ; Number of bias pixels to read
2033      Y:000015 Y:000015         NSREAD    DC      0                                 ; Number of columns in subimage read
2034      Y:000016 Y:000016         NPREAD    DC      0                                 ; Number of rows in subimage read
2035   
2036                                ; Definitions for CCD HV erase
2037      Y:000017 Y:000017         TIME1     DC      1000                              ; Erase time
2038      Y:000018 Y:000018         TIME2     DC      500                               ; Delay for Vsub ramp-up
2039                                ; Timing board shutter
2040      Y:000019 Y:000019         CL_H      DC      100                               ; El Shutter msec
2041   
2042                                ; Pocket pumping parameters
2043      Y:00001A Y:00001A         PK_MULT   DC      10                                ; Multiplicater for Number of pumping  cycle
s
2044      Y:00001B Y:00001B         PK_SHF    DC      20                                ; Number of lines to be shifted every cycle
2045      Y:00001C Y:00001C         PK_CY     DC      100                               ; Number of pumping cycles
2046                                ; EPER slit width. running pocket pumping with non zero EPER value will
2047      Y:00001D Y:00001D         EPER      DC      0                                 ; activate EPER code instead of pumping code
.
2048      Y:00001E Y:00001E         GAINRA    DC      0                                 ; try it at the end this way.. sigh. r.a. 4/
21/2011
2049   
2050                                ; Include the waveform table for the designated type of CCD
2051                                          INCLUDE "current.waveforms"               ; Readout and clocking waveform file
2052                                ; Waveform tables and definitions for the LBNL CCD
2053                                ; This is for a slow, low noise readout
2054                                ; In this version the reset encloses the three serial clocks
2055                                ; sg 2006-02-02 FS clocks removed, lower levels redefined to 0V (was -3V)
2056                                ;**********************************************************************
2057      1.240000E+001             Vmax      EQU     +12.4                             ; ARC32 clock driver board max. voltage
2058   
2059                                ; Miscellaneous definitions
2060      000000                    VIDEO     EQU     $000000                           ; Video processor board select = 0
2061      002000                    CLK2      EQU     $002000                           ; Clock driver board select = 2
2062      003000                    CLK3      EQU     $003000                           ; Clock driver board select = 3
2063      000884                    NS_CLR    EQU     2180                              ;1120   ; Horizontal clocks to clear
2064      0008A2                    NP_CLR    EQU     2210                              ;4100   ; Parallel clocks to clear
2065   
2066      B00000                    I_DELAY   EQU     $B00000                           ; Integration period (was 83, changed to 87 
on 5/9/07)
2067   
2068                                ; Delay numbers for clocking
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 39



2069      C80000                    P_DELAY   EQU     $C80000                           ; Parallel clock delay ($88 looked bad)
2070      0C0000                    R_DELAY   EQU     $0C0000                           ; Serial register transfer delay
2071   
2072                                ;30 KHz waveforms
2073      060000                    S_DELAY   EQU     $060000                           ; Serial register skipping delay
2074      0C0000                    SW_DELAY  EQU     $0C0000                           ; Sum_well  clock delay = 96*20+80 = 2000 ns
2075   
2076                                ;98 KHz clocking wavefors
2077                                 PRE_SET_DLY
2078      0C0000                              EQU     $0c0000                           ; 96*20+80 = 2us
2079                                 POST_SET_DLY
2080      0C0000                              EQU     $0c0000                           ; (was $2e = 1us)
2081                                 DCRST_DELAY
2082      030000                              EQU     $030000                           ; settling time (was 03, changed to 43 on 7/
11/07)
2083   
2084                                ; Macros to help getting from volts to bits.
2085   
2086                                VDEF      MACRO   NAME,BRDTYP,BRDNUM,DAC,ALO,AHI
2087 m 
2088 m                              LO_\NAME  EQU     ALO
2089 m                              HI_\NAME  EQU     AHI
2090 m                              DAC_\NAME EQU     DAC
2091 m                               BRDNUM_\NAME
2092 m                                        EQU     BRDNUM
2093 m                                        IF      @SCP("BRDTYP",'VID')
2094 m                               BRDTYP_\NAME
2095 m                                        EQU     3
2096 m                                        ELSE
2097 m                               BRDTYP_\NAME
2098 m                                        EQU     0
2099 m                                        ENDIF
2100 m 
2101 m                                        MSG     'Defining voltage ',"NAME",' type ',"BRDTYP",' board ',"BRDNUM",' dac ',"DAC",
' with limits ',"ALO",' ',"AHI"
2102 m                                        ENDM
2103   
2104                                VOLTS     MACRO   NAME,F
2105 m 
2106 m                              DUMMY     SET     @CVI(@MIN(4095,@MAX(0,(F-LO_\NAME)/(HI_\NAME-LO_\NAME)*4096.)))
2107 m                              DUMMY2    SET     @CVI((BRDNUM_\NAME<<20)|(BRDTYP_\NAME<<18)|(DAC_\NAME<<14)|DUMMY)
2108 m                                        DC      DUMMY2
2109 m                                        MSG     'Setting voltage ',"NAME ","F",'V ',DUMMY
2110 m                                        ENDM
2111   
2112                                ;*********************************************************************
2113                                                                                    ; define video board voltage symbols
2114                                ; !! Temp !!        VDEF    INOFFA,VID,0,0,-10.0,10.0
2115                                ; sg 2007-5-18 output offset is the name (in the ARC45 user manual) for signal A/D-BIAS-A in the
2116                                ; ARC45 schematic PDF file
2117                                ;        VDEF    OUTOFFA,VID,0,1,-10.0,10.0
2118                                ; !! Temp !!        VDEF    INOFFB,VID,0,2,-10.0,10.0
2119                                ; !! Temp !!        VDEF    OUTOFFB,VID,0,3,-10.0,10.0
2120   
2121   
2122                                ; Define switch state bits for the CCD clocks of the LBNL CCD
2123                                ;Bank 0
2124      000000                    V1L       EQU     0
2125      000001                    V1H       EQU     $1
2126      000000                    V2L       EQU     0                                 ; VERTICAL register, phase #2
2127      000002                    V2H       EQU     $2                                ; was $2
2128      000000                    V3L       EQU     0                                 ; VERTICAL register, phase #3
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 40



2129      000004                    V3H       EQU     $4                                ; was $4
2130      000000                    FS1L      EQU     0
2131      000000                    FS1H      EQU     0                                 ; was $8
2132      000000                    FS2L      EQU     0
2133      000000                    FS2H      EQU     0                                 ; was $10
2134      000000                    FS3L      EQU     0
2135      000000                    FS3H      EQU     0                                 ; was $20
2136   
2137   
2138      000000                    TL        EQU     0                                 ; Transfer gate
2139      0000C0                    TH        EQU     $c0                               ; both transfer gates concurrently
2140   
2141   
2142                                ; 3/30/2011 OS switching: "never got it to work"  as per juan via r.a.
2143                                ; so what they do is switch h1 and h3
2144                                ; reading to the left then the hi's going down  should be 1, 2, 4, 8, 10, 20, c0, 300, 400
2145                                ; reading to the right then 4 and 8 get reversed  to 8 , 4 going down.
2146                                ; (will try to get it to work...) r.a.
2147                                ;Bank 1
2148      000000                    HU1L      EQU     0
2149      000001                    HU1H      EQU     $001                              ;was $001
2150      000000                    HU2L      EQU     0
2151      000002                    HU2H      EQU     $002                              ;was $002
2152      000000                    HU3L      EQU     0
2153      000004                    HU3H      EQU     $004                              ;was $004
2154      000000                    HL1L      EQU     0                                 ; Serial shift register, phase #1
2155      000008                    HL1H      EQU     $008                              ; was $008
2156      000000                    HL2L      EQU     0                                 ; Serial shift register, phase #2
2157      000010                    HL2H      EQU     $010                              ; was $010
2158      000000                    HL3L      EQU     0                                 ; Serial shift register, phase #3
2159      000020                    HL3H      EQU     $020                              ;was $020
2160      000000                    WL        EQU     0                                 ; Both summing wells clocked together
2161      0008C0                    WH        EQU     $8c0                              ; was $0c0   8c0 is pins 19, (ox40) 33, (0x8
0) and 37 (0x800) together.  33 does not work on the new crate.
2162      000000                    RL        EQU     0                                 ; Reset both output nodes
2163      000300                    RH        EQU     $300
2164      000000                    TCLL      EQU     0
2165      000400                    TCLH      EQU     $400                              ; test clock
2166   
2167   
2168                                ;  ***  Definitions for Y: memory waveform tables  *****
2169                                ; Clock the Parallel clocks : I1->I2->I3, always
2170                                PARALLEL
2171      Y:00001F Y:00001F                   DC      PARALLEL_CLEAR-PARALLEL-1
2172      Y:000020 Y:000020                   DC      CLK3+$000000+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2173      Y:000021 Y:000021                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3H+TL ;
2174      Y:000022 Y:000022                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3L+V1H+V2L+V3L+TL ; 3 low
2175      Y:000023 Y:000023                   DC      CLK2+P_DELAY+FS1H+FS2H+FS3L+V1H+V2H+V3L+TL ; 2 hi
2176      Y:000024 Y:000024                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3L+V1L+V2H+V3L+TL ; 1 low
2177      Y:000025 Y:000025                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3H+V1L+V2H+V3H+TL ; 3 hi
2178      Y:000026 Y:000026                   DC      CLK2+P_DELAY+FS1L+FS2L+FS3H+V1L+V2L+V3H+TH ; shut TG, 2 lo
2179   
2180                                PARALLEL_CLEAR
2181      Y:000027 Y:000027                   DC      P_PARAL-PARALLEL_CLEAR-1
2182      Y:000028 Y:000028                   DC      CLK3+$000000+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2183      Y:000029 Y:000029                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3H+TL
2184      Y:00002A Y:00002A                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3L+V1H+V2L+V3L+TL
2185      Y:00002B Y:00002B                   DC      CLK2+P_DELAY+FS1H+FS2H+FS3L+V1H+V2H+V3L+TL
2186      Y:00002C Y:00002C                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3L+V1L+V2H+V3L+TL
2187      Y:00002D Y:00002D                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3H+V1L+V2H+V3H+TL
2188      Y:00002E Y:00002E                   DC      CLK2+P_DELAY+FS1L+FS2L+FS3H+V1L+V2L+V3H+TH ; shut TG
2189   
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 41



2190      Y:00002F Y:00002F         P_PARAL   DC      P_PARAL_INV-P_PARAL-1
2191      Y:000030 Y:000030                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3H+TH
2192      Y:000031 Y:000031                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3L+V1H+V2L+V3L+TH
2193      Y:000032 Y:000032                   DC      CLK2+P_DELAY+FS1H+FS2H+FS3L+V1H+V2H+V3L+TH
2194      Y:000033 Y:000033                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3L+V1L+V2H+V3L+TH
2195      Y:000034 Y:000034                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3H+V1L+V2H+V3H+TH
2196      Y:000035 Y:000035                   DC      CLK2+P_DELAY+FS1L+FS2L+FS3H+V1L+V2L+V3H+TH ; shut TG
2197   
2198                                P_PARAL_INV
2199      Y:000036 Y:000036                   DC      P_EPER-P_PARAL_INV-1
2200      Y:000037 Y:000037                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3H+TH
2201      Y:000038 Y:000038                   DC      CLK2+P_DELAY+FS1L+FS2L+FS3H+V1L+V2L+V3H+TH
2202      Y:000039 Y:000039                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3H+V1L+V2H+V3H+TH
2203      Y:00003A Y:00003A                   DC      CLK2+P_DELAY+FS1L+FS2H+FS3L+V1L+V2H+V3L+TH
2204      Y:00003B Y:00003B                   DC      CLK2+P_DELAY+FS1H+FS2H+FS3L+V1H+V2H+V3L+TH
2205      Y:00003C Y:00003C                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3L+V1H+V2L+V3L+TH ; shut TG
2206   
2207      Y:00003D Y:00003D         P_EPER    DC      END_P_EPER-P_EPER-1
2208      Y:00003E Y:00003E                   DC      CLK3+$000000+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2209      Y:00003F Y:00003F                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3H+TL ; or V clocking
2210      Y:000040 Y:000040                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1L+V2L+V3H+TL ; upwards
2211      Y:000041 Y:000041                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1L+V2H+V3H+TL
2212      Y:000042 Y:000042                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1L+V2H+V3L+TL
2213      Y:000043 Y:000043                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2H+V3L+TL
2214      Y:000044 Y:000044                   DC      CLK2+P_DELAY+FS1H+FS2L+FS3H+V1H+V2L+V3L+TH ; shut TG
2215                                END_P_EPER
2216      Y:000045 Y:000045                   DC      0
2217   
2218                                ; Video processor bit definition
2219                                ;            xfer, A/D, integ, Pol+, Pol-, DCrestore, rst   (1 => switch open)
2220                                ; Both amps is H1->H2->H3
2221                                ; L amp is H1->H2->H3
2222                                ; U amp is H3->H2->H1
2223   
2224                                SERIAL_IDLE                                         ; Clock serial charge from both L and R ends
2225      Y:000046 Y:000046                   DC      END_SERIAL_IDLE-SERIAL_IDLE-1
2226      Y:000047 Y:000047                   DC      VIDEO+$000000+%1110100            ; ADCLatch,NonInv,DCRestore,StrtRstInt.
2227   
2228      Y:000048 Y:000048                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo,Reset_On
2229      Y:000049 Y:000049                   DC      CLK3+S_DELAY+RL+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h1->lo
2230      Y:00004A Y:00004A                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h2->hi
2231      Y:00004B Y:00004B                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->lo
2232      Y:00004C Y:00004C                   DC      CLK3+S_DELAY+RL+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h1->hi
2233      Y:00004D Y:00004D                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h2->lo
2234      Y:00004E Y:00004E                   DC      CLK3+PRE_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;h3->hi,Delay
2235   
2236   
2237      Y:00004F Y:00004F                   DC      CLK3+$000000+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;dummy for transmit delay
2238      Y:000050 Y:000050                   DC      VIDEO+$000000+%1110111            ; StopDCRestore and StopResetIntegrator
2239      Y:000051 Y:000051                   DC      VIDEO+I_DELAY+%0000111            ; Integrate for I_DELAY microsec
2240      Y:000052 Y:000052                   DC      VIDEO+$000000+%0011011            ; Stop Integrate and sel inverting int.
2241      Y:000053 Y:000053                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2242      Y:000054 Y:000054                   DC      CLK3+POST_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2243      Y:000055 Y:000055                   DC      VIDEO+I_DELAY+%0001011            ; Integrate for I_DELAY microsec
2244      Y:000056 Y:000056                   DC      VIDEO+$000000+%0011011            ; StopIntegrator
2245      Y:000057 Y:000057                   DC      VIDEO+DCRST_DELAY+%1110111        ; ADCLatch,NonInv  ;mF to do ADC sampling be
fore resetting
2246                                END_SERIAL_IDLE
2247   
2248   
2249                                ;start binning waveforms
2250                                CCD_RESET                                           ;Used for binning only
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 42



2251      Y:000058 Y:000058                   DC      SERIAL_CLOCK_L-CCD_RESET-1
2252   
2253                                SERIAL_CLOCK_L                                      ;"NORMAL" clocking
2254      Y:000059 Y:000059                   DC      SERIAL_CLOCK_R-SERIAL_CLOCK_L-1
2255      Y:00005A Y:00005A                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;h3->lo,SW->lo,Reset_On
2256      Y:00005B Y:00005B                   DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h2->hi
2257      Y:00005C Y:00005C                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h1->lo
2258      Y:00005D Y:00005D                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2259      Y:00005E Y:00005E                   DC      CLK3+S_DELAY+RH+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h2->lo
2260      Y:00005F Y:00005F                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h1->hi
2261      Y:000060 Y:000060                   DC      CLK3+PRE_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2262   
2263                                SERIAL_CLOCK_R                                      ;"REVERSE" clocking
2264      Y:000061 Y:000061                   DC      SERIAL_CLOCK_LR-SERIAL_CLOCK_R-1
2265   
2266                                SERIAL_CLOCK_LR                                     ;"SPLIT" clocking
2267      Y:000062 Y:000062                   DC      VIDEO_PROCESS-SERIAL_CLOCK_LR-1
2268   
2269                                VIDEO_PROCESS
2270      Y:000063 Y:000063                   DC      END_VIDEO-VIDEO_PROCESS-1
2271      Y:000064 Y:000064         SXMIT     DC      $00F000                           ; Transmit A/D data to host
2272                                END_VIDEO
2273   
2274                                ;end binning waveforms
2275   
2276                                ; The fast serial code with the circulating address register must start
2277                                ;   on a boundary that is a multiple of the address register modulus.
2278   
2279                                ; Video processor bit definition
2280                                ;            xfer, A/D, integ, Pol+, Pol-, DCrestore, rst   (1 => switch open)
2281   
2282                                ; These are the three reading tables. Make sure they're all the same length
2283                                SERIAL_TEST
2284      Y:000065 Y:000065                   DC      END_SERIAL_TEST-SERIAL_TEST-1
2285      Y:000066 Y:000066                   DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h2->hi
2286      Y:000067 Y:000067                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h2->hi
2287                                END_SERIAL_TEST
2288                                ; switch the two polarity bits (3rd and 4th from the right000xx00) in all VIDEO words
2289                                SERIAL_READ_L
2290      Y:000068 Y:000068                   DC      END_SERIAL_READ_L-SERIAL_READ_L-1
2291      Y:000069 Y:000069                   DC      VIDEO+$000000+%1110100            ; NonInv,DCRestore,StrtRstInt.
2292      Y:00006A Y:00006A                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_On
2293      Y:00006B Y:00006B                   DC      CLK3+S_DELAY+RL+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h1->lo, Reset_off
2294      Y:00006C Y:00006C                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h2->hi
2295      Y:00006D Y:00006D                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->lo
2296      Y:00006E Y:00006E                   DC      CLK3+S_DELAY+RL+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h1->hi
2297      Y:00006F Y:00006F                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h2->lo
2298      Y:000070 Y:000070                   DC      CLK3+PRE_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;h3->hi,Delay
2299      Y:000071 Y:000071         SXL       DC      $00F000                           ; Transmit a/d data to host SELECT_OUTPUT_SO
URCE overwrites this at runtime
2300      Y:000072 Y:000072                   DC      VIDEO+$000000+%1110111            ; StopDCRestore and StopResetIntegrator
2301      Y:000073 Y:000073                   DC      VIDEO+I_DELAY+%0000111            ; Integrate for I_DELAY microsec
2302      Y:000074 Y:000074                   DC      VIDEO+$000000+%0011011            ; Stop Integrate and sel inverting int.
2303      Y:000075 Y:000075                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2304      Y:000076 Y:000076                   DC      CLK3+POST_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2305      Y:000077 Y:000077                   DC      VIDEO+I_DELAY+%0001011            ; Integrate for I_DELAY microsec
2306      Y:000078 Y:000078                   DC      VIDEO+$000000+%0011011            ; StopIntegrator
2307      Y:000079 Y:000079                   DC      VIDEO+DCRST_DELAY+%1110111        ; ADCLatch,NonInv  ;mF to do ADC sampeling b
evore resetting
2308                                END_SERIAL_READ_L
2309   
2310                                SERIAL_READ_R
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 43



2311      Y:00007A Y:00007A                   DC      END_SERIAL_READ_R-SERIAL_READ_R-1
2312      Y:00007B Y:00007B                   DC      VIDEO+$000000+%1110100            ; ADCLatch,NonInv,DCRestore,StrtRstInt.
2313      Y:00007C Y:00007C                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;h3->lo,SW->lo,Reset_On
2314      Y:00007D Y:00007D                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h2->hi
2315      Y:00007E Y:00007E                   DC      CLK3+S_DELAY+RL+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h1->lo
2316      Y:00007F Y:00007F                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2317      Y:000080 Y:000080                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h2->lo
2318      Y:000081 Y:000081                   DC      CLK3+S_DELAY+RL+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h1->hi
2319      Y:000082 Y:000082                   DC      CLK3+PRE_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2320      Y:000083 Y:000083         SXR       DC      $00F041                           ;Transmit a/d data to host SELECT_OUTPUT_SOU
RCE overwrites this at runtime
2321      Y:000084 Y:000084                   DC      VIDEO+$000000+%1110111            ; StopDCRestore and StopResetIntegrator
2322      Y:000085 Y:000085                   DC      VIDEO+I_DELAY+%0000111            ; Integrate for I_DELAY microsec
2323      Y:000086 Y:000086                   DC      VIDEO+$000000+%0011011            ; Stop Integrate and sel inverting int.
2324      Y:000087 Y:000087                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2325      Y:000088 Y:000088                   DC      CLK3+POST_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2326      Y:000089 Y:000089                   DC      VIDEO+I_DELAY+%0001011            ; Integrate for I_DELAY microsec
2327      Y:00008A Y:00008A                   DC      VIDEO+$000000+%0011011            ; StopResetIntegrator
2328      Y:00008B Y:00008B                   DC      VIDEO+DCRST_DELAY+%1110111        ; ADCLatch,NonInv  ;mF to do ADC sampeling b
evore resetting
2329                                END_SERIAL_READ_R
2330   
2331                                SERIAL_READ_LR
2332      Y:00008C Y:00008C                   DC      END_SERIAL_READ_LR-SERIAL_READ_LR-1
2333      Y:00008D Y:00008D                   DC      VIDEO+$000000+%1110100            ; ADCLatch,NonInv,DCRestore,StrtRstInt.
2334      Y:00008E Y:00008E                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;h3->lo,SW->lo,Reset_On
2335      Y:00008F Y:00008F                   DC      CLK3+S_DELAY+RL+HU1L+HU2L+HU3H+HL1H+HL2L+HL3L+WL ;h2->hi
2336      Y:000090 Y:000090                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3H+HL1H+HL2H+HL3L+WL ;h1->lo
2337      Y:000091 Y:000091                   DC      CLK3+S_DELAY+RL+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2338      Y:000092 Y:000092                   DC      CLK3+S_DELAY+RL+HU1H+HU2H+HU3L+HL1L+HL2H+HL3H+WL ;h2->lo
2339      Y:000093 Y:000093                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3L+HL1L+HL2L+HL3H+WL ;h1->hi
2340      Y:000094 Y:000094                   DC      CLK3+PRE_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2341      Y:000095 Y:000095         SXRL      DC      $00F040                           ;Transmit a/d data to host SELECT_OUTPUT_SOU
RCE overwrites this at runtime
2342      Y:000096 Y:000096                   DC      VIDEO+$000000+%1110111            ; StopDCRestore and StopResetIntegrator
2343      Y:000097 Y:000097                   DC      VIDEO+I_DELAY+%0000111            ; Integrate for I_DELAY microsec
2344      Y:000098 Y:000098                   DC      VIDEO+$000000+%0011011            ; Stop Integrate and sel inverting int.
2345      Y:000099 Y:000099                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2346      Y:00009A Y:00009A                   DC      CLK3+POST_SET_DLY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;SW->lo
2347      Y:00009B Y:00009B                   DC      VIDEO+I_DELAY+%0001011            ; Integrate for I_DELAY microsec
2348      Y:00009C Y:00009C                   DC      VIDEO+$000000+%0011011            ; StopResetIntegrator
2349      Y:00009D Y:00009D                   DC      VIDEO+DCRST_DELAY+%1110111        ; ADCLatch,NonInv  ;mF to do ADC sampeling b
evore resetting
2350                                END_SERIAL_READ_LR
2351   
2352                                ; These are the three skipping tables. Make sure they're all the same length
2353                                SERIAL_SKIP_L                                       ; Serial clocking waveform for skipping left
2354      Y:00009E Y:00009E                   DC      END_SERIAL_SKIP_L-SERIAL_SKIP_L-1
2355      Y:00009F Y:00009F                   DC      VIDEO+$000000+%1110100            ; Change nearly everything
2356      Y:0000A0 Y:0000A0                   DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h2->hi
2357      Y:0000A1 Y:0000A1                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h1->lo
2358      Y:0000A2 Y:0000A2                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2359      Y:0000A3 Y:0000A3                   DC      CLK3+S_DELAY+RH+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h2->lo
2360      Y:0000A4 Y:0000A4                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h1->hi
2361      Y:0000A5 Y:0000A5                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2362      Y:0000A6 Y:0000A6                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2363                                END_SERIAL_SKIP_L
2364   
2365                                SERIAL_SKIP_R                                       ; Serial clocking waveform for skipping righ
t
2366      Y:0000A7 Y:0000A7                   DC      END_SERIAL_SKIP_R-SERIAL_SKIP_R-1
2367      Y:0000A8 Y:0000A8                   DC      VIDEO+$000000+%1110100            ; Change nearly everything
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 44



2368      Y:0000A9 Y:0000A9                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3L+HL1H+HL2L+HL3L+WL ;h2->hi
2369      Y:0000AA Y:0000AA                   DC      CLK3+S_DELAY+RH+HU1H+HU2H+HU3L+HL1H+HL2H+HL3L+WL ;h1->lo
2370      Y:0000AB Y:0000AB                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2371      Y:0000AC Y:0000AC                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3H+HL1L+HL2H+HL3H+WL ;h2->lo
2372      Y:0000AD Y:0000AD                   DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1L+HL2L+HL3H+WL ;h1->hi
2373      Y:0000AE Y:0000AE                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2374      Y:0000AF Y:0000AF                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2375                                END_SERIAL_SKIP_R
2376   
2377                                SERIAL_SKIP_LR                                      ; Serial clocking waveform for skipping both
 ends
2378      Y:0000B0 Y:0000B0                   DC      END_SERIAL_SKIP_LR-SERIAL_SKIP_LR-1
2379      Y:0000B1 Y:0000B1                   DC      VIDEO+$000000+%1110100            ; Change nearly everything
2380      Y:0000B2 Y:0000B2                   DC      CLK3+S_DELAY+RH+HU1H+HU2L+HU3L+HL1L+HL2L+HL3H+WL ;h2->hi
2381      Y:0000B3 Y:0000B3                   DC      CLK3+S_DELAY+RH+HU1H+HU2H+HU3L+HL1L+HL2H+HL3H+WL ;h1->lo
2382      Y:0000B4 Y:0000B4                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3L+HL1L+HL2H+HL3L+WL ;h3->hi
2383      Y:0000B5 Y:0000B5                   DC      CLK3+S_DELAY+RH+HU1L+HU2H+HU3H+HL1H+HL2H+HL3L+WL ;h2->lo
2384      Y:0000B6 Y:0000B6                   DC      CLK3+S_DELAY+RH+HU1L+HU2L+HU3H+HL1H+HL2L+HL3L+WL ;h1->hi
2385      Y:0000B7 Y:0000B7                   DC      CLK3+S_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WL ;Reset_Off+Delay
2386      Y:0000B8 Y:0000B8                   DC      CLK3+SW_DELAY+RL+HU1H+HU2L+HU3H+HL1H+HL2L+HL3H+WH ;SW->hi
2387                                END_SERIAL_SKIP_LR
2388   
2389                                ;brought in and guestafied 4/7/2011 r.a.
2390                                PARALLELS_DURING_EXPOSURE
2391      Y:0000B9 Y:0000B9                   DC      END_PARALLELS_DURING_EXPOSURE-PARALLELS_DURING_EXPOSURE-1
2392      Y:0000BA Y:0000BA                   DC      CLK3+0000000+00+00+V3H+FS3H+TH    ;   during exposure
2393                                END_PARALLELS_DURING_EXPOSURE
2394   
2395                                ;brought in and guestafied for new roi code in the 8.1misc.asm code r.a. 8/21/2011
2396                                PARALLELS_DURING_READOUT
2397      Y:0000BB Y:0000BB                   DC      END_PARALLELS_DURING_READOUT-PARALLELS_DURING_READOUT-1
2398      Y:0000BC Y:0000BC                   DC      CLK3+P_DELAY+V1H+00+V3H+FS1H+FS2L+FS3H+TH ;tg>th added fs*h/L to this.. right?
 r.a.
2399                                END_PARALLELS_DURING_READOUT
2400   
2401                                ; persistent image erase voltage tables
2402                                ; Removed 11/7/05 at UM
2403                                VSUBN
2404   
2405      Y:0000BD Y:0000BD         ERHI      DC      EREND-ERHI-1
2406   
2407      Y:0000BE Y:0000BE         EREND     DC      EREND2-EREND-1
2408   
2409                                EREND2
2410   
2411                                ; Bias voltages for the LBL CCD
2412      7.500000E+000             BZERO     EQU     7.5                               ; Zero Bias
2413      3.000000E+001             Vsub      EQU     30.0                              ; Substrate Voltage
2414      -1.000000E+001            OutDrain  EQU     -10.0                             ; Output Drain
2415      3.500000E+000             OutGate   EQU     3.50                              ; Output Gate (was 2.16)
2416      -1.000000E+001            RstDrain  EQU     -10.0                             ; Reset Drain
2417      5.000000E-001             Btest     EQU     0.5                               ; bias test voltage
2418   
2419                                ; Define high and low clock levels
2420      0.000000E+000             CK_ZERO   EQU     0.0
2421      5.000000E+000             VCLK_HI   EQU     5.0
2422      -3.000000E+000            VCLK_LO   EQU     -3.0
2423      8.000000E+000             HCLK_HI   EQU     8.0                               ; was 8.0
2424      -4.000000E+000            HCLK_LO   EQU     -4.0                              ; was -4.0
2425      5.000000E+000             TGATE_HI  EQU     5.0
2426      -3.000000E+000            TGATE_LO  EQU     -3.0
2427      4.500000E+000             SWELL_HI  EQU     4.5                               ; was 4.5
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 45



2428      -4.500000E+000            SWELL_LO  EQU     -4.5                              ; was -4.5
2429      -6.000000E+000            RGATE_HI  EQU     -6.0                              ; -6.0 Reset ACTIVE wrong polarity....
2430      0.000000E+000             RGATE_LO  EQU     0.0                               ; Reset INACTIVE (from LBL - brownmg 11/7/05
)
2431      0.000000E+000             TCLK_LO   EQU     .0
2432      1.000000E-001             TCLK_HI   EQU     0.1
2433   
2434                                ; Initialization of clock driver and video processor DACs and switches
2435      Y:0000BF Y:0000BF         DACS      DC      END_DACS-DACS-1
2436   
2437                                ; Set gain and integrator speed. x 1 gain, FAST integrate
2438      Y:0000C0 Y:0000C0                   DC      $0c3cbb                           ; Gain, integrate speed, board #0
2439   
2440                                ; Input offset voltages for DC coupling. Target is U4#6 = 24 volts
2441                                ; This voltage is not used since we use AC coupling
2442                                ; !! Temp !!        VOLTS   INOFFA,0.0              ; Input offset, ch. A
2443                                ; sg 2007-5-18 enable output offset voltage; but maybe the macro stuff doesn't work
2444                                ;     VOLTS   OUTOFFA,-9.9            ; Output video offset, ch. A
2445   
2446                                ; Output offset voltages to get around 1000 DN A/D units on a dark frame
2447                                ; !! Temp !!        VOLTS   INOFFB,0.0              ; Input offset, ch. B
2448                                ; !! Temp !!        VOLTS   OUTOFFB,-2.5            ; Output video offset, ch. B
2449                                                                                    ; sg 2006-02-02 changed FS1 to FS3 2nd (low)
 levels from VCLK_Lo+Vmax to Vmax
2450                                ; Set the levels on the clock board
2451      Y:0000C1 Y:0000C1                   DC      $2A0080                           ; DAC = unbuffered mode
2452      Y:0000C2 Y:0000C2                   DC      $200100+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #1, V1L
2453      Y:0000C3 Y:0000C3                   DC      $200200+@CVI((VCLK_LO+Vmax)/(2*Vmax)*255)
2454      Y:0000C4 Y:0000C4                   DC      $200400+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #2, V2L
2455      Y:0000C5 Y:0000C5                   DC      $200800+@CVI((VCLK_LO+Vmax)/(2*Vmax)*255)
2456      Y:0000C6 Y:0000C6                   DC      $202000+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #3, V3L
2457      Y:0000C7 Y:0000C7                   DC      $204000+@CVI((VCLK_LO+Vmax)/(2*Vmax)*255)
2458      Y:0000C8 Y:0000C8                   DC      $208000+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #4, FS1
2459      Y:0000C9 Y:0000C9                   DC      $210000+@CVI((Vmax)/(2*Vmax)*255)
2460      Y:0000CA Y:0000CA                   DC      $220100+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #5, FS2
2461      Y:0000CB Y:0000CB                   DC      $220200+@CVI((Vmax)/(2*Vmax)*255)
2462      Y:0000CC Y:0000CC                   DC      $220400+@CVI((VCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #6, FS3
2463      Y:0000CD Y:0000CD                   DC      $220800+@CVI((Vmax)/(2*Vmax)*255)
2464      Y:0000CE Y:0000CE                   DC      $222000+@CVI((TGATE_HI+Vmax)/(2*Vmax)*255) ; Pin #7, Trans Gate
2465      Y:0000CF Y:0000CF                   DC      $224000+@CVI((TGATE_LO+Vmax)/(2*Vmax)*255)
2466      Y:0000D0 Y:0000D0                   DC      $228000+@CVI((TGATE_HI+Vmax)/(2*Vmax)*255) ; Pin #8, Trans Gate
2467      Y:0000D1 Y:0000D1                   DC      $230000+@CVI((TGATE_LO+Vmax)/(2*Vmax)*255)
2468      Y:0000D2 Y:0000D2                   DC      $240100+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255) ; Pin #9, Unused
2469      Y:0000D3 Y:0000D3                   DC      $240200+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255)
2470      Y:0000D4 Y:0000D4                   DC      $240400+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255) ; Pin #10, Unused
2471      Y:0000D5 Y:0000D5                   DC      $240800+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255)
2472      Y:0000D6 Y:0000D6                   DC      $242000+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255) ; Pin #11, Unused
2473      Y:0000D7 Y:0000D7                   DC      $244000+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255)
2474      Y:0000D8 Y:0000D8                   DC      $248000+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255) ; Pin #12, Unused
2475      Y:0000D9 Y:0000D9                   DC      $250000+@CVI((CK_ZERO+Vmax)/(2*Vmax)*255)
2476   
2477      Y:0000DA Y:0000DA                   DC      $260100+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #13, HU1
2478      Y:0000DB Y:0000DB                   DC      $260200+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2479      Y:0000DC Y:0000DC                   DC      $260400+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #14, HU2
2480      Y:0000DD Y:0000DD                   DC      $260800+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2481      Y:0000DE Y:0000DE                   DC      $262000+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #15, HU3
2482      Y:0000DF Y:0000DF                   DC      $264000+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2483      Y:0000E0 Y:0000E0                   DC      $268000+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #16, HL1
2484      Y:0000E1 Y:0000E1                   DC      $270000+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2485      Y:0000E2 Y:0000E2                   DC      $280100+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #17, HL2
2486      Y:0000E3 Y:0000E3                   DC      $280200+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2487      Y:0000E4 Y:0000E4                   DC      $280400+@CVI((HCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #18, HL3
Motorola DSP56300 Assembler  Version 6.3.4   18-04-02  17:49:56  current.waveforms  Page 46



2488      Y:0000E5 Y:0000E5                   DC      $280800+@CVI((HCLK_LO+Vmax)/(2*Vmax)*255)
2489      Y:0000E6 Y:0000E6                   DC      $282000+@CVI((SWELL_HI+Vmax)/(2*Vmax)*255) ; Pin #19, Summing Well
2490      Y:0000E7 Y:0000E7                   DC      $284000+@CVI((SWELL_LO+Vmax)/(2*Vmax)*255)
2491      Y:0000E8 Y:0000E8                   DC      $288000+@CVI((SWELL_HI+Vmax)/(2*Vmax)*255) ; Pin #33, Summing Well  broke on d
ave's crate
2492      Y:0000E9 Y:0000E9                   DC      $290000+@CVI((SWELL_LO+Vmax)/(2*Vmax)*255)
2493      Y:0000EA Y:0000EA                   DC      $2A0100+@CVI((RGATE_HI+Vmax)/(2*Vmax)*255) ; Pin #34, Reset Gate
2494      Y:0000EB Y:0000EB                   DC      $2A0200+@CVI((RGATE_LO+Vmax)/(2*Vmax)*255)
2495      Y:0000EC Y:0000EC                   DC      $2A0400+@CVI((RGATE_HI+Vmax)/(2*Vmax)*255) ; Pin #35, Reset Gate
2496      Y:0000ED Y:0000ED                   DC      $2A0800+@CVI((RGATE_LO+Vmax)/(2*Vmax)*255)
2497      Y:0000EE Y:0000EE                   DC      $2A2000+@CVI((TCLK_HI+Vmax)/(2*Vmax)*255) ; Pin #36, Bias test voltage
2498      Y:0000EF Y:0000EF                   DC      $2A4000+@CVI((TCLK_LO+Vmax)/(2*Vmax)*255)
2499      Y:0000F0 Y:0000F0                   DC      $2A8000+@CVI((SWELL_HI+Vmax)/(2*Vmax)*255) ; Pin #37, upper SW 4 dave's crate
2500      Y:0000F1 Y:0000F1                   DC      $2B0000+@CVI((SWELL_LO+Vmax)/(2*Vmax)*255)
2501   
2502                                ; Set the voltages on the video board 25 pin connector for ARC45 video board
2503      Y:0000F2 Y:0000F2                   DC      $0d0000+@CVI((Vsub-7.5)/22.5*4095) ; pin 1 - Vsub
2504      Y:0000F3 Y:0000F3                   DC      $0d4000+@CVI((BZERO-7.5)/22.5*4095) ; pin 2
2505      Y:0000F4 Y:0000F4                   DC      $0c0000+@CVI((BZERO-5)/15*4095)   ; pin 3
2506      Y:0000F5 Y:0000F5                   DC      $0c4000+@CVI((BZERO-5)/15*4095)   ; pin 4
2507      Y:0000F6 Y:0000F6                   DC      $0d8000+@CVI((BZERO-7.5)/22.5*4095) ; pin 5
2508      Y:0000F7 Y:0000F7                   DC      $0dc000+@CVI((BZERO-7.5)/22.5*4095) ; pin 6
2509      Y:0000F8 Y:0000F8                   DC      $0e0000+@CVI((OutDrain+10)/20*4095) ; pin 9 - Reset Drain
2510      Y:0000F9 Y:0000F9                   DC      $0e4000+@CVI((RstDrain+10)/20*4095) ; pin 10 - Out Drain
2511      Y:0000FA Y:0000FA                   DC      $0e8000+@CVI((OutGate+10)/20*4095) ; pin 11 - Out Gate
2512      Y:0000FB Y:0000FB                   DC      $0ec000+@CVI((BZERO+10)/20*4095)  ; pin 12
2513      Y:0000FC Y:0000FC                   DC      $0C8600                           ; OUTOFFA = 000 sg 2007-05-23
2514                                END_DACS
2515   
2516   
2517   
2518   
2519                                 END_APPLICATON_Y_MEMORY
2520      0000FD                              EQU     @LCV(L)
2521   
2522                                ; End of program
2523                                          END

0    Errors
0    Warnings


