This is the new super sequencer. As of commit #2a469de, you can NO LONGER use this with Owl (easily). I am working on a cross compatible sequencer, but that is not ready yet and it is a low priority. 


This sequencer adds the following commands:
--------------------------------------------
SAT: Select amplifier type. 0 for skipper and 1 for DES. 

SSR: Set skipper repeat. How many times do you want to repeat a skipper measurement?

VDR: V-clock direction. 0 for 1->2->3 and 1 for 3->2->1

HDR: H-clock direction. 0 for 1->2->3 and 1 for 3->2->1. Do this AFTER you select amplifier using SOS

CIT: Change Integration Time. The second variable needs to be what "I_DELAY" used to be before. Use idelayvar.sh to calculate this and make sure to check "hexadecimal values". Try C00000 as default for DES CCDs.

STC: Set the number of columns to read. You will HAVE to set this before you attempt a readout, since the default value is 0. With that default value, you wont see any images!
--------------------------------------------

Upcoming:
--------------------------------------------
Set the PRE_SET_DELAY
Set POST_SET_DELAY
Set VE_DELAY

These are required to achieve a lower noise.
--------------------------------------------


Send comments to Pitam Mitra at pitamm@uw.edu

Enjoy.
