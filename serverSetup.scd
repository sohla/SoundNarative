( 
o = Server.local.options;
o.inDevice = ServerOptions.devices[1];
o.outDevice = ServerOptions.devices[1];
// o.inDevice = ServerOptions.devices[ServerOptions.devices.indexOfEqual("Soundflower (2ch)")];
// o.outDevice = ServerOptions.devices[ServerOptions.devices.indexOfEqual("Soundflower (2ch)")];
o.numOutputBusChannels = 2;
o.numInputBusChannels = 2;
o.sampleRate = nil;
s.reboot

)


ServerMeter.new(s, 2, 2);
