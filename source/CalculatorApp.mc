import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Attention;
using Toybox.Application.Storage;

//(:background)
class CalculatorApp extends Application.AppBase {
    var  mCalculatorView;
    var  mCalculatorDelegate;
    var  mGlanceView;

    function initialize() {
        AppBase.initialize();
    }

    function onSettingsChanged() {
        if ( mGlanceView) {
             mGlanceView.onSettingsChanged();
        }
        if ( mCalculatorView) {
             mCalculatorView.onSettingsChanged();
        }
        if ( mCalculatorDelegate) {
             mCalculatorDelegate.onSettingsChanged();
        }
    }
    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            if (state.get(:launchedFromComplication) != null) {
                if (Attention has :vibrate) {
                    var vibeData = [ new Attention.VibeProfile(50, 200) ]; // On for 200 ms at 50% duty cycle
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
        if (Storage.getValue("fromGlance")) { // Swipe gestures only work when launched from Glance for the main view, hence why we need a subview with watches that don't support Glance or not launched from Glance
            Storage.setValue("fromGlance", false); // In case we stop launching from Glance
             mCalculatorDelegate = new CalculatorDelegate();
             mCalculatorView = new CalculatorView( mCalculatorDelegate);
            return [  mCalculatorView,  mCalculatorDelegate ] as Array<Views or InputDelegates>;
        }
        else { // Sucks, but we have to have an extra view so swipe gestures work in our main view
            return [ new NoGlanceView(), new NoGlanceDelegate() ];
        }
    }

    (:glance)
    function getGlanceView() {
        Storage.setValue("fromGlance", true);
         mGlanceView = new GlanceView();
        return [  mGlanceView ];
    }
}

function getApp() as CalculatorApp {
    return Application.getApp() as CalculatorApp;
}
