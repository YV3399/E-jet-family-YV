# Abstract Base Class for CPDLC driver

var BaseDriver = {
    new: func (system) {
        return {
            parents: [BaseDriver],
            system: system,
        };
    },

    getDriverName: func () { return 'NONE'; },
    isAvailable: func () { return 0; },
    start: func () { },
    stop: func () { },
    connect: func (logonStation) { },
    disconnect: func () { },
    send: func (msg) { },
};
