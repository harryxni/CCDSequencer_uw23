#!/bin/sh

#########################################################
#This script converts a given timing window
#into a hex value that the leach system takes
#that dictates the timing of a certain instruction.
#
#Most people will use this script to calculate the I_DELAY
#variable. However you can use this for all the other delay
#variables too.
#
#Written by Pitam Mitra on Feb 7, 2019.
#pitamm@uw.edu
#License: GPL v3.
#########################################################


#First, convert number to ns. The ($var+0.5)/1 converts float to an int
TIMING_NS=$(bc <<< "($1*1000+0.5)/1")

#If the number is > 5us, always use 640ns intervals
if [ "$TIMING_NS" -gt 4000 ];
then
TIMING_BIGMULT=$(( TIMING_NS/640 | 0x80))
HEX_BIGMULT=$(bc -l <<< "obase=16;$TIMING_BIGMULT")

echo "Please use the line: "
echo "I_DELAY 	EQU     $"$HEX_BIGMULT"0000"

else
#if between 640ns and 40ns, 640 is a closer match, then use that
BIGREMINDER=$(( TIMING_NS % 640 > 320 ? 640-TIMING_NS % 640 : TIMING_NS % 640 ))
LITTLEREMINDER=$(( TIMING_NS % 40 > 20 ? 40-TIMING_NS % 40 : TIMING_NS % 40 ))
if (( BIGREMINDER <= LITTLEREMINDER ));
then
TIMING_BIGMULT=$(( TIMING_NS/640 | 0x80))
HEX_BIGMULT=$(bc -l <<< "obase=16;$TIMING_BIGMULT")

echo "Please use the line: "
echo "I_DELAY 	EQU     $"$HEX_BIGMULT"0000"
else
#use 40ns timing scale
TIMING_LITTLEMULT=$(( TIMING_NS/40 ))
HEX_LITTLEMULT=$(bc -l <<< "obase=16;$TIMING_LITTLEMULT")

echo "Please use the line: "
echo "I_DELAY 	EQU     $"$HEX_LITTLEMULT"0000"
fi
fi
