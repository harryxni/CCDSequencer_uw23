This is the new super sequencer. You can use this with CCDDrone or Owl. Your choice. This essentially adds the following commands:


SAT: Select amplifier type. 0 for skipper and 1 for DES. In owl, go to Debug --> put SAT in the first box and 0 or 1 in the second.

SSR: Set skipper repeat. How many times do you want to repeat a skipper measurement?

VDR: V-clock direction. 0 for 1->2->3 and 1 for 3->2->1

HDR: H-clock direction. 0 for 1->2->3 and 1 for 3->2->1. Do this AFTER you select amplifier using SOS

CIT: Change Integration Time. The second variable needs to be what "I_DELAY" used to be before. Use idelayvar.sh to calculate this and make sure to check "hexadecimal values". Try C00000 as default for DES CCDs.


Send comments to Pitam Mitra at pitamm@uw.edu

Enjoy.