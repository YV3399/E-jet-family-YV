var TestApp = {
    new: func (masterGroup) {
        var m = BaseApp.new(masterGroup);
        return m;
    },
};

registerApp('test', 'Test', nil, TestApp);
