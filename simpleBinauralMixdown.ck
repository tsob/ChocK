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



Binaural4 b4;

// load you audio files
SndBuf buf[4];

// NOTE: set your path here otherwise the VM will fail you.
me.sourceDir() + "/1_output.wav" => buf[0].read;
me.sourceDir() + "/2_output.wav" => buf[1].read;
me.sourceDir() + "/3_output.wav" => buf[2].read;
me.sourceDir() + "/4_output.wav" => buf[3].read;

// writing signals to files...
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/left_binaural.wav" => string _captureL;
me.sourceDir() + "/right_binaural.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;


for(0 => int i; i < 4; ++i) {
    buf[i] => b4.input[i];
}

3.2::minute => now;


// ------------------------------------------------------------
// finish the show
leftOut.closeFile();
rightOut.closeFile();
// print message in terminal for sox command
cherr <= "\n[score] Finished.\nMerge two products with the command below.\n\n";
cherr <= "sox -M " <= _captureL <= " " <= _captureR <= " ";
cherr <= me.sourceDir() + "/FinalBinaural.wav\n\n";
