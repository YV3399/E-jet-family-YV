var includes = {};

var acdir = getprop('/sim/aircraft-dir');

var include = func (basename) {
    var namespace = 'html';
    var path = acdir ~ '/Nasal/html/' ~ basename;
    if (!contains(includes, basename)) {
        printf("--- loading " ~ path ~ " ---");
        io.load_nasal(path, namespace);
        includes[basename] = 1;
    }
}

include('rendering.nas');
include('hyperscript.nas');
include('dom.nas');
