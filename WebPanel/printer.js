function getprop(prop, callback) {
    let request = new XMLHttpRequest;
    let url = window.location.protocol + "//" + window.location.host + "/json/" + prop;
    request.open("GET", url);
    request.responseType = 'json';
    request.addEventListener('load', function () {
        let data = request.response;
        callback(data);
    }, true);
    request.send();
}

function nasal(src) {
    let request = new XMLHttpRequest;
    request.open(
        "POST",
        window.location.protocol + "//" + window.location.host + "/run.cgi?value=nasal"
    );
    request.setRequestHeader("Content-Type", "application/json");
    let body = JSON.stringify({
        "name": "",
        "children": [
            {
                "name": "script",
                "index": 0,
                "value": src,
            }
        ]
    });
    request.send(body);
    request.addEventListener('load', function (data) {
        console.log(data);
    }, true);
}

document.getElementById('sendPrintJob').addEventListener('click', function () {
    let printJobTA = document.getElementById('printJob');
    let txt = printJobTA.value;
    let src = "printer.newJob('" + txt.replace("'", "\\'") + "');";
    nasal(src);
});

var paperLoading = false;
setInterval(function () {
    if (!paperLoading) {
        paperLoading = true;
        getprop('/instrumentation/printer/paper?d=3', function (node) {
            paperLoading = false;
            var txt = '';
            for (var i = 0; i < node.nChildren; i++) {
                txt = txt + node.children[i].value + "\n";
            }
            document.getElementById('current').innerText = txt;
        });
    }
}, 250);

var archiveLoading = false;
var archive = [];
var archiveSelected = 0;

var selectArchive = function (i) {
    var txt = '';
    archiveSelected = i;
    if (archiveSelected >= archive.length)
        archiveSelected = archive.length - 1;
    if (archiveSelected < 0)
        archiveSelected = 0;
    if (archiveSelected < archive.length) {
        txt = archive[archive.length - archiveSelected - 1];
    }
    document.getElementById('archive').innerText = txt;
};

document.getElementById('cutPaper').addEventListener('click', function () {
    nasal('printer.cutPaper();');
});


document.getElementById('archivePrev').addEventListener('click', function () {
    selectArchive(archiveSelected - 1);
});

document.getElementById('archiveNext').addEventListener('click', function () {
    selectArchive(archiveSelected + 1);
});

document.getElementById('archiveDelete').addEventListener('click', function () {
    nasal('printer.discard(' + archiveSelected + ');');
});

setInterval(function () {
    if (!archiveLoading) {
        archiveLoading = true;
        getprop('/instrumentation/printer/history?d=4', function (node) {
            archive = [];
            for (var i = 0; i < node.nChildren; i++) {
                var txt = '';
                var sheet = node.children[i];
                for (var j = 0; j < sheet.nChildren; j++) {
                    txt = txt + sheet.children[j].value + "\n";
                }
                archive[i] = txt;
            }
            selectArchive(archiveSelected);
            archiveLoading = false;
        });
    }
}, 250);
