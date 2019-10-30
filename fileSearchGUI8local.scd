
// o = Server.local.options;
// o.outDevice
// 
//
// // Post the number of output channels
//
// o.numOutputBusChannels.postln;
//
// // Set them to a new number
//
// o.numOutputBusChannels = 10; // The next time it boots, this w
//
//






(

var window, mainView,newSearchView,stackView,queryView,resultsView,waitingView,playView;
var addStack,removeStack,addResult,switchToStack;
var searchViews = [];
var stackIndexes = [\newSearchIdx,\queryIdx,\waitingIdx,\resultsIdx,\playIdx];
var dir = PathName.new("~/Music/SoundNarative/");
var fastSearch;

//var dirPath = "/Volumes/Steph2015/*".postln;
//var dirPath = "/Volumes/Steph2017/SFX/*".postln;
var dirPath = "~/Music/*";

var gainSpec = ControlSpec(0.ampdb, 12, \db, step: 0.5, default: 0.0, units: " db");
var fadeInSpec = ControlSpec(0.001, 5.0, \lin, step: 0.1, default: 1.8, units: " secs");
var fadeOutSpec = ControlSpec(0.001, 5.0, \lin, step: 0.1, default: 2.8, units: " secs");
var pitchSpec = ControlSpec(0.25, 4, \exp, step: 0.01, default: 1, units: " pitch");


s.boot;
QtGUI.palette = QPalette.dark; 


fastSearch = {|dir, fileTypes, searchString, itrFunc, completeFunc|

	// start building find command string
	var cs = ("find % \\(").format(dir);

//	var cs = ("find % -iname \"*%*\" -a \\(").format(dir,searchString);
	var data = 0;


	// itr each word in search string
	searchString.split($ ).do({|ss|
			cs = cs ++ (" -iname \"*%*\" -%").format(ss,"a");//(o)R/(a)ND
	
	});

	// add AND to then search for file extension typest
	cs = cs.copyFromStart(cs.size-3)++ " \\) -a \\(";


	// add each of the extensions in the find
	fileTypes.split($|).do({|type|type.postln;
		cs = cs ++ " -iname \"*.%\" -o".format(type);
	});
	// remove last -o and complete the command string
	cs = cs.copyFromStart(cs.size-3)++ " \\)";
	// send it off and get results, fast
	cs.postln;
	data = cs.unixCmdGetStdOutLines;
	data.do({|o,i|itrFunc.(o,i)});
	completeFunc.(data.size);

};

//------------------------------------------------------
// addStack
//------------------------------------------------------
addStack =({|index|
	var view  = stackView.(index);
	searchViews = searchViews.insert(index,view);
	{window.layout.add(searchViews[index]);}.defer;
	"addStack->".post;
	searchViews.postln;
});

//------------------------------------------------------
// removeStack
//------------------------------------------------------
removeStack =({|index|
	searchViews[index].removeAll;
	searchViews[index].remove;
	searchViews = searchViews.put(index,0);// put 0 and never use again!

	"removeStack->".post;
	searchViews.postln;
});

//------------------------------------------------------
// newSearchView
//------------------------------------------------------
newSearchView =({|i|

	var buttonAction = {|a|
		"action".postln;
		searchViews[i].layout.index = stackIndexes.find([\queryIdx]);
		// hack! ever growing array!
		addStack.(i+1);
	};

	View().layout_( HLayout(
		Button()
			.string_("+")
			.font_(Font(size:48))
			.action_(buttonAction)
		)
	);
});

//------------------------------------------------------
// waitingView
//------------------------------------------------------
waitingView =({|i|
	View().layout_( HLayout(
		StaticText()
			.string_("searching.....")
		.align_(\center)
			.font_(Font(size:24))
		)
	);
});



//------------------------------------------------------
// playView
//------------------------------------------------------
playView =({|i,sndResult|

	var buffer,sfv,view;
	var group = Group.tail(s), loopSynth, oneShotSynth;
	var transportView;
	var fontSize = 9;
	var oneShotButton, pitchSlider, volumeSlider, fadeInKnob, fadeOutKnob;

	var cancelButtonAction = {|button|
		loopSynth.free;

		oneShotSynth.free;
		
		buffer.close;
		buffer.free;
		group.free;
		searchViews[i].layout.index = stackIndexes.find([\newSearchIdx]);
		removeStack.(i);

	};



	var buttonAction = {|button|
		switch(button.value,
			0,{
				button.parent.children(View).do({|o|
					o.enabled_(true)
				});

				},
			1,{		
				var c = button.parent.children(View);
				c.remove(button);
				c.do({|o|
					o.enabled_(false)
				});
			});

	};

	var sloopButtonAction = { |button|
		buttonAction.(button);
		switch(button.value,
			0,{
			
			},
			1,{		

			});
	};

	var makeSynth = {|localBuffer, synthTypeMono, synthTypeStereo|

		var localSynth;
		localBuffer.numChannels.switch(
			1,{
				localSynth = Synth.tail(group, synthTypeMono, [\bufnum, localBuffer.bufnum, \gate, 1]);
			},
			2,{
				localSynth = Synth.tail(group, synthTypeStereo, [\bufnum, localBuffer.bufnum, \gate, 1]);
			}
		);

		group.set(\gain,gainSpec.map(volumeSlider.value));
		group.set(\attack,fadeInSpec.map(fadeInKnob.value));
		group.set(\decay,fadeOutSpec.map(fadeOutKnob.value));
		group.set(\pitch,pitchSpec.map(pitchSlider.value));

		localSynth		
	};

	var loopButtonAction = { |button|
		buttonAction.(button);
		switch(button.value,
			1,{
				"play loop...".postln;
				loopSynth = makeSynth.(buffer,\loopSynthMono,\loopSynthStereo);
			},
			0,{
				"stop loop".postln;
				loopSynth.set(\gate,0);
			}
		);
	};


	var oneShotButtonAction = { |button|
		buttonAction.(button);
		switch(button.value,
			1,{"play oneshot...".postln;

				oneShotSynth = makeSynth.(buffer,\oneShotSynthMono,\oneShotSynthStereo);
				OSCpathResponder(s.addr, ['/n_end', oneShotSynth.nodeID], { |time, resp, msg| 
				        resp.remove;
				        {button.valueAction = 0;}.defer;
				}).add; 
			},
			0,{	"stop oneshot".postln;
				//oneShotSynth.set(\gate,0);
				oneShotSynth.free;
			}
		);
	};

	var oneShotEnd = {

	};

	var onBufferRead = {|localBuf|
		localBuf.loadToFloatArray(action:{ |data|
			{
				sfv.setData(data,
					512,// QT not using this
					0,
					localBuf.numChannels,
					localBuf.sampleRate.asInteger // need to cast!?!
				);
				view.enabled_(true);
			}.defer;
		});
	};

	// //• encapsulate as a service (either freesound or a HD)

	//• sndResult could be a path to local path or URL to freesound
	//• if it's freesound, need to download, process mp3->local
	//• local->buffer...let's go!


	sndResult.basename.splitext[1].toLower.postln;

	if(sndResult.basename.splitext[1].toLower == "mp3",{
		buffer = MP3.readToBuffer(s, sndResult,action:onBufferRead);
	},{
		buffer = Buffer.read(s, sndResult,action:onBufferRead);
	});




	// //• freesound load sound into mp3 buffer
	// sndResult.retrievePreview(dir.asAbsolutePath,{|a|
	// 	"*".postln;
	// 	sndResult.postln;
	// 	p = dir +/+ PathName(sndResult.name.splitext[0]++".mp3");
	// 	buffer = MP3.readToBuffer(s, p.asAbsolutePath,action:onBufferRead);
	// },"hq","mp3");


	view = View().layout_(
	GridLayout.rows(
			[
				Button()
					.states_([["❌"]])
					.font_(Font(size:9))
					.maxWidth_(30)
					.minHeight_(30)
					.action_({|b|cancelButtonAction.(b)}),

				StaticText()
					.string_(sndResult.basename.splitext[0])
					.align_(\left)
					.font_(Font(size:12)),



				transportView = View().layout_(HLayout(

							 // Button()
								// .states_([
								// 	["SLoop In"],
								// 	["SLoop Out",Color.black,Color.green.alpha_(0.3)]

								// 	])
								// .action_(sloopButtonAction)
								// .minHeight_(30)
								// .maxWidth_(50)
								// .font_(Font(size:fontSize)),

							 oneShotButton = Button()
								.states_([
									["1Shot In"],
									["1Shot Out",Color.black,Color.green.alpha_(0.3)]

									])
								.action_(oneShotButtonAction)
								.minHeight_(30)
								.maxWidth_(50)
								.font_(Font(size:fontSize)),
							 Button()
								.states_([
									["Loop In"],
									["Loop Out",Color.black,Color.green.alpha_(0.3)]

									])
								.action_(loopButtonAction)
								.minHeight_(30)
								.maxWidth_(50)
								.font_(Font(size:fontSize));



					)),




				StaticText().string_("fadeIn").font_(Font(size:9)),
				fadeInKnob =  Knob()
					.minHeight_(30)
					.maxWidth_(30)
					.action_({|o|

						group.set(\attack,fadeInSpec.map(o.value));
					})
					.valueAction_(fadeInSpec.unmap(fadeInSpec.default)),

				StaticText().string_("fadeOut").font_(Font(size:9)),
				fadeOutKnob = Knob()

					.minHeight_(30)
					.maxWidth_(30)
					.action_({|o|
						group.set(\decay,fadeOutSpec.map(o.value));
					})
					.valueAction_(fadeOutSpec.unmap(fadeOutSpec.default)),
				

				GridLayout.rows([

					StaticText().string_("volume").font_(Font(size:9)),
					volumeSlider =  Slider()
						.orientation_(\horizontal)
						.maxHeight_(20)
						.action_({|o|
							group.set(\gain,gainSpec.map(o.value));
						})
						.valueAction_(gainSpec.unmap(gainSpec.default))
				],[

					StaticText().string_("pitch").font_(Font(size:9)),
					pitchSlider =  Slider()
						.orientation_(\horizontal)
						.maxHeight_(20)
						.action_({|o|
							group.set(\pitch,pitchSpec.map(o.value));
						})
						.valueAction_(pitchSpec.unmap(pitchSpec.default))
				]);



			],[
				[sfv = SoundFileView()
					.maxHeight_(80)
					.gridOn_(false)
					.backColor_(Color.white.alpha_(0.7))
					.rmsColor_(Color.blue.alpha_(0.4))
					.peakColor_(Color.blue.alpha_(0.3))
					//.selectionColor_(0, Color.black.alpha_(0.2))

					,columns:11],



		]
	).setMinColumnWidth(1,150)
	).enabled_(false)
	.background_(Color.rand(0.1,0.9))
	.maxHeight_(160)
});


//------------------------------------------------------
// queryView
//------------------------------------------------------
queryView =({|i|

	var textFieldAction = {|a|

		searchViews[i].layout.index = stackIndexes.find([\waitingIdx]);

		//• HD version
		//• time to start making a protocol
		//•
		//• either search should return data including path, channels, length, shape?
		//• soundInfo structure should be passed on to results view
		//searchViews[i].layout.index = stackIndexes.find([\resultsIdx]);

		searchViews[i].layout.index = stackIndexes.find([\resultsIdx]);
		fastSearch.(
			dirPath,
			"wav|wave|aif|aiff|mp3",
			a.string,// using '.' will give every file
			{|a,count|
		
				//[i,a].postln;
				//Routine{
				addResult.(i,a,count);
				//}.play(AppClock);
		
			},
			{|c|("sound files found"+c).postln;
			}
		);

		//• encapsulate as a service (either freesound or a HD)

		//freesound basic text search

		// Freesound.defaultFields =
		// 	"id,name,tags,username,license,previews,channels,images,type,download,duration";

		// FSSound.textSearch(
		// 	query: a.string,
		// 	filter: "duration:[0 TO 30]",
		// 	params:('page':1),
		// 	action: {|p|
		// 		var count = 0;
		// 		searchViews[i].layout.index = stackIndexes.find([\resultsIdx]);
		// 		p.do({|snd|

		// 			Routine{
		// 				addResult.(i,snd,count);
		// 				count = count + 1;
		// 			}.play(AppClock);

		// 		});
		// 	}
		// );
	};

	View().layout_( VLayout(
		TextField()
			.string_("")
			.align_(\center)
			.font_(Font(size:48))
			.stringColor_(Color.red)
			.focusGainedAction_({|a|a.string ="";})//always clear
			.action_(textFieldAction)
		)
	);

});

//------------------------------------------------------
// resultsView
//------------------------------------------------------
resultsView =({|i|

	var scroll = ScrollView(bounds:Rect(0,50,500,300).center_(Window.availableBounds.center));
	var canvas = View();
	var button;
	var layout;

	canvas.layout = VLayout();
	button = Button().states_([["cancel"]]).action_({
		searchViews[i].layout.index = stackIndexes.find([\newSearchIdx]);
		removeStack.(i);
	}).maxWidth_(50);

	canvas.layout.add(nil); // stretch remaining empty space

	scroll.canvas = canvas;
	//scroll.front;
	scroll.hasHorizontalScroller_(false);

	View().layout_( VLayout(
			button,
			scroll
		)
	);

});


//------------------------------------------------------
// addResult
//------------------------------------------------------

addResult =({|i,sndResult,count|

	var fontSize = 16;

	var buttonAction = {|button|

		searchViews[i].layout.add(playView.(i,sndResult).front);
		searchViews[i].layout.index = stackIndexes.find([\playIdx]);
	};


	var makeEntry = {
		var view = View()
			.layout_( HLayout(
				StaticText()
					.background_(Color.green(0.7,0.2))
					.stringColor_(Color.white)
						

					.string_(" " + (count+1) + "\t🔊" + sndResult.basename.splitext[0])
					.align_(\left)
					.font_(Font(size:fontSize))
					.mouseDownAction_(buttonAction),

				StaticText()
					.background_(Color.green(0.7,0.2))
					.string_(count)
					.align_(\center)
					.font_(Font(size:fontSize))
					.maxWidth_(160)
					.mouseDownAction_(buttonAction)
					.onResize_({|btn|
						SoundFile.use(sndResult, { |f| 
							var dur = f.duration;
							btn.string_( 
								"🕓" + (dur/60).floor + "\'" + (dur%60).floor++ "\"" + ((dur%60).mod(1).round(1e-3)*1000) ++"",
								Color.white,
								Color.green(0.7,0.2)
							);

						})
					})

			)
	    );
		view.layout.margins = [0,0,0,0];
	    view;
	};

	searchViews[i].children(View)[3].children(ScrollView)[0].canvas.layout.add( makeEntry.() );

});

//------------------------------------------------------
// stackView
//------------------------------------------------------
stackView =({|i|

	View().layout_( StackLayout(
			newSearchView.(i),
			queryView.(i),
			waitingView.(i),
			resultsView.(i),
			//playView.(i)

		)
	);
});

//------------------------------------------------------
// build UI
//------------------------------------------------------
window = Window("Sound Narative",Rect(0,0,Window.screenBounds.width * 0.7, Window.screenBounds.height)
	//.center_(Window.availableBounds.center)
	).front;

window.layout = VLayout();

// add our first stack
addStack.(0);


window.onClose = ({

	Buffer.freeAll;
	s.freeAll;

});
CmdPeriod.doOnce({window.close});

//------------------------------------------------------------------
// SYNTHS
//------------------------------------------------------------------

SynthDef("loopSynthMono", { |bufnum = 0, gain = 0.0, gate = 0, attack=2.8, decay=2.8, pitch = 1|
	var son;
	son = PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum)*pitch, trigger:gate, loop:1, doneAction:0)
		* EnvGen.kr(Env.asr(attack,1.0,decay,\sine), gate, doneAction:2) * gain.dbamp;
	Out.ar(0, son!2);
}).load(s);

SynthDef("loopSynthStereo", { |bufnum = 0, gain = 0.0, gate = 0, attack=2.8, decay=2.8, pitch = 1|
	var son;
	son = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum)*pitch, trigger:gate, loop:1, doneAction:0)
		* EnvGen.kr(Env.asr(attack,1.0,decay,\sine), gate, doneAction:2) * gain.dbamp;
	Out.ar(0, son);
}).load(s);

SynthDef("oneShotSynthMono", { |bufnum = 0, gain = 0.0, gate = 0, attack=2.8, decay=2.8, pitch = 1|
	var son;

	son = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*pitch*gate, trigger:gate, loop:0, doneAction:2) 
		//* EnvGen.kr(Env.linen(attack, (BufDur.kr(bufnum) * pitch.reciprocal) - attack - decay, decay), gate, doneAction:0) 
		* gain.dbamp;
	Out.ar(0, son!2);
}).load(s);

SynthDef("oneShotSynthStereo", { |bufnum = 0, gain = 0.0, gate = 0, attack=2.8, decay=2.8, pitch = 1|
	var son;
	son = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*pitch*gate, trigger:gate, loop:0, doneAction:2) 
		//* EnvGen.kr(Env.linen(attack, (BufDur.kr(bufnum) * pitch.reciprocal) - attack - decay, decay), gate, doneAction:0) 
		* gain.dbamp;
	Out.ar(0, son);
}).load(s);


)


