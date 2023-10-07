import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application.Storage;

(:glance)
class GlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc) {
    }

    function onUpdate(dc) {
        var answer = Storage.getValue("answer");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, dc.getHeight() / 2, Graphics.FONT_TINY, (answer != null ? WatchUi.loadResource(Rez.Strings.label_calculator1) + limitDigits(answer) : WatchUi.loadResource(Rez.Strings.label_calculator2)), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
