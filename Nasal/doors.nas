# Airbus A330-200 Doors by Omega Pilot
######################################

var doors =
 {
 new: func(name, transit_time)
  {
  doors[name] = aircraft.door.new("sim/model/door-positions/" ~ name, transit_time);
  },
 toggle: func(name)
  {
  doors[name].toggle();
  },
 open: func(name)
  {
  doors[name].open();
  },
 close: func(name)
  {
  doors[name].close();
  },
 setpos: func(name, value)
  {
  doors[name].setpos(value);
  }
 };
doors.new("l1", 10);
doors.new("l2", 10);
doors.new("r1", 10);
doors.new("r2", 10);
doors.new("cockpit-door", 3);
doors.new("l1-stairs", 20);
doors.new("l2-stairs", 20);
doors.new("eng1-control",2);
doors.new("eng2-control",2);
