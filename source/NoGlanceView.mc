using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class NoGlanceView extends Ui.View {
    var mLaunched;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        if (mLaunched == null) {
            mLaunched = true;

            var delegate = new CalculatorDelegate();
            var view = new CalculatorView(delegate);

            App.getApp().mCalculatorView = view;
            App.getApp().mCalculatorDelegate = delegate;

			Ui.pushView(view, delegate, Ui.SLIDE_IMMEDIATE);
        }
        else {
            try {
                Ui.popView(Ui.SLIDE_IMMEDIATE); 
            }
            catch (e) {
                System.exit();
            }
        }
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.NoGlanceLayout(dc));
    }
}
