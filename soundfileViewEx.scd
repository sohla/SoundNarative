(
	var sfv,sf,ev;
	var path = PathName.new("~/Music/SCSamples/discustingMelody.wav").asAbsolutePath;
w=Window().layout_(


	GridLayout.rows(
		[
			[sfv = SoundFileView(), columns:2]
		],
		[
			Button()
				.states_([["Play"],["Stop"]])
				.minHeight_(100)
				.action_({|b|
				
				}),


			VLayout(
			CheckBox().string_("auto-fade"),
			CheckBox().string_("loop")
			)


		],[
			[Slider().orientation_(\horizontal).maxHeight_(100),columns:2]
		]
	)



).front;

	sf = SoundFile.new;
	sf.openRead(path);
	sf.cue(ev);
	sfv.soundfile = sf;
	sfv.read(0,sf.numFrames);
	sfv.gridOn = false;

	sfv.timeCursorOn = true;
	sfv.timeCursorPosition = 2000000;
	sfv.drawsWaveForm = true;
	sfv.setSelectionStart(0, 102345);
	sfv.setSelectionSize(0, 1002345);

)



