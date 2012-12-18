declare name "Glass Harmonica";
declare description "Nonlinear Banded Waveguide Modeled Glass Harmonica";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This instrument uses banded waveguide. For more information, see Essl, G. and Cook, P. Banded Waveguides: Towards Physical Modelling of Bar Percussion Instruments, Proceedings of the 1999 International Computer Music Conference.";

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq",440,20,20000,1);
gain = nentry("gain",0.8,0,1,0.01); 
gate = button("gate");

select = nentry("Excitation_Selector",0,0,1,1);
integrationConstant = hslider("Integration_Constant",0,0,1,0.01);
baseGain = hslider("Base_Gain",1,0,1,0.01);
bowPressure = hslider("Bow_Pressure",0.2,0,1,0.01);
bowPosition = hslider("Bow_Position",0,0,1,0.01);

typeModulation = nentry("Modulation_Type",0,0,4,1);
nonLinearity = hslider("Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("Modulation_Frequency",220,20,1000,0.1);
nonLinAttack = hslider("Nonlinearity_Attack",0.1,0,2,0.01);

//==================== MODAL PARAMETERS ================

preset = 3;

nMode(3) = 6;

modes(3,0) = 1.0;
basegains(3,0) = pow(0.999,1);
excitation(3,0) = 1*gain*gate/(nMode(3) - 1);

modes(3,1) = 2.32;
basegains(3,1) = pow(0.999,2);
excitation(3,1) = 1*gain*gate/(nMode(3) - 1);

modes(3,2) = 4.25;
basegains(3,2) = pow(0.999,3);
excitation(3,2) = 1*gain*gate/(nMode(3) - 1);

modes(3,3) = 6.63;
basegains(3,3) = pow(0.999,4);
excitation(3,3) = 1*gain*gate/(nMode(3) - 1);

modes(3,4) = 9.38;
basegains(3,4) = pow(0.999,5);
excitation(3,4) = 1*gain*gate/(nMode(3) - 1);

modes(3,5) = 0 : float;
basegains(3,5) = 0 : float;
excitation(3,5) = 0 : float;

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),1,freq,
typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//the number of modes depends on the preset being used
nModes = nMode(preset);

//bow table parameters
tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

delayLengthBase = SR/freq;

//delay lengths in number of samples
delayLength(x) = delayLengthBase/modes(preset,x);

//delay lines
delayLine(x) = delay(4096,delayLength(x));

//Filter bank: bandpass filters (declared in instrument.lib)
radius = 1 - PI*32/SR;
bandPassFilter(x) = bandPass(freq*modes(preset,x),radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1*baseGain);
velocityInputApp = integrationConstant;
velocityInput = velocityInputApp + _*baseGainApp,par(i,(nModes-1),(_*baseGainApp)) :> +;

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + 0.1*gain;
bowVelocity = maxVelocity*adsr(0.02,0.005,90,0.01,gate);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(delayLengthBase);

//----------------------- Algorithm implementation ----------------------------

//Bow table lookup (bow is decalred in instrument.lib)
bowing = bowVelocity - velocityInput <: *(bow(tableOffset,tableSlope)) : /(nModes);

//One resonance
resonance(x) = + : + (excitation(preset,x)*select) : delayLine(x) : *(basegains(preset,x)) : bandPassFilter(x);

process =
		//Bowed Excitation
		(bowing*((select-1)*-1) <:
		//nModes resonances with nModes feedbacks for bow table look-up 
		par(i,nModes,(resonance(i)~_)))~par(i,nModes,_) :> + : 
		//Signal Scaling and stereo
		*(4) : NLFM : stereo : instrReverb;

