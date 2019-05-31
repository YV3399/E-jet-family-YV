##
# Citation X Initialisation

var get_local_path = func(file){
    var aircraft_dir = split('/', getprop("/sim/aircraft-dir"))[-1];
    return "Aircraft/" ~ aircraft_dir ~ "/Models/Primus-Epic/canvas/"~ file;
};

var SymbolLayer = canvas.SymbolLayer;
var SingleSymbolLayer = canvas.SingleSymbolLayer;
var MultiSymbolLayer = canvas.MultiSymbolLayer;
var NavaidSymbolLayer = canvas.NavaidSymbolLayer;
var OverlayLayer = canvas.OverlayLayer;
var TileLayer = canvas.TileLayer;
var Symbol = canvas.Symbol;
var Group = canvas.Group;
var Path = canvas.Path;
var DotSym = canvas.DotSym;
var Map = canvas.Map;
var SVGSymbol = canvas.SVGSymbol;
var LineSymbol = canvas.LineSymbol;
var StyleableCacheable = canvas.StyleableCacheable;
var SymbolCache32x32 = canvas.SymbolCache32x32;
var SymbolCache256x256 = canvas.SymbolCache256x256;
var SymbolCache = canvas.SymbolCache;
var Text = canvas.Text;

io.include('loaders.nas');

