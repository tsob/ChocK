declare name "BlowHole";
declare description "Nonlinear WaveGuide Clarinet with one register hole and one tonehole";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A clarinet model, with the addition of a two-port register hole and a three-port dynamic tonehole implementation, as discussed by Scavone and Cook (1998). In this implementation, the distances between the reed/register hole and tonehole/bell are fixed.  As a result, both the tonehole and register hole will have variable influence on the playing frequency, which is dependent on the length of the air column.  In addition, the highest playing freqeuency is limited by these fixed lengths.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Woodwinds.html";

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq",440,20,20000,1);
gain = nentry("gain",1,0,1,0.01); 
gate = button("gate");

reedStiffness = hslider("Reed_Stiffness",0.35,0,1,0.01);
toneHoleOpenness = hslider("Tone_Hole_Openness",0.12,0,1,0.01);
ventOpenness = hslider("Vent_Openness",0,0,1,0.01);
noiseGain = hslider("Noise_Gain",0,0,1,0.01);
pressure = hslider("Pressure",0.35,0,1,0.01);

typeModulation = nentry("Modulation_Type",0,0,4,1);
nonLinearity = hslider("Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("Modulation_Frequency",220,20,1000,0.1);
nonLinAttack = hslider("Nonlinearity_Attack",0.1,0,2,0.01);

vibratoFreq = hslider("Vibrato_Freq",5,1,15,0.1);
vibratoGain = hslider("Vibrato_Gain",0.1,0,1,0.01);
vibratoAttack = hslider("Vibrato_Attack",0.5,0,2,0.01);
vibratoRelease = hslider("Vibrato_Release",0.01,0,2,0.01);

envelopeAttack = hslider("Envelope_Attack",0.01,0,2,0.01);
envelopeDecay = hslider("Envelope_Decay",0.05,0,2,0.01);
envelopeRelease = hslider("Envelope_Release",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order (problem with compilation time if order is bigger than 2)
nlfOrder = 2; 

//attack - sustain - release envelope for nonlinearity (declared in instrument.lib)
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),envelopeMod,freq,
     typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//reed table parameters
reedTableOffset = 0.7;
reedTableSlope = -0.44 + (0.26*reedStiffness);

//the reed function is declared in instrument.lib
reedTable = reed(reedTableOffset,reedTableSlope);

// Calculate the initial tonehole three-port scattering coefficient
rb = 0.0075;    // main bore radius
rth = 0.003;    // tonehole radius
scattering = pow(rth,2)*-1 / (pow(rth,2) + 2*pow(rb,2));

// Calculate register hole filter coefficients
r_rh = 0.0015; 	// register vent radius
teVent = 1.4*r_rh;	 // effective length of the open hole
xi = 0 ; 	// series resistance term
zeta = 347.23 + 2*PI*pow(rb,2)*xi/1.1769;
psi = 2*PI*pow(rb,2)*teVent/(PI*pow(r_rh,2));
rhCoeff = (zeta - 2*SR*psi)/(zeta + 2*SR*psi);
rhGain = -347.23/(zeta + 2*SR*psi);
ventFilterGain = rhGain*ventOpenness;

// Vent filter
ventFilter = *(ventFilterGain) : poleZero(1,1,rhCoeff);

teHole = 1.4*rth; // effective length of the open hole
coeff = (teHole*2*SR - 347.23)/(teHole*2*SR + 347.23);
scaledCoeff = (toneHoleOpenness*(coeff - 0.9995)) + 0.9995;

//register hole filter using a poleZero filter (declared in instrument.lib)
toneHoleFilter = *(1) : poleZero(b0,-1,a1)
	with{
		b0 = scaledCoeff;
		a1 = -scaledCoeff;
	};

//reflexion filter is a one zero filter (delcred in instrument.lib)
reflexionFilter = oneZero0(0.5,0.5)*-0.95;

//delay lengths in number of samples
delay0Length = 5*SR/22050;
delay2Length = 4*SR/22050;
delay1Length = (SR/freq*0.5 - 3.5) - (delay0Length + delay2Length) - (nlfOrder*nonLinearity)*(typeModulation < 2);

//fractional delay lines
delay0 = fdelay(4096,delay0Length);
delay1 = fdelay(4096,delay1Length);
delay2 = fdelay(4096,delay2Length);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//----------------------- Algorithm implementation ----------------------------

//envelope(ADSR) + vibrato + noise
envelope = (0.55 + pressure*0.3)*asr(pressure*envelopeAttack,100,pressure*envelopeRelease,gate);
vibratoEnvelope = envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);
vibrato = vibratoGain*osc(vibratoFreq)*vibratoEnvelope;
breath = envelope + envelope*noiseGain*noise;
breathPressure = breath + (breath*vibrato);

//two-port junction scattering for register vent
twoPortJunction(portB) = (pressureDiff : ((_ <: breathPressure + *(reedTable)) <: (+(portB) : ventFilter <: +(portB),_),_))~
		delay0 : inverter : + ,_
	with{
		pressureDiff = -(breathPressure); 
		inverter(a,b,c) = b,c,a;
	};

//three-port junction scattering (under tonehole)
threePortJunction(twoPortOutput) =  (_ <: junctionScattering(twoPortOutput),_ : +(twoPortOutput), + : 
		reflexionFilter,_)~delay2 : !,_
	with{
		toneHole(temp,portA2,portB2) = (portA2 + portB2-_ + temp : toneHoleFilter)~_;
		junctionScattering(portA2,portB2) = (((portA2+portB2-2*_)*scattering) <: toneHole(_,portA2,portB2),_,_)~_ : !,_,_;
	};

process = (twoPortJunction : threePortJunction,_) ~ (delay1 : NLFM) : !,*(gain)*1.5 : stereo : instrReverb;

