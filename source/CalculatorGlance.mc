import Toybox.WatchUi;
import Toybox.Graphics;

(:glance)
class GlanceView extends WatchUi
.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.GlanceLayout(dc));
    }
}
