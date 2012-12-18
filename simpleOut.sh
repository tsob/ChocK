#!/bin/csh -f

chuck -s -o4 --bufsize16384 -g./faustSTKforChucK/tibetanBowl.chug -g./faustSTKforChucK/blowHole.chug DBAP4.ck simpleOut.ck > output.dat
