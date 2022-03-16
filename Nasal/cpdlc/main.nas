io.include('message-types.nas');
io.include('message.nas');
io.include('base-driver.nas');
io.include('irc-driver.nas');
io.include('system.nas');

var system = System.new();

var drivers = [
    IRCDriver.new(system),
];

system.attach('cpdlc');
system.setDriver(drivers[0]);
