io.include('message-types.nas');
io.include('message.nas');
io.include('base-driver.nas');
io.include('irc-driver.nas');
io.include('hoppie-driver.nas');
io.include('system.nas');

var system = System.new();
system.registerDriver(BaseDriver.new(system));
system.registerDriver(IRCDriver.new(system));
system.registerDriver(HoppieDriver.new(system));
debug.dump("CPDLC DRIVERS: ", system.listDrivers());
system.attach('cpdlc');
