import Toybox.Graphics;
import Toybox.WatchUi;

var gAnswer = 0.0;
var gGrid = 0;
var gHilight = 0;

class CalculatorView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onHide() {
        if (Toybox has :Attention && Attention has :setFlashlightMode) {
            Attention.setFlashlightMode(Attention.FLASHLIGHT_MODE_OFF, null);
        }
    }

    function drawInside(dc, x, y, pos, text) {
		var width = dc.getWidth();
		var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        if (gHilight == pos) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        }
        else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.drawText(x, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

		var width = dc.getWidth();
		var height = dc.getHeight();
        var w_separation = width / 3;
        var h_separation = height / 5;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        for (var i = 1; i < 3; i++) {
            dc.drawLine(w_separation * i, h_separation, w_separation * i, height - h_separation);
        }

        for (var i = 1; i < 5; i++) {
            dc.drawLine(0, h_separation * i, width, h_separation * i);
        }

        dc.drawLine(width / 2, height - h_separation, width / 2, height);

        var array1;
        var array2;
        var array3;
        var array;

        switch (gGrid) {
            case 0:
                array1 = [" 7 ", " 8 ", " 9 "];
                array2 = [" 4 ", " 5 ", " 6 "];
                array3 = [" 1 ", " 2 ", " 3 "];
                array = [array1, array2, array3];

                drawInside(dc, width / 4 + width / 8, height - height / 10, 10, " 0 ");
                drawInside(dc, width - width / 4 - width / 8, height - height / 10, 11, " . ");
                break;

            case 1:
                array1 = [" ( ", " ) ", "CA"];
                array2 = [" + ", " - ", "CE"];
                array3 = [" * ", " ÷ ", " % "];
                array = [array1, array2, array3];

                drawInside(dc, width / 4 + width / 8, height - height / 10, 10, "MS");
                drawInside(dc, width - width / 4 - width / 8, height - height / 10, 11, "MR");
                break;
        }

        for (var row = 0; row < 3; row++) {
            for (var col = 0; col < 3; col++) {
                drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col]);
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height / 10, Graphics.FONT_SMALL, gAnswer, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
