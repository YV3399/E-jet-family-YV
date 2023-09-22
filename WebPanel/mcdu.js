let screen;
var screen_src;
let loading = 0;
let scheduled_load = 0;
var canvas_index = -1;
var ws = null;

function resize() {
    let maxByW = document.documentElement.clientWidth / 36;
    let maxByH = document.documentElement.clientHeight / 52;
    let max = Math.max(8, Math.min(maxByW, maxByH));
    document.documentElement.style.fontSize = max + 'px';
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
    request.addEventListener('load', (ev) => {
        setTimeout(() => {
            if (ws != null) {
                ws.send(JSON.stringify({
                    command: 'get',
                    node: '/instrumentation/mcdu[0]/screen'
                }));
                ws.send(JSON.stringify({
                    command: 'get',
                    node: '/instrumentation/mcdu[0]/scratchpad'
                }));
            }
        }, 100);
    });
    request.send(body);
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

var wsReconnectDelay = 500;

let screenW = 24;
let screenH = 13;

let colors = [
        'white',
        'red',
        'yellow',
        'green',
        'cyan',
        'blue',
        'magenta',
    ];

function refresh_cell(index, value) {
    let elem = cells[index];
    if (!elem)
        return;
    let flags = Number.parseInt('0x' + value.substr(0, 2));
    let colorIndex = flags & 0x07;
    let large = !!(flags & 0x10);
    let reverse = !!(flags & 0x20);
    let glyph = value[2];
    let color = colors[colorIndex % 7];

    elem.innerText = glyph;
    elem.className = "cell " + color + " " + (large ? "large" : "small");
}

function refresh_screen(data) {
    for (var i = 0; i < screenW * screenH; i++) {
        refresh_cell(i, data.substr(i * 3, 3));
    }
}

var statusLight = null;
var statusLightFlipflopTimer = 0;
var connectionStatus = 'off';

function updateStatusLight() {
    var color = 'black';
    switch (connectionStatus) {
        case 'connected':
            if (statusLightFlipflopTimer > 0)
                color = 'lime';
            else
                color = 'green';
            break;
        case 'connecting':
            color = 'yellow';
            break;
        case 'error':
            if (statusLightFlipflopTimer > 0)
                color = 'yellow';
            else
                color = 'red';
            break;
    }
    statusLight.style.backgroundColor = color;
}

function update_dividers(dividersStr) {
    var dividersClasses = "mcduScreen";
    var screenElem = document.getElementById('mcduScreen');
    if (/0/.test(dividersStr)) dividersClasses += ' enable-divider0';
    if (/1/.test(dividersStr)) dividersClasses += ' enable-divider1';
    if (/2/.test(dividersStr)) dividersClasses += ' enable-divider2';
    if (/3/.test(dividersStr)) dividersClasses += ' enable-divider3';
    if (/4/.test(dividersStr)) dividersClasses += ' enable-divider4';
    screenElem.className = dividersClasses;
}

function update_scratchpad(txt) {
    scratchpad.innerText = txt;
}

function runWebsocket() {
    let url = "ws://" + window.location.host + "/PropertyListener";
    console.log("Connecting to " + url + "...");
    connectionStatus = 'connecting';
    statusLightFlipflopTimer = 0;
    updateStatusLight();
    ws = new WebSocket(url);
    ws.onopen = (ev) => {
        console.log("Connected to " + url + ".");
        connectionStatus = 'connected';
        statusLightFlipflopTimer = 0;
        updateStatusLight();
        wsReconnectDelay = 500;
        // ws.send(JSON.stringify({
        //     command: 'get',
        //     node: '/instrumentation/mcdu[0]/screen'
        // }));
        // ws.send(JSON.stringify({
        //     command: 'get',
        //     node: '/instrumentation/mcdu[0]/dividers'
        // }));
        ws.send(JSON.stringify({
            command: 'addListener',
            node: '/instrumentation/mcdu[0]/screen'
        }));
        ws.send(JSON.stringify({
            command: 'addListener',
            node: '/instrumentation/mcdu[0]/scratchpad'
        }));
    }
    ws.onmessage = (ev) => {
        statusLight.style.backgroundColor = 'lime';
        connectionStatus = 'connected';
        statusLightFlipflopTimer = 500;
        updateStatusLight();
        let msg = JSON.parse(ev.data);
        switch (msg.name) {
            case 'cell':
                refresh_cell(msg.index, msg.value);
                break;
            case 'screen':
                ws.send(JSON.stringify({
                    command: 'get',
                    node: '/instrumentation/mcdu[0]/dividers'
                }));
                refresh_screen(msg.value);
                break;
            case 'scratchpad':
                console.log(msg);
                update_scratchpad(msg.value);
                break;
            case 'dividers':
                update_dividers(msg.value);
                break;
            default:
                console.log(msg);
                break;
        }
    }
    ws.onerror = (ev) => {
        ws = null;
        console.log("Websocket error");
        console.log(ev);
        connectionStatus = 'error';
        updateStatusLight();
        setTimeout(runWebsocket, wsReconnectDelay);
        wsReconnectDelay = Math.min(60000, wsReconnectDelay * 2);
    }
    ws.onclose = (ev) => {
        ws = null;
        console.log("Websocket closed due to " + ev.reason);
        connectionStatus = 'off';
        updateStatusLight();
        setTimeout(runWebsocket, wsReconnectDelay);
        wsReconnectDelay = Math.min(60000, wsReconnectDelay * 2);
    }
}

var cells = [];
var scratchpad = null;

function initScreen() {
    var screenElem = document.getElementById('mcduScreen');
    for (var y = 0; y < screenH; y++) {
        var tr = document.createElement('tr');
        switch (y) {
            case 4: tr.className = 'divider3'; break;
            case 8: tr.className = 'divider4'; break;
        }
        screenElem.appendChild(tr);
        for (var x = 0; x < screenW; x++) {
            var td = null;
            if (x == 12 && y > 0) {
                td = document.createElement('td');
                if (y <= 4)
                    td.className = 'divider divider0'; 
                else if (y <= 8)
                    td.className = 'divider divider1'; 
                else
                    td.className = 'divider divider2'; 
                tr.appendChild(td);
            }
            td = document.createElement('td');
            tr.appendChild(td);
            td.className = 'white large';
            td.innerText = ' ';
            cells.push(td);
        }
    }
    var tr = document.createElement('tr');
    var td = document.createElement('td');
    td.setAttribute('colspan', screenW);
    td.className = 'scratchpad';
    tr.appendChild(td);
    screenElem.appendChild(tr);
    scratchpad = td;
}

window.addEventListener('load', function () {
    statusLight = document.getElementById('statusLight');
    let dt = 100;
    setInterval(() => {
            if (statusLightFlipflopTimer > 0) {
                statusLightFlipflopTimer -= dt;
                if (statusLightFlipflopTimer <= 0) {
                    updateStatusLight();
                }
            }
        }, dt);
    resize();
    window.addEventListener('resize', resize);
    let buttons = document.querySelectorAll('button');
    for (const button of buttons) {
        button.addEventListener('click', function () {
            press_button(button.name);
        });
        button.addEventListener('touchstart', preventzoomaction, true);
    }
    initScreen();

    runWebsocket();
}, true);

