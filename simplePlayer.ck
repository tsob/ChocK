// @title sampleBinauralMixdown.ck
// @author Tim O'Brien (tsob@ccrma)
// @NOTE adapted from "example-Binaural4.ck"
// @author Hongchan Choi (hongchan@ccrma) 
// @desc A simple examplary usage of Binaural4 class
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 2

// run with:
//   chuck -s --bufsize16384 Binaural4.ck simpleBinauralMixdown.ck
// or  ./simpleBinauralMixdown.sh



DBAP4 spks[4];

// load you audio files
SndBuf buf[4];

// NOTE: set your path here otherwise the VM will fail you.
me.sourceDir() + "/1_output.wav" => buf[0].read;
me.sourceDir() + "/2_output.wav" => buf[1].read;
me.sourceDir() + "/3_output.wav" => buf[2].read;
me.sourceDir() + "/4_output.wav" => buf[3].read;


for(0 => int i; i < 4; ++i) {
    buf[i] => spks[i];
}

spks[0].setPosition(1,1);
spks[1].setPosition(1,-1);
spks[2].setPosition(-1,1);
spks[3].setPosition(-1,-1);

3.2::minute => now;


