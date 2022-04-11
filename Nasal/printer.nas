# Flight deck printer

var myprops = {};
myprops.base = props.globals.getNode('instrumentation/printer', 1);
myprops.queue = myprops.base.getNode('job-queue', 1);
myprops.paper = myprops.base.getNode('paper', 1);
myprops.history = myprops.base.getNode('history', 1);
myprops.printing = myprops.base.getNode('printing', 1);
myprops.printing.setBoolValue(0);

paperWidth = getprop('instrumentation/printer/config/paper-width') or 32;

var newJob = func(txt) {
    var job = myprops.queue.addChild('job');
    var rawLines = [];
    if (typeof(txt) == 'scalar')
        rawLines = split("\n", txt);
    elsif (typeof(txt) == 'vector')
        rawLines = txt;
    else
        rawLines = [debug.string(txt)];
    foreach (var rawLine; rawLines) {
        while (utf8.size(rawLine) > paperWidth) {
            var line = utf8.substr(rawLine, 0, paperWidth);
            job.addChild('line').setValue(line);
            rawLine = utf8.substr(rawLine, paperWidth);
        }
        job.addChild('line').setValue(rawLine);
    }
};

var cutPaper = func {
    var sheet = myprops.history.addChild('sheet');
    sheet.setValues(myprops.paper.getValues());
    myprops.paper.removeAllChildren();
};

var discard = func (n) {
    var sheet = myprops.history.getNode('sheet[' ~ n ~ ']');
    if (sheet != nil)
        sheet.remove();
};

var update = func {
    var jobs = myprops.queue.getChildren('job');
    if (size(jobs) == 0) {
        myprops.printing.setBoolValue(0);
        return;
    }
    else {
        myprops.printing.setBoolValue(1);
    }
    var job = jobs[0];
    var lines = job.getChildren('line');
    if (size(lines) == 0) {
        job.remove();
        return;
    }
    var line = lines[0].getValue();
    lines[0].remove();
    myprops.paper.addChild('line').setValue(line);
};

var printTimer = maketimer(0.5, update);
printTimer.simulatedTime = 1;
printTimer.start();
