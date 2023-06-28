using Toybox.WatchUi as Ui;

class NoGlanceDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        var view = new CalculatorView();
        var delegate = new CalculatorDelegate();
        Ui.pushView(view, delegate, Ui.SLIDE_UP);
        return true;
    }
}