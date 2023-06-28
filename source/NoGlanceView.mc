using Toybox.WatchUi as Ui;
using Toybox.Application.Properties;

class NoGlanceView extends Ui.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.NoGlanceLayout(dc));
    }
}
