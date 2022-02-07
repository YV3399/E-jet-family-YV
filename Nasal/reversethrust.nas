togglereverser = func {
   var val = getprop("/controls/engine/engine[0]/reverser");
   setprop("/controls/engine/engine[0]/reverser", !val);
   setprop("/controls/engine/engine[1]/reverser", !val);
}
