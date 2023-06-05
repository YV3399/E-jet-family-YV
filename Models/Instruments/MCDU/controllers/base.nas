var BaseController = {
    new: func () {
        return {
            parents: [BaseController]
        };
    },

    getKey: func () {
        return nil;
    },

    # Process a select event. The 'boxed' argument indicates that the
    # controller's key is currently boxed.
    select: func (owner, boxed) {
        return nil;
    },

    # Process a send event.
    # Scratchpad contents is sent as the value.
    # Return updated scratchpad contents to indicate acceptance, or nil to
    # keep scratchpad value unchanged and signal rejection.
    send: func (owner, val) {
        return nil;
    },

    # Process a delete event. This event is sent when the scratchpad contains
    # the magical "*DELETE*" message, and the controller is triggered. The
    # controller should respond by clearing its field, deleting it, or
    # resetting it to defaults. The 'boxed' argument indicates whether the
    # field was boxed at the time the controller was triggered.
    delete: func (owner, boxed) {
    },

    # Process a dialling event.
    dial: func (owner, digit) {
        return nil;
    },
};

