import Toybox.WatchUi;
import Toybox.Graphics;
using Toybox.Application.Storage;

(:glance)
class GlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.GlanceLayout(dc));
    }

    function onUpdate(dc) {
        var answer = Storage.getValue("answer");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, dc.getHeight() / 2, Graphics.FONT_TINY, (answer != null ? "Calculator\nLatest: " + answer : "Calculator"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
