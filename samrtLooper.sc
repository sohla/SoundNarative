(
var winenv;
//var dir = PathName.new("~/Music/SCSamples/ding.wav");
var dir = PathName.new("~/Music/SCSamples/iAmWatchingYou.wav");
// var dir = PathName.new("~/Music/SCSamples/final_chord.wav");
//var dir = PathName.new("~/Music/SCSamples/ClosingSynth.aif");




winenv = Env([0, 1, 0], [0.5, 0.05],[-8,-8]);

b = Buffer.read(s, dir.asAbsolutePath);
z = Buffer.sendCollection(s, winenv.discretize, 1);

SynthDef(\warp, {|buffer = 0, envbuf = -1, ratio = 1, ws = 0.1, ol = 1, rr = 0.0|
    var out, pointer, filelength, pitch, dur;

	dur = BufDur.kr(buffer);

    pointer = 0.0;

    pitch = 1;

    out = Warp1.ar(2, buffer, pointer, pitch, dur * ratio, envbuf, ol, rr, 2);

    Out.ar(0, out);
}).send(s);

)

// use built-in env
x = Synth(\warp, [\buffer, b, \envbuf, z])
x.set(\ratio, 0.25);
x.set(\ol, 4);

x.set(\ws, 1.5);
x.set(\rr, 0);



// switch to the custom env
x.set(\envbuf, z)
x.set(\envbuf, -1);

x.free;

s.plotTree