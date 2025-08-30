import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application.Storage;

(:glance)
class GlanceView extends WatchUi.GlanceView {
    var _usingFont;

    function initialize() {
        GlanceView.initialize();
    }

    function onSettingsChanged() {
    }
    
    function onLayout(dc) {
        // Find the best font that fits the number of lines we'll be showing (two or three, depending if we're showing the title)
        var fonts = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_MEDIUM, Graphics.FONT_LARGE];
        var dcHeight = dc.getHeight();

        _usingFont = Graphics.FONT_TINY; // We default to this

        for (var i = fonts.size() - 1; i >= 0 ; i--) {
            var fontHeight = Graphics.getFontHeight(fonts[i]);
            if (dcHeight / fontHeight == 2) {
                _usingFont = fonts[i];
                break;
            }
        }
    }

    function onUpdate(dc) {
        var answer = Storage.getValue("answer");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, dc.getHeight() / 2, _usingFont, (answer != null ? WatchUi.loadResource(Rez.Strings.label_calculator1) + limitDigits(answer) : WatchUi.loadResource(Rez.Strings.label_calculator2)), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
