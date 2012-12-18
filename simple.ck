// @title simple.ck
// @author Tim O'Brien (tsob@ccrma) 
// @desc A musical swarm simulation implementation in ChucK
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 1

// @note Adapted from Craig Reynolds' original boids algorithm
// from 1986 (http://en.wikipedia.org/wiki/Boids)

// run with:
//   chuck -o4 --bufsize16384 -g../faustSTKforChucK/tibetanBowl.chug -g../faustSTKforChucK/blowHole.chug DBAP4.ck simple.ck > output.dat
// or  ./simple.sh


//----------------------------------
// Vars

17	 => int n;   // number of dimensions
1.0 => float dimLim;              // max position val for each dimension
dimLim/10.0 => float bVisionLimit; // boid vision for collision avoidance

20 => int updateTime; //in ms
20 * updateTime => int minIOI; //in ms
100 * updateTime => int maxIOI; //in ms

5.0 => float attraction; // attraction factor

//----------------------------------
// Startup

Boid boids[4];                   //instantiate boids
Attractor attractors[1];         //instantiate attractors
randomizeBoids(boids);           //randomize boid positions
//randomizeAttractors(attractors); //randomize attractor positions


//----------------------------------
// Main score

spork ~ attractorScore(attractors);

swarmloop(boids, attractors, 9000);
5::second => now;

//---------SWARM-FUNCTIONS-------------------------------------------

fun void swarmloop( Boid boids[], Attractor attractors[], int steps )
{
    0 => int step;
    0.0 => float noteTime;

    while( step < steps )
    {
        updateTime::ms => now;
        moveBoids(boids, attractors);

        if( noteTime < updateTime*step)
        {
            makeSound( centroid(boids) ) +=> noteTime;
        }

        1 +=> step;
    }
}

fun float[] centroid( Boid boids[] )
{
    float centroidVal[n];
    for ( 0 => int i; i < n; i++ )
    {
        0.0 => centroidVal[i];
        for ( 0 => int j; j < boids.cap(); j++ )
        {
            boids[j].position[i] +=> centroidVal[i];
        }
        boids.cap() /=> centroidVal[i];
        Math.min(1.0,Math.max(0.0,centroidVal[i])) => centroidVal[i];
    }
    return centroidVal;
}

fun float makeSound( float centroidVal[] )
{
    float val[n];
    for(0 => int i; i<n; i++) 
    {
        centroidVal[i] => val[i];
    }

    centroidVal[n-1] => float ioi;

    ( ioi  * (maxIOI - minIOI) )  + minIOI  => ioi;
    
    centroidVal[n-2] => float instFNum;
    //centroidVal[n-3] => float tonicNum;
    48 => float tonicNum;
    centroidVal[n-4] => float scaleFNum;

    Math.floor( instFNum * 6 ) => instFNum;

    instFNum $ int => int instNum;

    tonicNum * 16 => tonicNum;
    Math.floor( scaleFNum * 6 ) $ int => int scaleNum;


    chout <= now/second <= " " <= centroidVal[0] <= " " <= centroidVal[1] <= " " <= centroidVal[2] <= " " <= instFNum <= IO.newline();
//<= centroidVal[3] <= " " <= centroidVal[4] <= " " <= centroidVal[5] <= " " <= centroidVal[6] <= " " <= centroidVal[7] <= " " <= centroidVal[8] <= " " <= centroidVal[9] <= " " <= centroidVal[10]

    if(instNum==0)
    {
        spork ~ bowlSmack( val[0], val[1], val[2], val[3], val[4], val[5], val[6], scaleNum, tonicNum );
    }
    else if(instNum==1)
    {
        spork ~ blowBot( val[0], val[1], val[2], val[3], val[4], val[5], scaleNum, tonicNum );
    }
    else if(instNum==2)
    {
        spork ~ bower( val[0], val[1], val[2], val[3], val[4], val[5], val[6], val[7], val[8], scaleNum, tonicNum );
    }
    else if(instNum==3)
    {
        spork ~ holeBlow( val[0], val[1], val[2], val[3], val[4], val[5], val[6], val[7], val[8], val[9], val[10], val[11], scaleNum, tonicNum );
    }
    else if(instNum==4)
    {
        spork ~ sax( val[0], val[1], val[2], val[3], val[4] );
    }
    else if(instNum==5)
    {
        spork ~ monster( val[0], val[1], val[2], val[3], val[4] );
    }

    return ioi;
}

//---ATTRACTOR-SCORE--------------------------------------------------------------------------------------

fun void attractorScore( Attractor attractors[] )
{
    for ( 0 => int k; k<18; k++)
    {
        for ( 0=> int j; j < attractors.cap(); j++ )
        {
            for ( 0=> int i; i < n; i++ )
           {
               Std.rand2f(0.0,1.0) => attractors[j].position[i];
           }
        Math.sin(2.0 * pi * (k$float)/18.0) => attractors[j].position[n-1]; //ioi
        (k % 6) => attractors[j].position[n-2]; //instrument
        }
        10::second => now;
    }

    5::second => now;
}

//---SYNTHS-----------------------------------------------------------------------------------------------

fun void blowBot( float freq, float amp, float dur, float lrPan, float frPan,
                  float noiseGain, int scaleNum, float tonicNum )
{
    40.0 => float minFreq;
    70.0 => float maxFreq;
    0.5 => float minAmp;
    1.0 => float maxAmp;
    minIOI => int minDur; //in ms
    maxIOI => int maxDur; //in ms

    noiseGain*(0.7) + 0.3 => noiseGain;
    freq*(maxFreq - minFreq) + minFreq => freq;
    amp *(maxAmp - minAmp)   + minAmp  => amp;
    dur *(maxDur - minDur)   + minDur  => dur;
    3.0 *=> dur;
    2.0 *=> lrPan;
    2.0 *=> frPan;
    1.0 -=> lrPan;
    1.0 -=> frPan;

    BlowBotl bottle => LPF lpf => Gain g => Envelope env => JCRev rev => DBAP4 spks;

    spks.setPosition(frPan,lrPan);
    g.gain(0.2);
    rev.mix(0.7);
    1.0 => env.value;


    Std.mtof(scaleMidi(freq,tonicNum,scaleNum)) => freq;
    freq => lpf.freq;
    1.0 => lpf.Q;
    freq => bottle.freq;
    freq*Std.rand2(1,3)/Std.rand2(1,3) => bottle.vibratoFreq;
    1.0 => bottle.vibratoGain;
    bottle.volume(amp);
    bottle.noiseGain(noiseGain);

    bottle.startBlowing(1.0);

    dur*0.9::ms => env.duration;

    env.target(0.0);    

    dur::ms => now;

    bottle.stopBlowing(1.0);
}

fun void bowlSmack( float freq, float amp, float dur, float lrPan, float frPan,
                    float modType, float nonlinearity, int scaleNum, float tonicNum )
{
    42.0 => float minFreq;
    80.0 => float maxFreq;
    0.1 => float minAmp;
    0.5 => float maxAmp;
    minIOI => int minDur; //in ms
    maxIOI => int maxDur; //in ms

    freq*(maxFreq - minFreq) + minFreq => freq;
    amp *(maxAmp - minAmp)   + minAmp  => amp;
    dur *(maxDur - minDur)   + minDur  => dur;
    //2.0 *=> dur;
    2.0 *=> lrPan;
    2.0 *=> frPan;
    1.0 -=> lrPan;
    1.0 -=> frPan;

    
    Tibetan_Bowl bowl => Envelope env => DBAP4 spks;

    spks.setPosition(frPan,lrPan);
    1.0 => env.value;
    1 => bowl.Excitation_Selector; //1=hit,0=bow
    Math.round(modType * 4) $ int => bowl.Modulation_Type;
    nonlinearity / 16.0 => bowl.Nonlinearity;
    Std.mtof(scaleMidi(freq,tonicNum,scaleNum)) => bowl.freq;
    1.0 => bowl.gate;
    amp*0.2 => bowl.gain;

    dur::ms => now;

    env.duration(dur::ms);
    env.target(0.0);

    (2*dur)::ms => now;
}

fun void holeBlow( float freq, float amp, float dur, float lrPan, float frPan,
                   float modType, float nonlinearity, float vibratoFreq,
                   float vibratoGain, float vibratoAttack, float vibratoRelease, float nlAttack,
                   int scaleNum, float tonicNum )
{
    30.0 => float minFreq;
    60.0 => float maxFreq;
    0.1 => float minAmp;
    0.5 => float maxAmp;
    minIOI => int minDur; //in ms
    maxIOI => int maxDur; //in ms

    freq*(maxFreq - minFreq) + minFreq => freq;
    amp *(maxAmp - minAmp)   + minAmp  => amp;
    dur *(maxDur - minDur)   + minDur  => dur;
    //2.0 *=> dur;
    2.0 *=> lrPan;
    2.0 *=> frPan;
    1.0 -=> lrPan;
    1.0 -=> frPan;
    
    /*
    Reed_Stiffness
    Tone_Hole_Openness
    Vent_Openness
    Noise_Gain 
    Pressure 
    Modulation_Frequency
    Nonlinearity_Attack
    */
    
    BlowHole hole => Envelope env => DBAP4 spks;

    spks.setPosition(frPan,lrPan);
    1.0 => env.value;

    Math.round(modType * 4) $ int => hole.Modulation_Type;
    nonlinearity / 16.0 => hole.Nonlinearity;
    Std.mtof(scaleMidi(freq,tonicNum,scaleNum)) => hole.freq;
    1.0 => hole.gate;
    amp => hole.gain;
    nlAttack * 2.0 => hole.Nonlinearity_Attack;

    vibratoFreq * 6.0 + 3.0 => hole.Vibrato_Freq;
    vibratoGain / 20.0 => hole.Vibrato_Gain;

    dur::ms => now;

    env.duration(dur::ms);
    env.target(0.0);

    (2*dur)::ms => now;
}

fun void bower( float freq, float amp, float dur, float lrPan, float frPan,
                float bowPressure, float bowPosition, float vibratoFreq,
                float vibratoGain, int scaleNum, float tonicNum )
{
    40.0 => float minFreq;
    72.0 => float maxFreq;
    0.1 => float minAmp;
    0.5 => float maxAmp;
    minIOI => int minDur; //in ms
    maxIOI => int maxDur; //in ms

    freq*(maxFreq - minFreq) + minFreq => freq;
    amp *(maxAmp - minAmp)   + minAmp  => amp;
    dur *(maxDur - minDur)   + minDur  => dur;
    //2.0 *=> dur;
    2.0 *=> lrPan;
    2.0 *=> frPan;
    1.0 -=> lrPan;
    1.0 -=> frPan;

    
    Bowed bow => Envelope env => DBAP4 spks;

    spks.setPosition(frPan,lrPan);
    1.0 => env.value;
    
    Std.mtof(scaleMidi(freq,tonicNum,scaleNum)) => bow.freq;
    bowPressure => bow.bowPressure;
    bowPosition => bow.bowPosition;
    vibratoFreq * 6.0 + 2.0 => bow.vibratoFreq;
    vibratoGain / 20.0 => bow.vibratoGain;
    
    1.0 => bow.startBowing;
    amp => bow.volume;

    dur::ms => now;

    env.duration(dur::ms);
    env.target(0.0);

    (2*dur)::ms => now;
}


fun void monster( float rate, float amp, float lrPan, float frPan, float sampleNum )
{
    string filename[11];

    me.sourceDir() + "/child/" => string pathname;
    pathname + "monster2.wav" => filename[0];
    pathname + "kangaroo.wav" => filename[1];
    pathname + "murcs.wav" => filename[2];
    pathname + "thatsthephone.wav" => filename[3];
    pathname + "ears.wav" => filename[4];
    pathname + "ears.wav" => filename[5];
    pathname + "trousers.wav" => filename[6];
    pathname + "cupoftea.wav" => filename[7];
    pathname + "banana.wav" => filename[8];
    pathname + "bear.wav" => filename[9];
    pathname + "alldone.wav" => filename[10];

    Math.floor(sampleNum * filename.cap()) $ int => int sampIndex;

    swarmBufPlayer( rate, amp, lrPan, frPan, filename[sampIndex] );
}

fun void sax( float rate, float amp, float lrPan, float frPan, float sampleNum )
{
    string filename[10];

    me.sourceDir() + "/sax/" => string pathname;
    pathname + "a3.wav" => filename[0];
    pathname + "gb2-v127.wav" => filename[1];
    pathname + "eb3-v115.wav" => filename[2];
    pathname + "c3.wav" => filename[3];
    pathname + "eb2-v127.wav" => filename[4];
    pathname + "gb3-v115.wav" => filename[5];
    pathname + "a2.wav" => filename[6];
    pathname + "gb4-v95.wav" => filename[7];
    pathname + "a4.wav" => filename[8];
    pathname + "c3_dirty.wav" => filename[9];
    
    Math.floor(sampleNum * filename.cap()) $ int => int sampIndex;

    3.0 /=> amp;

    swarmBufPlayer( rate, amp, lrPan, frPan, filename[sampIndex] );
}


fun void swarmBufPlayer( float rate, float amp, float lrPan, float frPan, string filename )
{
    2.0 *=> lrPan;
    2.0 *=> frPan;
    1.0 -=> lrPan;
    1.0 -=> frPan;
    SndBuf buf => DBAP4 spks;
    spks.setPosition(frPan,lrPan);
    filename => buf.read;
    0 => buf.pos;
    amp => buf.gain;
    (rate*0.5)+0.75	 => rate;
    rate => buf.rate;
    (buf.samples()$float / rate)::samp => dur waitTime;
    waitTime => now;
}


//---------MORE-FUNCTIONS------------------------------------------

fun float scaleMidi( float midiNote, float midiTonic, int scaleNum )
{

    int scale[];
    if (scaleNum == 0)
    {
        // 0: pentatonic
        [ 0, 3, 5, 7, 10 ] @=> scale;
    }
    else if (scaleNum == 1)
    {    // 1: symmetric diminished
        [0, 1, 3, 4, 6, 7, 9, 10] @=> scale;
    }
    else if (scaleNum == 2)
    {    // 2: major
        [0, 2, 4, 5, 7, 9, 11] @=> scale;
    }
    else if (scaleNum == 3)
    {    // 3: minor (aeolian)
        [0, 2, 3, 5, 7, 8, 10] @=> scale;
    }
    else if (scaleNum == 4)
    {    // 4: harmonic minor
        [0, 2, 3, 5, 7, 8, 11] @=> scale;
    }
    else
    {   //pentatonic
        [ 0, 2, 4, 7, 9 ] @=> scale;
    }

    (midiTonic-3.0) % 15.0 => midiTonic;
    48.0 +=> midiTonic;

    Math.floor((midiNote - midiTonic) / 15.0) => float baseOctave;
    (midiNote - 3.0) % 15.0 => float pitchClass;

    Math.floor( pitchClass * scale.cap() / 15.0 ) => float scaleDegree;

    scale[scaleDegree$int] => float scalePitch;

    return (midiTonic + (baseOctave*15.0) + scalePitch);
}



//randomly position all boids in a boid[] array
fun void randomizeBoids( Boid boids[] )
{
    for ( 0=> int j; j < boids.cap(); j++ )
    {
        boids[j].randPos();
    }
}

//randomly position all attractors in an attractor[] array
fun void randomizeAttractors( Attractor attractors[] )
{
    for ( 0=> int j; j < attractors.cap(); j++ )
    {
        attractors[j].randPos();
    }
}

//move swarm 1 step based on calculated velocities
fun void moveBoids( Boid boids[], Attractor attractors[] )
{
    for ( 0=> int j; j < boids.cap(); j++ )
    {
        boids[j].move(boids, attractors);
    }
}




//---------------------------------------------------------------------------
//-SWARM-SIMULATION----------------------------------------------------------

//---------------------------------------------------------------------------
//-----BOID-CLASS------------------------------------------------------------
class Boid
{
    1.5 => float avoidanceFactor;      // scale of collision avoidance force

    float position[n];
    float velocity[n];

    // randomly position boid
    fun void randPos()
    {
        for ( 0=> int i; i < position.cap(); i++ ){
            Std.rand2f(0.0,dimLim) => position[i];
        }
    }
    
    fun void move( Boid boids[], Attractor attractors[] )
    {
        for ( 0=> int i; i < position.cap(); i++ ){
            updateVel(boids, attractors)[i] + position[i] => position[i];
            position[i] % dimLim => position[i];
        }
    }

    fun float[] updateVel( Boid boids[], Attractor attractors[] )
    {
        float v1[n];
        float v2[n];
        float v4[n];
        float tempV[n];
        rule1(boids) @=> v1;
        rule2(boids) @=> v2;
        rule4(attractors) @=> v4;
        for ( 0=> int i; i < v1.cap(); i++ ){
            v1[i] + v2[i] + v4[i] => tempV[i];
        }
        return tempV;
    }

    fun float[] rule1( Boid boids[] )
    {
        //clumping (attraction to swarm centroid)
        float vector1[n]; //for clumping
        for ( 0=> int j; j < vector1.cap(); j++ ) {0.0=>vector1[j];}
        //iterate over boids
        for ( 0=> int j; j < boids.cap(); j++ )
        {
            //iterate over dimensions
            for ( 0=> int i; i < position.cap(); i++ )
            {
                vector1[i] + (boids[j].position[i] - position[i]) => vector1[i];
            }
        }
        //divide by total number of boids to get average
        for ( 0=> int i; i < vector1.cap(); i++ )
        {
            vector1[i] / ( boids.cap() - 1 ) => vector1[i];
        }
        return vector1;
    }

    fun float[] rule2( Boid boids[] )
    {
        //avoidance (try to avert boid collisions):
        float vector2[n];
        for ( 0=> int j; j < vector2.cap(); j++ ) {0.0=>vector2[j];}
        //iterate over boids
        for ( 0=> int j; j < boids.cap(); j++ )
        {
            //iterate over dimensions
            for ( 0=> int i; i < position.cap(); i++ )
            {
                if ( (Std.fabs( position[i] - boids[j].position[i] ) < bVisionLimit) && (Std.fabs( position[i] - boids[j].position[i] ) != 0.0) )
                {
                    vector2[i] + ( position[i] - boids[j].position[i] ) => vector2[i];
                }
            }
        }
        return vector2;
    }

    //NOTE: NO rule3 BECAUSE WE DON'T IMPOSE VELOCITY MATCHING/SCHOOLING

    fun float[] rule4( Attractor attractors[] )
    {
        //attractors
        float vector4[n];
        for ( 0=> int j; j < vector4.cap(); j++ ) {0.0=>vector4[j];}
        //iterate over attractors
        for ( 0=> int j; j < attractors.cap(); j++ )
        {
            //iterate over dimensions
            for ( 0=> int i; i < position.cap(); i++ )
            {
                vector4[i] + (attractors[j].position[i] - position[i])*attraction => vector4[i];
            }
        }
        return vector4;
    }
}

//-----ATTRACTOR-CLASS------------------------------------------
class Attractor
{
    float position[n];
    
    // randomly position attractor
    fun void randPos()
    {
        for ( 0=> int i; i < position.cap(); i++ )
        {
            Std.rand2f(0.0,dimLim) => position[i];
        }
    }
}
