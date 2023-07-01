using Toybox.WatchUi as Ui;

class NoGlanceDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        var delegate = new CalculatorDelegate();
        var view = new CalculatorView(delegate);
        Ui.pushView(view, delegate, Ui.SLIDE_UP);
        return true;
    }
}