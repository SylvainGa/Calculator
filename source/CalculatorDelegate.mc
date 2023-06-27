import Toybox.WatchUi;
import Toybox.Timer;

class CalculatorDelegate extends WatchUi.BehaviorDelegate {
    var timer;

    function initialize() {
        BehaviorDelegate.initialize();

        if (timer == null) {
            timer = new Timer.Timer();
        }
    }

    function onSelect() {
        return false;
    }

    function onTap(clickEvent) {
 		var coords = clickEvent.getCoordinates();
		var x = coords[0];
		var y = coords[1];

        timer.start(method(:doUpdate), 100, false);

        gHilight = findTapPos(x, y);

        WatchUi.requestUpdate();
        return true;
    }

    function doUpdate()
    {
        gHilight = 0;
 
        WatchUi.requestUpdate();
    }

    function onBack() {
        return false;
    }

    function onSwipe(swipeEvent) {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
            gGrid++;
            if (gGrid > 1) {
                gGrid = 0;
            }
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
            gGrid--;
            if (gGrid < 0) {
                gGrid = 1;
            }
        }

        WatchUi.requestUpdate();

        return true;
    }

    function findTapPos(x, y) {
        var width = System.getDeviceSettings().screenWidth;
        var h_separation = width / 3;
        var height = System.getDeviceSettings().screenHeight;
        var v_separation = height / 5;

        for (var ty = v_separation, i = 0; ty < height - v_separation * 2; ty += v_separation, i++) {
            for (var tx = 0, j = 0; tx < width - h_separation; tx += h_separation, j++) {
                if (x > tx && x < tx + h_separation && y > ty && y < ty + v_separation) {
                    return i * 3 + j + 1; 
                }
            }
        }

        if (y > height - v_separation) {
            if (x < width / 2) {
                return 10;
            }
            else {
                return 11;
            }
        }

        return 0;
    }
}