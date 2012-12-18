ChocK
=====

A native ChucK swarm simulation for musical composition.

Created by Tim O'Brien at CCRMA (Stanford's Center for Computer Research in Music and Acoustics).

More info at: https://ccrma.stanford.edu/~tsob/220a/fp.html

Code
=====
    simple.ck contains the code for a live four-channel computer performance.
    simple.sh is a script which calls simple.ck, loads the necessary chugins, and sets some useful ChucK parameters. It also pipes the Stdout data (corresponding to note times and parameter values) to output.dat.
    simpleOut.ck is the same as simple.ck, but it renders four mono wav files.
    simpleOut.sh is similar to simple.sh, but it calls simpleOut.ck in silent mode to ensure that the output wave files are rendered without any real-time-related dropouts or degradation of sound quality.
    simpleBinauralMixdown.ck takes the four mono files generated from simpleOut and renders them to two binaural wave files.
    simpleBinauralMixdown.sh simply runs simpleBinauralMixdown.ck in silent mode.
    plotOutput.m is a simple Matlab script for plotting the note data. 

    blowHole.dsp, the Faust file for the BlowHole (clarinet) physical model.
    tibetanBowl.dsp, the Faust file for the Tibetan bowl physical model.
    blowHole.chug, the compiled Chugin file for the BlowHole (clarinet) physical model.
    tibetanBowl.chug, the compiled Chugin file for the Tibetan bowl physical model.



Introduction and Motivation
=====

This project is inspired by the field of computer improvisation and the use of complex systems to simulate musical performance. Specifically, ChocK applies the swarm simulation paradigm originally developed by Reynolds [1] and subsequently applied to generative music and computer improvisation by Blackwell and Young [2].

This program, written fully in ChucK, implements Reynolds' "boids" algorithm with many of the musical applications described in [2]. However, instead of being a simulacrum of a musical improviser responding to a human performer, ChocK is built to input a meta-score based on time-varying swarm attractor elements. The output is thus the swarm simulation's rather unpredictable interpretation of the human composer's instructions.

The Swarm Simulation
=====

The swarm simulation is elegant in its simplicity. A number of swarm elements (conventionally referred to as "boids") are instantiated with random positions. As the simulation progresses, each swarm element is subject to three main forces: (1) attraction to the center of the swarm, (2) avoidance of collisions with each other boid, and (3) attraction to the "attractor" element(s). These forces are calculated for each boid at each time step (defined by an update time interval, such as 10 ms), and each boid's position is changed accordingly.

For musical considerations, we make the swarm space multidimensional. Thus the swarm's centroid value for each dimension can be used as input for an arbitrary number of musical parameters, such as pitch, loudness, duration, etc. Additionally, we apply dimensional decoupling as described in [2]. This makes sense if the dimensions correspond to different musical parameters, since we want these parameters to vary independently. This also simplifies computation, as the distances between boids are calculated for one dimension at a time and we do not have to worry about, for example, multidimensional Euclidean distance.

Swarm Sonification
=====

At the highest level, the musical output is note-based. The timing of each note proceeds from the swarm centroid value along the dimension marked for inter-onset interval calculated at the time of the previous note. Thus at every note event, the program stores the new ioi value (subject to a scaling factor to ensure minimum and maximum IOI values) and waits until that IOI duration has progressed before generating the next note.

At the next highest level, we use centroid values along another swarm dimension to choose from several instruments with which to process the note. In this program, we use physical models of a blown bottle and a cello/bowed instrument (ChucK's built-in BlowBotl and Bowed instruments, respectively); physical models of a Tibetan bowl and a clarinet based on Romain Michon's Faust STK and compiled into Chugins via faust2ck; and two players of sampled sound collections of saxophone and a child's speech (see the sampled material section below).

There are of course dimensions which we interpret in the code as corresponding to frequency (or rate), amplitude, duration (which is independent of IOI), and panning (both left/right and front/back in our 4-channel setup). For the physical models which take further inputs, we use other swarm dimensions for variables such as nonlinearity amount, nonlinearity mode, vibrato frequency/gain/attack, etc. All are scaled to ranges which are deemed suitable and desirable for the sound of each particular instrument. Additionally, we define several scales of pitches with which we quantize the frequency, and allow the swarm centroid value along a corresponding dimension to select the scale being used.

Composition
=====

In addition the the compositional choices inherent in the creation of different instruments and use of parameter minimums and maximums, we use a single attractor with positions varying over time to influence the beahvior (and thus musical output) of the swarm. The code accepts any number of attractor elements, but we chose to use a single attractor to decrease the computational load.

For this particular composition, we varied the attractor's instrument parameter by stepping from the minimum value to the maximum twice during the duration of the piece. We also varied the IOI attractor parameter as a function of the raised sine of the time, with a period equal to the length of the piece.

References
=====

[1] Craig W. Reynolds. 1987. Flocks, herds and schools: A distributed behavioral model. In Proceedings of the 14th annual conference on Computer graphics and interactive techniques (SIGGRAPH '87), Maureen C. Stone (Ed.). ACM, New York, NY, USA, 25-34. DOI=10.1145/37401.37406 http://doi.acm.org/10.1145/37401.37406

[2] Blackwell, T., & Young, M. (2004). Self-organised music. Organised Sound, 9(02). doi:10.1017/S1355771804000214
