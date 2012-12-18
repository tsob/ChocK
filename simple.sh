#!/bin/csh -f

chuck -o4 --bufsize16384 -g./faustSTKforChucK/tibetanBowl.chug -g../faustSTKforChucK/blowHole.chug DBAP4.ck simple.ck > output.dat
