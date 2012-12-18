declare name "BlowBottle";
declare description "Blown Bottle Instrument";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This object implements a helmholtz resonator (biquad filter) with a polynomial jet excitation (a la Cook).";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq",440,20,20000,1);
gain = nentry("gain",1,0,1,0.01); 
gate = button("gate");

noiseGain = hslider("Noise_Gain",0.5,0,1,0.01)*2;
pressure = hslider("Pressure",1,0,1,0.01);

typeModulation = nentry("Modulation_Type",0,0,4,1);
nonLinearity = hslider("Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("Modulation_Frequency",220,20,1000,0.1);
nonLinAttack = hslider("Nonlinearity_Attack",0.1,0,2,0.01);

vibratoFreq = hslider("Vibrato_Freq",5,1,15,0.1);
vibratoGain = hslider("Vibrato_Gain",0.1,0,1,0.01);
vibratoBegin = hslider("Vibrato_Begin",0.05,0,2,0.01);
vibratoAttack = hslider("Vibrato_Attack",0.5,0,2,0.01);
vibratoRelease = hslider("Vibrato_Release",0.01,0,2,0.01);

envelopeAttack = hslider("Envelope_Attack",0.01,0,2,0.01);
envelopeDecay = hslider("Envelope_Decay",0.01,0,2,0.01);
envelopeRelease = hslider("Envelope_Release",0.5,0,2,0.01);


//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//attack - sustain - release envelope for nonlinearity (declared in instrument.lib)
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),envelopeMod,freq,
typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//botlle radius
bottleRadius = 0.999;

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

bandPassFilter = bandPass(freq,bottleRadius);

//----------------------- Algorithm implementation ----------------------------

//global envelope is of type attack - decay - sustain - release
envelopeG =  gain*adsr(gain*envelopeAttack,envelopeDecay,80,envelopeRelease,gate);

//pressure envelope is also ADSR
envelope = pressure*adsr(gain*0.02,0.01,80,gain*0.2,gate);

//vibrato
vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);

//breat pressure
breathPressure = envelope + vibrato;

//breath noise
randPressure = noiseGain*noise*breathPressure ;

process = 
	//differential pressure
	(-(breathPressure) <: 
	((+(1))*randPressure : +(breathPressure)) - *(jetTable),_ : bandPassFilter,_)~NLFM : !,_ : 
	//signal scaling
	dcblocker*envelopeG*0.5 : stereo : instrReverb;

