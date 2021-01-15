# Various polyfills, providing functionality from newer FG releases on older
# versions.

if (!defined('isfunc')) {
    globals.isfunc = func(x) { return typeof(x) == 'func'; }
}

if (props.Node['toggleBoolValue'] == nil) {
    props.Node.toggleBoolValue = func() {
        me.setBoolValue(!me.getBoolValue());
    }
}
