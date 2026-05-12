import("stdfaust.lib");

/* 
MusiqHub Bloom v0.6

The one you hear in promotional videos is processed more in FL Studio, But this is the raw sound. 

Also there are a couple options for final chords. But in our branding I combined both Fmaj9 and Gsus9, in the final version in FL.

another thing is the cutoff of the sound does not occur in this. That was done in FL.

the sparkle was used in one of the final recordings before combining them. I think it was the Fmaj9 but I can't remember. 
The other was a non sparkle version.

Written by @blvd - 2026 
*/

play = checkbox("Play");

master  = hslider("Master", 0.72, 0, 1, 0.01);
dur     = hslider("Duration[unit:s]", 5.2, 2, 10, 0.1);
sparkle = hslider("Sparkle", 0.78, 0, 1, 0.01);

// 0 = Fmaj9-ish
// 1 = Dm9
// 2 = Am7/add9
// 3 = Cmaj9
// 4 = Gsus/add9
chord = nentry(
    "Final Chord[style:menu{'Fmaj9':0;'Dm9':1;'Am7add9':2;'Cmaj9':3;'Gsus9':4}]",
    0, 0, 4, 1
);

// timeline
step = 1.0 / (dur * ma.SR);
t = +(step * play) ~ _ : min(1) : *(play);

curve(x) = x * x * (3 - 2 * x);
late(pos) = max(0, (t - pos) / (1 - pos)) : min(1);
hit(pos, sharp) = max(0, 1 - abs((t - pos) * sharp));

softclip(x) = ma.tanh(x);

// chord selector helper
sel(a, b, c, d, e) =
    (chord == 0) * a +
    (chord == 1) * b +
    (chord == 2) * c +
    (chord == 3) * d +
    (chord == 4) * e;

// final chord notes
n1 = sel(1046.50, 1174.66, 880.00, 1046.50, 783.99);
n2 = sel(1318.51, 1396.91, 1046.50, 1234.91, 1174.66);
n3 = sel(1567.98, 1760.00, 1318.51, 1567.98, 1567.98);
n4 = sel(1760.00, 2093.00, 1567.98, 1760.00, 1760.00);

// base notes
F3 = 174.61;
A3 = 220.00;
C4 = 261.63;
E4 = 329.63;
G4 = 392.00;
A4 = 440.00;
C5 = 523.25;
D5 = 587.33;
E5 = 659.25;
G5 = 783.99;
A5 = 880.00;
C6 = 1046.50;
D6 = 1174.66;
E6 = 1318.51;
G6 = 1567.98;

// glide
glide(start, target, skew) =
    start * pow(target / start, curve(pow(t, skew)));

// voice
voice(start, target, amp, pan, skew) =
    (
        os.osc(glide(start, target, skew)) * 0.82 +
        os.osc(glide(start * 2.002, target * 2.0, skew)) * 0.12
    )
    * amp
    * curve(t)
    : fi.highpass(1, 120)
    : fi.lowpass(2, 5000 + 8000 * sparkle)
    : sp.panner(pan);

// cloud
cloud =
    voice(310,  F3, 0.026, 0.12, 1.15),
    voice(620,  A3, 0.023, 0.88, 0.95),
    voice(440,  C4, 0.022, 0.25, 1.30),
    voice(780,  E4, 0.020, 0.72, 0.85),
    voice(530,  G4, 0.018, 0.45, 1.10),
    voice(980,  A4, 0.016, 0.65, 1.25),
    voice(720,  C5, 0.014, 0.18, 0.90),
    voice(1180, E5, 0.012, 0.82, 1.40)
    :> _,_;

// bell
bell(freq, pos, amp, pan) =
    (
        os.osc(freq) * 0.78 +
        os.osc(freq * 2.01) * 0.18 +
        os.osc(freq * 3.99) * 0.06
    )
    * hit(pos, 32)
    * amp
    : fi.highpass(1, 900)
    : fi.lowpass(2, 13000)
    : sp.panner(pan);

// arp
arp =
    bell(C5, 0.15, 0.050, 0.20),
    bell(E5, 0.27, 0.046, 0.70),
    bell(G5, 0.39, 0.044, 0.42),
    bell(A5, 0.51, 0.040, 0.82),
    bell(C6, 0.64, 0.050, 0.30),
    bell(D6, 0.74, 0.042, 0.62),
    bell(E6, 0.84, 0.052, 0.44),
    bell(G6, 0.92, 0.035, 0.76)
    :> _,_;

// arrival
arrival = late(0.62) : curve;

// high glow
highGlow =
    (
        os.osc(n1 * 0.5) * 0.18 +
        os.osc(n1) * 0.26 +
        os.osc(n2) * 0.22 +
        os.osc(n3) * 0.18 +
        os.osc(n4) * 0.13 +
        os.osc(n1 * 2.0) * 0.08 +
        os.osc(n2 * 2.0) * 0.06
    )
    * arrival
    * 0.18
    : fi.highpass(1, 120)
    : fi.lowpass(2, 14000)
    <: _,_;

// sweep
sweep =
    no.noise
    : fi.highpass(2, 1800 + 9000 * curve(t))
    : fi.lowpass(2, 15000)
    : *(0.020 * sparkle * curve(t))
    <: _,_;

// impact
impact = late(0.76) : curve;

// sub
subRise =
    (
        os.osc(F3 * 0.25) * 0.75 +
        os.osc(F3 * 0.5) * 0.35 +
        os.osc(F3) * 0.18
    )
    * impact
    * 0.18
    : fi.lowpass(2, 140)
    <: _,_;

// impact noise
impactNoise =
    no.noise
    * hit(0.82, 10)
    * 0.035
    : fi.lowpass(2, 900)
    <: _,_;

// mix
dry =
    cloud,
    arp,
    highGlow,
    sweep,
    subRise,
    impactNoise
    :> _,_;

// output
process =
    dry
    : softclip, softclip
    : *(master), *(master);