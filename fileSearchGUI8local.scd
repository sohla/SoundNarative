// (
// Freesound.clientId = "f2880da706c6d92d7ce3";
// Freesound.clientSecret = "bfa791a021762f7c6cb70088c720855a0c5f8f49";
// Freesound.authType = "oauth2";
// Freesound.refreshToken;
// )


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

// (
// SynthDef("bufplayerMonoFS", { |bufnum = 0, volume = 0.0, gate = 1, attack=2.8, decay=2.8|
// 	var son;
// 	son = PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum),trigger:gate,loop:1,doneAction:0)
// 	* EnvGen.kr(Env.asr(attack,1.0,decay,\sine),gate,doneAction:0) * volume.dbamp;

// 	Out.ar(0, son!2);
// 	//	Out.ar(0, son!2);
// }).load(s);

// SynthDef("bufplayerStereoFS", { |bufnum = 0, volume = 0.0, gate = 1, attack=2.8, decay=2.8|
// 	var son;
// 	son = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum),trigger:gate,loop:1,doneAction:0)
// 	* EnvGen.kr(Env.asr(attack,1.0,decay,\sine),gate,doneAction:0) * volume.dbamp;

// 	Out.ar(0, son);
// 	//	Out.ar(0, son);
// }).load(s);

// )




(

var window, mainView,newSearchView,stackView,queryView,resultsView,waitingView,playView;
var addStack,removeStack,addResult,switchToStack, transportView;
var searchViews = [];
var stackIndexes = [\newSearchIdx,\queryIdx,\waitingIdx,\resultsIdx,\playIdx];
var dir = PathName.new("~/Music/SoundNarative/");
var fastSearch;

//var dirPath = "/Volumes/Steph2015/*".postln;
//var dirPath = "/Volumes/Steph2017/SFX/*".postln;
var dirPath = "~/Music/*";

var gainSpec = ControlSpec(0.ampdb, 12, \db, step: 0.5, default: 0, units: " dB");
var fadeInSpec = ControlSpec(0.1, 5.0, \lin, step: 0.1, default: 1.8, units: " secs");
var fadeOutSpec = ControlSpec(0.1, 5.0, \lin, step: 0.1, default: 2.8, units: " secs");


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
// transportView
//------------------------------------------------------
transportView = ({|samplerNode, buffer|

	var fontSize = 9;
	var k,view;
	var buttonAction = {|button|
		switch(button.value,
			0,{
				button.parent.children(View).do({|o|
					o.enabled_(true)
				});

				},
			1,{		
				var c = view.children(View);
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

	var loopButtonAction = { |button|
		buttonAction.(button);
		switch(button.value,
			1,{"playing...".postln;
			//s.sendMsg("/n_set",samplerNode,\gate,-1);
			s.sendMsg("/n_set",samplerNode,\gate,1);
			},
			0,{"stopped".postln;
			//s.sendMsg("/n_free", samplerNode);
			s.sendMsg("/n_set",samplerNode,\gate,0);
		});
	};


	var oneShotButtonAction = { |button|
		buttonAction.(button);
		switch(button.value,
			0,{
			
			},
			1,{		
				
			});
	};

	view = View().layout_(HLayout(

				 Button()
					.states_([
						["SLoop In"],
						["SLoop Out",Color.black,Color.green.alpha_(0.3)]

						])
					.action_(sloopButtonAction)
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
					.font_(Font(size:fontSize)),

				 Button()
					.states_([
						["1Shot In"],
						["1Shot Out",Color.black,Color.green.alpha_(0.3)]

						])
					.action_(oneShotButtonAction)
					.minHeight_(30)
					.maxWidth_(50)
					.font_(Font(size:fontSize));




		));
		
});


//------------------------------------------------------
// playView
//------------------------------------------------------
playView =({|i,sndResult|

	var buffer,sfv,sliderView,view;
	var samplerNode = s.nextNodeID;

	var cancelButtonAction = {|button|
		s.sendMsg("/n_free", samplerNode);
		buffer.close;
		buffer.free;
		searchViews[i].layout.index = stackIndexes.find([\newSearchIdx]);
		removeStack.(i);

	};

	// var buttonAction = {|button|

	// 	button.value.switch(

	// 		1,{"playing...".postln;

	// 		buffer.numChannels.switch(
	// 		1,{s.sendMsg("/s_new", "bufplayerMonoFS", samplerNode, 0, 0,\bufnum, buffer.bufnum);},
	// 		2,{s.sendMsg("/s_new", "bufplayerStereoFS", samplerNode, 0, 0,\bufnum, buffer.bufnum);});
	// 		s.sendMsg("/n_set",samplerNode,\volume,sliderView.value);

	// 		},
	// 		0,{"stopped".postln;
	// 		//s.sendMsg("/n_free", samplerNode);
	// 		s.sendMsg("/n_set",samplerNode,\gate,0);
	// 	});

	// };

	// var loopAction = {|button|
	// 	//•TODO 
	// };


	// var sliderAction = {|o|

	// };

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

		localBuf.numChannels.switch(
			1,{s.sendMsg("/s_new", "bufplayerMonoFS", samplerNode, 0, 0,\bufnum, localBuf.bufnum, \gate, 0);},
			2,{s.sendMsg("/s_new", "bufplayerStereoFS", samplerNode, 0, 0,\bufnum, localBuf.bufnum, \gate, 0);}
		);

		s.sendMsg("/n_set",samplerNode,\volume,gainSpec.unmap(gainSpec.default));
		s.sendMsg("/n_set",samplerNode,\attack,fadeInSpec.unmap(fadeInSpec.default));
		s.sendMsg("/n_set",samplerNode,\decay,fadeOutSpec.unmap(fadeOutSpec.default));

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
					.maxWidth_(30)
					.minHeight_(30)
					.action_({|b|cancelButtonAction.(b)}),

				StaticText()
					.string_(sndResult.basename.splitext[0])
					.align_(\left)
					.font_(Font(size:12)),
				transportView.(samplerNode,buffer),


				StaticText().string_("fadeIn").font_(Font(size:9)),
				Knob()
					.minHeight_(30)
					.maxWidth_(30)
					.action_({|o|
						s.sendMsg("/n_set",samplerNode,\attack,fadeInSpec.map(o.value));
					})
					.value_(fadeInSpec.unmap(fadeInSpec.default)),

				StaticText().string_("fadeOut").font_(Font(size:9)),
				k = Knob()

					.minHeight_(30)
					.maxWidth_(30)
					.action_({|o|
						s.sendMsg("/n_set",samplerNode,\decay,fadeOutSpec.map(o.value));
					})
					.value_(fadeOutSpec.unmap(fadeOutSpec.default)),
				
				StaticText().string_("volume").font_(Font(size:9)),
				
				sliderView = Slider()
					.orientation_(\horizontal)
					.maxHeight_(20)
					.action_({|o|
						s.sendMsg("/n_set",samplerNode,\volume,gainSpec.map(o.value));
					})
					.value_(gainSpec.unmap(gainSpec.default));



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



)







