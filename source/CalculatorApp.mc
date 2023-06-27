import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Attention;

//(:background)
class CalculatorApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            if (state.get(:launchedFromComplication) != null) {
                if (Attention has :vibrate) {
                    var vibeData = [ new Attention.VibeProfile(50, 200) ]; // On for half a second
                    Attention.vibrate(vibeData);
                }
            }
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new CalculatorView(), new CalculatorDelegate() ] as Array<Views or InputDelegates>;
    }

    (:glance)
    function getGlanceView() {
        return [ new GlanceView() ];
    }
}

function getApp() as CalculatorApp {
    return Application.getApp() as CalculatorApp;
}