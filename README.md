This is the new super sequencer to drive a Leach system. It can be used to operate a DESI/Regular CCD or a Skipper CCD. It is recommended that you use this in conjunction with CCDDrone. There are two version of this firmware. You can compile one of them with ./DSPMake and the other with ./DSPMakeSimple. The difference is that a lot of extra functionality like synthetic imaging, binning etc are removed from the simple version in the interest of keeping a clean and concise version of the code that is easy to understand. 

As of commit #2a469de, you can no longer use this with Owl (easily) unless you specify ALL of these extra parameters manually. I am not working on a sequencer that is "plug-and-play" with Owl since  it is a low priority and Owl is not really designed to run skipper CCDs.


This sequencer adds the following commands:
--------------------------------------------

SAT: Select amplifier type. 0 for skipper and 1 for DES. 

SSR: Set skipper repeat. How many times do you want to repeat a skipper measurement?

VDR: V-clock direction. 0 for 1->2->3 and 1 for 3->2->1

HDR: H-clock direction. 0 for 1->2->3 and 1 for 3->2->1. Do this AFTER you select amplifier using SOS

CIT: Change Integration Time. The second variable needs to be what "I_DELAY" used to be before. Use idelayvar.sh to calculate this and make sure to check "hexadecimal values". Try C00000 as default for DES CCDs.

STC: Set the number of columns to read. You will HAVE to set this before you attempt a readout, since the default value is 0. With that default value, you wont see any images!

CPR: Change pedestal relaxation time. This is the time it waits before starting the pedestal integration. Again, just like CIT, use idelayvar.sh to calculate this.

CPO: Change signal relaxation time. This is the time it waits before starting the signal integration. Use idelayvar.sh to calculate this.

The last two may be adjusted to get a lower noise.

--------------------------------------------

Send comments to Pitam Mitra at pitamm@uw.edu

Enjoy.
