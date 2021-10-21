let screen;
var screen_src;
let loading = 0;
let scheduled_load = 0;
var canvas_index = -1;

function resize() {
    let maxByW = document.documentElement.clientWidth / 36;
    let maxByH = document.documentElement.clientHeight / 52;
    let max = Math.max(8, Math.min(maxByW, maxByH));
    document.documentElement.style.fontSize = max + 'px';
}

function refresh_screen(force) {
    if (loading && !force) {
        scheduled_load = 1;
    }
    else {
        document.getElementById('statusLight').style.backgroundColor = 'lime';
        loading = 1;
        screen.src = screen_src + '&random=' + (new Date).getTime()
    }
}

function getprop(prop, callback) {
    let request = new XMLHttpRequest;
    let url = window.location.protocol + "//" + window.location.host + "/json/" + prop;
    request.open("GET", url);
    request.responseType = 'json';
    request.addEventListener('load', function () {
        let data = request.response;
        callback(data.value);
    }, true);
    request.send();
}

function press_button(key) {
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
                "value": "setprop('/instrumentation/mcdu[0]/command', '" + key + "');"
            }
        ]
    });
    request.send(body);
    refresh_screen();
    request.addEventListener('load', function () {
        refresh_screen();
    }, true);
}

var preventzoomaction = function(e) {  //https://exceptionshub.com/disable-double-tap-zoom-option-in-browser-on-touch-devices.html
        var t2 = e.timeStamp;
        var t1 = e.currentTarget.dataset.lastTouch || t2;
        var dt = t2 - t1;
        var fingers = e.touches.length;
        e.currentTarget.dataset.lastTouch = t2;

        if (!dt || dt > 500 || fingers > 1) return; // not double-tap

        e.preventDefault();
        e.target.click();
    };

window.addEventListener('load', function () {
    resize();
    window.addEventListener('resize', resize);
    let buttons = document.querySelectorAll('button');
    for (const button of buttons) {
        button.addEventListener('click', function () {
            press_button(button.name);
        });
        button.addEventListener('touchstart', preventzoomaction, true);
    }

    screen = document.querySelector('#mcduScreen');
    screen_src = screen.src;
    screen.addEventListener('load', function () {
        document.getElementById('statusLight').style.backgroundColor = 'green';
        loading = 0;
        if (scheduled_load) {
            scheduled_load = 0;
            refresh_screen();
        }
    });
    screen.addEventListener('error', function () {
        document.getElementById('statusLight').style.backgroundColor = 'red';
        loading = 0;
        if (scheduled_load) {
            refresh_screen();
        }
    });
    screen.addEventListener('abort', function () {
        document.getElementById('statusLight').style.backgroundColor = 'yellow';
        loading = 0;
        if (scheduled_load) {
            refresh_screen();
        }
    });
    setInterval(function () { refresh_screen(true); }, 1000);

    getprop('instrumentation/mcdu/canvas-index', function (i) {
        canvas_index = i;
        if (canvas_index >= 0) {
            screen_src = "/screenshot?canvasindex=" + canvas_index + "&type=png";
        }
    });
}, true);

