import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Attention;
using Toybox.Application.Storage;
using Toybox.Application.Properties;

enum { Oper_DOT = 0,
       Oper_ParenOpen,
       Oper_ParenClose,
       Oper_CA,
       Oper_CE,
       Oper_Add,
       Oper_Substract,
       Oper_Multiply,
       Oper_Divide,
       Oper_Percent,
       Oper_MC,
       Oper_MR,
       Oper_Equal,
       Oper_Sinus,
       Oper_Cosinus,
       Oper_Tangeant,
       Oper_Log10,
       Oper_LogE,
       Oper_Invert,
       Oper_Square,
       Oper_Exponent
    }

class CalculatorDelegate extends WatchUi.BehaviorDelegate {
    var mTimer;
    var mOps = new [20];
    var mOps_pos; 
    var mHistorySize;
    var mCountHistory;
    var mParenCount;
    var mUnaryPending;
    var mPercentPending;
    var mVibrateOnTouch;
    var mRestoreOnLaunch;

    // Financial var
    var mPresentValue;
    var mFutureValue;
    var mPayment;
    var mYears;
    var mInterestPerYear;
    var mPeriodsPerYear;
    var mRecall;
    var mCalc;
    var mFinancialMissingPV;
    var mFinancialMissingFV;
    var mFinancialMissingDEP;
    var mFinancialMissingYears;
    var mFinancialMissingIY;
    var mFinancialMissingPY;

    // Statistical var
    var mDataChanged;
    var mDataPointsSorted;

    // Drag coord following
    var mDragStartX;
    var mDragStartY;

    function initialize() {
        BehaviorDelegate.initialize();

        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
    
        mOps_pos = 0;
        mCountHistory = true;
        mRecall = false;
        mCalc = false;
        mDataChanged = false;
        mParenCount = 0;
        mUnaryPending = false;
        mPercentPending = false;
        mFinancialMissingPV = false;
        mFinancialMissingFV = false;
        mFinancialMissingDEP = false;
        mFinancialMissingYears = false;
        mFinancialMissingIY = false;
        mFinancialMissingPY = false;

        restoreDataPoints();

        // Read into memory if we had a pending operations when we last left
        try {
            mRestoreOnLaunch = Properties.getValue("restoreOnLaunch");
        }
        catch (e) {
            mRestoreOnLaunch = false;
            Properties.setValue("restoreOnLauch", mRestoreOnLaunch);
        }
        if (mRestoreOnLaunch != null && mRestoreOnLaunch == true) {
            mOps_pos = Storage.getValue("mOps_pos");
            if (mOps_pos == null) {
                mOps_pos = 0;
            }
            else {
                mOps = Storage.getValue("pendingOps");
                gAnswer = Storage.getValue("gAnswer");
                gText = WatchUi.loadResource(Rez.Strings.label_restored);
            }
        }
        else {
            mRestoreOnLaunch = false;
        }

        try {
            mHistorySize = Properties.getValue("historySize");
        }
        catch (e) {
            mHistorySize = 10;
            Properties.setValue("historySize", mHistorySize);
        }
        if (mHistorySize == null) {
            mHistorySize = 10;
        }

        try {
            mVibrateOnTouch = Properties.getValue("vibrateOnTouch");
        }
        catch (e) {
            mVibrateOnTouch = false;
            Properties.setValue("mVibrateOnTouch", false);
        }
        if (mVibrateOnTouch == null) {
            mVibrateOnTouch = false;
        }
    }

    function onSelect() {
        return false;
    }

    function onTap(clickEvent) {
 		var coords = clickEvent.getCoordinates();
		var x = coords[0];
		var y = coords[1];
        var array;

        gCurrentHistoryIndex = null;
        gCurrentHistoryIncIndex = null;
        gError = null;
        gOpText = null;
        gDataEntry = false;
        gDigitsChanged = false;

        mFinancialMissingPV = false;
        mFinancialMissingFV = false;
        mFinancialMissingDEP = false;
        mFinancialMissingYears = false;
        mFinancialMissingIY = false;
        mFinancialMissingPY = false;

        mTimer.start(method(:doUpdate), 100, false);

        gHilight = findTapPos(x, y);

        /*DEBUG
        for (var i = 0; i <= mOps_pos; i++) {
            if (i == 0) {
                System.print("Before: " + mOps_pos.format("%02d") + " ");
            }
            System.print("[" + i.format("%02d") + "]=");
            var c = mOps[i];
            if (c == null) {
                System.print("{null}");
            }
            else if (c instanceof Lang.String) {
                System.print(c);
            }
            else if (c instanceof Lang.Number) {
                var opsArray = ["DOT", "(", ")", "CA", "DD", "+", "-", "*", "/", "%", "MS", "MR"];
                System.print("'" + opsArray[c] + "'");
            }
            else {
                System.print("Unknown: '" + c + "'");
            }

        }
        System.println("");
        /*DEBUG*/

        if (Attention has :vibrate && mVibrateOnTouch) {
            var vibeData = [ new Attention.VibeProfile(25, 50) ]; // On for 50 ms at 25% duty cycle
            Attention.vibrate(vibeData);
        }

        if (gHilight > 0) {
            var prefillResult;

            switch (gPanelOrder[gGrid - 1]) {
                case 1:
                    gDataEntry = true; // Out flag to tell the display code NOT to limit the number of decimals

                    array = ["", "7", "8", "9", "4", "5", "6", "1", "2", "3", "0", Oper_DOT ];
                    if (mOps[mOps_pos] == null || mOps[mOps_pos].equals("0")) {
                        if (array[gHilight] == Oper_DOT) {
                            mOps[mOps_pos] = "0.";
                        }
                        else {
                            mOps[mOps_pos] = array[gHilight];
                        }
                    }
                    else {
                        if (array[gHilight] == Oper_DOT) {
                            if (mOps[mOps_pos].find(".") == null) { // Make sure we only add ONE dot!
                                mOps[mOps_pos] += ".";
                            }
                        }
                        else {
                            mOps[mOps_pos] += array[gHilight];
                        }
                    }
                    gAnswer = mOps[mOps_pos];

                    break;

                case 2:
                    gText = null;

                    switch (gHilight) {
                        case 1: // ParenOpen
                            // '(' must NOT be preceded by a 'number' (a string here)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                break;
                            }
                            // We just tag its place in the queue so ParenClose can do its thing
                            mOps[mOps_pos] = Oper_ParenOpen;
                            mOps_pos++;
                            mOps[mOps_pos] = null;
                            mParenCount++;
                            gOpText = "(x" + mParenCount;
                            break;

                        case 2: // ParenClose
                            if (mParenCount == 0) {
                                break;
                            }

                            do {
                                calcPrevious(Oper_ParenClose);
                            } while (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen);

                            if (mOps_pos > 0) {
                                mOps[mOps_pos - 1] = mOps[mOps_pos];
                                mOps_pos--;
                            }
                            mOps[mOps_pos + 1] = null;
                            mParenCount--;
                            if (mParenCount < 0) {
                                mParenCount = 0;
                            }
                            gOpText = "(x" + mParenCount;
                            break;

                        case 3: // CA
                            for (var i = 0; i < mOps.size(); i++) {
                                mOps[i] = null;
                            }
                            mOps_pos = 0;
                            mParenCount = 0;
                            mUnaryPending = false;
                            mPercentPending = false;
                            gAnswer = null;
                            gError = null;
                            gInvActive = false;
                            gText = null;
                            break;

                        case 4: // Add
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                calcPrevious(Oper_Add);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Add;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            else if (prefillResult == 2) { // Not a number, must be an operation (other than open parenthesise), replace it with this
                                mOps[mOps_pos - 1] = Oper_Add;
                            }
                            gOpText = "+";
                            break;

                        case 5: // Substract (or negative number)
                            // If we didn't type a number, use what's on the display
                            if (mOps[mOps_pos] == null) {
                                if (mOps_pos > 0 && mOps[mOps_pos - 1] instanceof Lang.Number) { // But not if the previous item in our stack is an operation. If so, assume we want to enter a negative numner
                                    gAnswer = "-";
                                    mOps[mOps_pos] = gAnswer;
                                    break;
                                }
                                else {
                                    mOps[mOps_pos] = gAnswer;
                                }
                            }
                            // We currently have something in the input queue
                            if (mOps[mOps_pos] != null) {
                                // And that something is a 'number' (shown as a string)
                                if (mOps[mOps_pos] instanceof Lang.String) {
                                    calcPrevious(Oper_Substract);
                                    mOps_pos++;
                                    mOps[mOps_pos] = Oper_Substract;
                                    mOps_pos++;
                                    mOps[mOps_pos] = null;
                                }
                                // Not a number, must be an operation (other than open parenthesise), replace it with this
                                else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
                                    mOps[mOps_pos - 1] = Oper_Substract;
                                }
                                gOpText = "-";
                            }
                            // Our input queue is empty, what will follow will be a negative number
                            else {
                                gAnswer = "-";
                                mOps[mOps_pos] = gAnswer;
                            }
                            break;

                        case 6: // DD
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String && mOps[mOps_pos].length() > 0) {
                                mOps[mOps_pos] = mOps[mOps_pos].substring(0, mOps[mOps_pos].length() - 1);

                                if (mOps[mOps_pos].length() == 0) {
                                    mOps[mOps_pos] = null;
                                }
                            }

                            if (mOps[mOps_pos] == null) {
                                gAnswer = null;
                            }
                            else {
                                gAnswer = mOps[mOps_pos];
                            }
                            break;

                        case 7: // Multiply
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                calcPrevious(Oper_Multiply);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Multiply;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            else if (prefillResult == 2) { // Not a number, must be an operation (other than open parenthesise), replace it with this
                                mOps[mOps_pos - 1] = Oper_Multiply;
                            }
                            gOpText = "×";
                            break;

                        case 8: // Divide
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                calcPrevious(Oper_Divide);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Divide;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            else if (prefillResult == 2) { // Not a number, must be an operation (other than open parenthesise), replace it with this
                                mOps[mOps_pos - 1] = Oper_Divide;
                            }
                            gOpText = "÷";
                            break;

                        case 9: // Percent
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = getDouble(mOps[mOps_pos]);
                                if (double == null) {
                                    gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                    break;
                                }

                                gAnswer = stripTrailingZeros(double / 100.0d);
                                mOps[mOps_pos] = null;

                                if (mOps_pos > 1 && mOps[mOps_pos - 2] instanceof Lang.String && mOps[mOps_pos - 1] instanceof Lang.Number && (mOps[mOps_pos - 1] == Oper_Add || mOps[mOps_pos - 1] == Oper_Substract)) {
                                    // Percentage operation with an addition or substraction just before
                                    var left = getDouble(mOps[mOps_pos - 2]);
                                    if (left == null) {
                                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                        break;
                                    }

                                    gAnswer = stripTrailingZeros(left * double / 100.0d);
                                    mOps[mOps_pos] = null;
                                }
                                mUnaryPending = true;
                                mPercentPending = true;
                            }
                            gOpText = "%";
                            break;

                        case 10: // MS
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();

                                if (double != 0.0d) {
                                    // Empty? Stock it
                                    if (gMemory == null) {
                                        gMemory = gAnswer;
                                    }
                                    // Otherwise add to it
                                    else {
                                        gMemory = stripTrailingZeros(gMemory.toDouble() + double);
                                    }
                                    Storage.setValue("Memory", gMemory);
                                }
                                // Storing 0 is like erasing it
                                else {
                                    gMemory = null;
                                    Storage.deleteValue("Memory");
                                }
                            }
                            mOps[mOps_pos] = null;

                            break;

                        case 11: // MR
                            if (gMemory != null) {
                                gAnswer = gMemory;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }
                            break;
                    }
                    break;

                case 3:
                    gText = null;

                    switch (gHilight) {
                        case 1: // INV
                            gInvActive = !gInvActive;
                            break;

                        case 2: // Deg/Rad
                            gDegRad = (gDegRad == Degree ? Radian : Degree);
                            break;

                        case 3: // Pi
                            gAnswer = stripTrailingZeros(Math.PI);
                            mUnaryPending = true;
                            mOps[mOps_pos] = gAnswer;
                            break;

                        case 4: // SIN
                        case 5: // COSIN
                        case 6: // TANGEANT
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                try {
                                    if (gInvActive) {
                                        var rad;
                                        switch (gHilight) {
                                            case 4:
                                                rad = Math.asin(double);
                                                break;
                                            case 5:
                                                rad = Math.acos(double);
                                                break;
                                            case 6:
                                                rad = Math.atan(double);
                                                break;
                                        }
                                        if (isFinite(rad) == false) {
                                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                        }
                                        else {
                                            gAnswer = stripTrailingZeros(gDegRad == Degree ? Math.toDegrees(rad) : rad);
                                            mUnaryPending = true;
                                        }

                                        mOps[mOps_pos] = null;
                                    }
                                    else {
                                        var rad = (gDegRad == Degree ? Math.toRadians(double) : double);
                                        switch (gHilight) {
                                            case 4:
                                                double = Math.sin(rad);
                                                break;
                                            case 5:
                                                double = Math.cos(rad);
                                                break;
                                            case 6:
                                                double = Math.tan(rad);
                                                break;
                                        }

                                        if (isFinite(double) == false) {
                                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                        }
                                        else {
                                            gAnswer = stripTrailingZeros(double);
                                            mUnaryPending = true;
                                        }

                                        mOps[mOps_pos] = null;
                                    }
                                }
                                catch (e) {
                                    gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                }
                            }

                            gInvActive = false;

                            break;

                        case 7: // Log
                        case 8: // Ln
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                try {
                                    if (gInvActive) {
                                        if (gHilight == 7) {
                                            double = Math.pow(10, double);
                                        }
                                        else {
                                            double = Math.pow(2.718281828d, double);
                                        }
                                    }
                                    else {
                                        if (gHilight == 7) {
                                            double = Math.log(double, 10);
                                        }
                                        else {
                                            double = Math.ln(double);
                                        }
                                    }

                                    if (isFinite(double) == false) {
                                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                    }
                                    else {
                                        gAnswer = stripTrailingZeros(double);
                                        mUnaryPending = true;
                                    }

                                    mOps[mOps_pos] = null;
                               }
                                catch (e) {
                                    gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                }
                            }

                            gInvActive = false;

                            break;

                        case 9: // 1/x
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (double != 0.0d) {
                                    gAnswer = stripTrailingZeros(1.0d / double);
                                    mUnaryPending = true;
                                    mOps[mOps_pos] = null;
                                }
                                else {
                                    gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                                }
                            }

                            gInvActive = false;

                            break;

                        case 10: // x^2
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                try {
                                    if (gInvActive) {
                                        double = Math.sqrt(double);
                                    }
                                    else {
                                        double *= double;
                                    }

                                    if (isFinite(double) == false) {
                                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                    }
                                    else {
                                        gAnswer = stripTrailingZeros(double);
                                        mUnaryPending = true;
                                    }

                                    mOps[mOps_pos] = null;
                                }
                                catch (e) {
                                    gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                }
                            }

                            gInvActive = false;

                            break;

                        case 11: // x^y
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                calcPrevious(Oper_Exponent);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Exponent;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            else if (prefillResult == 2) { // Not a number, must be an operation (other than open parenthesise), replace it with this
                                mOps[mOps_pos - 1] = Oper_Exponent;
                            }

                            gOpText = "^";
                            gInvActive = false;

                            break;

                    }
                    break;

                case 4:
                    gText = null;

                    switch (gHilight) {
                        case 1: // INV
                            gInvActive = !gInvActive;
                            break;

                        case 2: // Imp/USA
                            gConvUnit = (gConvUnit == Imperial ? USA : Imperial);
                            break;

                        case 3: // F->C
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    double = double * 9.0d / 5.0d;
                                    double += 32.0d;
                                    gAnswer = stripTrailingZeros(double);
                                }
                                else {
                                    double -= 32.0d;
                                    double = double * 5.0d / 9.0d;
                                    gAnswer = stripTrailingZeros(double);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 4: // GAL/LITRE
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                var convUnit = (gConvUnit == Imperial ? 4.54609d : 3.78541d);
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / convUnit);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * convUnit);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 5: // OZ/ML
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 29.5735d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 29.5735d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 6: // CUP/ML
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                var convUnit = (gConvUnit == Imperial ? 284.131d : 240.0d);
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / convUnit);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * convUnit);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 7: // MILE/KM
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 1.60934d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 1.60934d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 8: // FT/CM
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 30.48d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 30.48d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 9: // LB/KG
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 0.453592d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 0.453592d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 10: // MPH/KMH
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 1.60934d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 1.60934d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 11: // ACRE/M2
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                var double = mOps[mOps_pos].toDouble();
                                if (gInvActive) {
                                    gAnswer = stripTrailingZeros(double / 4046.86d);
                                }
                                else {
                                    gAnswer = stripTrailingZeros(double * 4046.86d);
                                }
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;
                    }
                    break;
                case 5:
                    gText = null;

                    switch (gHilight) {
                        case 1: // Fut.V/Loan
                            gFinancialMode = (gFinancialMode == FutureValue ? Loan : FutureValue);
                            break;

                        case 2:
                            gFinancialBeginEnd = (gFinancialBeginEnd == Begin ? End : Begin);
                            break;

                        case 3:
                            break;

                        case 4: // PV
                            if (mRecall) {
                                gAnswer = stripTrailingZeros(mPresentValue);
                                mRecall = false;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mPresentValue = gAnswer.toDouble();
                            if (mPresentValue == 0.0d) {
                                mPresentValue = null;
                            }
                            mOps[mOps_pos] = null;
                            break;


                        case 5: // FV
                            if (mRecall) {
                                gAnswer = stripTrailingZeros(mFutureValue);
                                mRecall = false;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mFutureValue = gAnswer.toDouble();
                            if (mFutureValue == 0.0d) {
                                mFutureValue = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 6: // DEP/PMT
                            if (mRecall) {
                                gAnswer = stripTrailingZeros(mPayment);
                                mRecall = false;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mPayment = gAnswer.toDouble();
                            if (mPayment == 0.0d) {
                                mPayment = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 7: // YEARS
                            if (mRecall) {
                                gAnswer = stripTrailingZeros(mYears);
                                mRecall = false;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mYears = gAnswer.toDouble();
                            if (mYears == 0.0d) {
                                mYears = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 8: // I/Y
                            if (mRecall) {
                                if (mInterestPerYear != null) {
                                    gAnswer = stripTrailingZeros(mInterestPerYear * 100.0d);
                                }
                                else {
                                    gAnswer = "0.";
                                    mOps[mOps_pos] = null;
                                }
                                mUnaryPending = true;
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mInterestPerYear = gAnswer.toDouble() / 100.0d;
                            if (mInterestPerYear == 0.0d) {
                                mInterestPerYear = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 9: // P/Y
                            if (mRecall) {
                                gAnswer = stripTrailingZeros(mPeriodsPerYear);
                                mRecall = false;
                                mUnaryPending = true;
                                mOps[mOps_pos] = null;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }
                            mPeriodsPerYear = gAnswer.toDouble();
                            if (mPeriodsPerYear == 0.0d) {
                                mPeriodsPerYear = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 10: // Recall
                            mRecall = !mRecall;
                            break;

                        case 11: // Calc
                            mCalc = !mCalc;
                            gError = null;
                            break;
                    }
                    break;
                
                case 6:
                    gText = null;

                    if (gHilight != 8) {
                        gDataView = false;
                    }
                    if (gHilight != 9 && gHilight != 11) {
                        gDataReset = false;
                    }
                    switch (gHilight) {
                        case 1: // MEAN
                            if (gDataCount > 0) {
                                gAnswer = stripTrailingZeros(gDataMean);
                                mUnaryPending = true;
                                gText = "MEAN=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 2: // SSDEV
                            if (gDataCount > 1) {
                                var index;
                                var ssdev = 0;
                                for (index = 0; index < gDataCount; index++) {
                                    var variance = (gDataPoints[index] - gDataMean);
                                    ssdev += variance * variance;
                                }
                                ssdev = ssdev / (gDataCount - 1);
                                ssdev = Math.sqrt(ssdev);
                                gAnswer = stripTrailingZeros(ssdev);
                                mUnaryPending = true;
                                gText = "SSDEV=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 3: // PSDEV
                            if (gDataCount > 0) {
                                var index;
                                var psdev = 0;
                                for (index = 0; index < gDataCount; index++) {
                                    var variance = (gDataPoints[index] - gDataMean);
                                    psdev += variance * variance;
                                }
                                psdev = psdev / gDataCount;
                                psdev = Math.sqrt(psdev);
                                gAnswer = stripTrailingZeros(psdev);
                                mUnaryPending = true;
                                gText = "PSDEV=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 4: // MEDIAN
                            if (gDataCount > 0) {
                                if (mDataChanged) {
                                    mDataPointsSorted = gDataPoints;
                                    bubble_sort(mDataPointsSorted); // Data needs to be in order
                                    mDataChanged = false;
                                }
                                var median;
                                if (gDataCount % 2 == 0) { // Even number of data points
                                    median = (mDataPointsSorted[(gDataCount / 2) - 1] + mDataPointsSorted[((gDataCount / 2) + 1) - 1]) / 2;
                                }
                                else { // Odd number of data points
                                    median = mDataPointsSorted[((gDataCount + 1) / 2) - 1];
                                }
                                
                                gAnswer = stripTrailingZeros(median);
                                mUnaryPending = true;
                                gText = "MEDIAN=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 5: // VARIANCE
                            if (gDataCount > 0) {
                                var index;
                                var variance = 0;
                                for (index = 0; index < gDataCount; index++) {
                                    var diff = (gDataPoints[index] - gDataMean);
                                    variance += diff * diff;
                                }
                                variance = variance / gDataCount;
                                gAnswer = stripTrailingZeros(variance);
                                mUnaryPending = true;
                                gText = "VARIANCE=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 6: // MODE
                            if (gDataCount > 0) {
                                if (mDataChanged) {
                                    mDataPointsSorted = gDataPoints;
                                    bubble_sort(mDataPointsSorted); // Data needs to be in order
                                    mDataChanged = false;
                                }

                                // Let's start by initializing our current and highest to the first array element
                                var currentValue = mDataPointsSorted[0];
                                var currentCount = 1;
                                var highestValue = mDataPointsSorted[0];
                                var highestCount = 1;
                                for (var i = 1; i < gDataCount; i++) { // Go through the (sorted) array
                                    if (mDataPointsSorted[i] == currentValue) {
                                        currentCount++; // Still the same value, increase our count
                                    }
                                    else {
                                        if (currentCount > highestCount) { // We have a new highest count, switch to it
                                            highestCount = currentCount;
                                            highestValue = currentValue;
                                        }
                                        currentCount = 1;
                                        currentValue = mDataPointsSorted[i];
                                    }
                                }                                
                                gAnswer = stripTrailingZeros(highestValue);
                                mUnaryPending = true;
                                gText = "MODE=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 7: // RANGE
                            if (gDataCount > 0) {
                                if (mDataChanged) {
                                    mDataPointsSorted = gDataPoints;
                                    bubble_sort(mDataPointsSorted); // Data needs to be in order
                                    mDataChanged = false;
                                }
                                
                                gAnswer = stripTrailingZeros(mDataPointsSorted[gDataCount - 1] - mDataPointsSorted[0]);
                                mUnaryPending = true;
                                gText = "RANGE=";
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 8: // View
                            if (gDataCount > 0) {
                                gDataView = !gDataView;
                                if (gDataView) {
                                    gAnswer = stripTrailingZeros(gDataPoints[0]);
                                    mUnaryPending = true;
                                    gDataViewPos = 0;
                                }
                            }
                            else {
                                gError = WatchUi.loadResource(Rez.Strings.label_noData);
                            }
                            break;

                        case 9: // Reset
                            gDataReset = !gDataReset;
                            break;

                        case 10: // Add
                            prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                            if (prefillResult == 0) { // Invalid number entered
                                break;
                            }
                            else if (prefillResult == 1) { // Valid number entered
                                gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                            }

                            if (gAnswer == null) {
                                gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                break;
                            }

                            mDataChanged = true;

                            gDataCount++;
                            gDataSum += gAnswer.toDouble();
                            gDataMean =  gDataSum / gDataCount;
                            if (gDataPoints == null) {
                                gDataPoints = [];
                            }                        
                            gDataPoints.add(gAnswer.toDouble());

                            gText = "N=" + gDataCount;

                            saveDataPoints();

                            mOps[mOps_pos] = null;
                            break;

                        case 11: // Del
                            mDataChanged = true;

                            if (gDataReset) {
                                gDataCount = 0;
                                gDataSum = 0;
                                gDataMean = 0;
                                gDataPoints = null;
                                gDataReset = false;

                                gText = "N=0";
                            }
                            else {
                                prefillResult = prefillmOps();  // Use gAnswer in certain conditions
                                if (prefillResult == 0) { // Invalid number entered
                                    break;
                                }
                                else if (prefillResult == 1) { // Valid number entered
                                    gAnswer = stripTrailingZeros(mOps[mOps_pos].toDouble());
                                }

                                if (gDataPoints != null && gDataPoints.indexOf(gAnswer.toDouble()) != -1) {
                                    gDataPoints.remove(gAnswer.toDouble());
                                    gDataCount--;
                                    if (gDataCount > 0) {
                                        gDataSum -= gAnswer.toDouble();
                                        gDataMean = gDataSum / gDataCount;
                                    }
                                    else {
                                        gDataSum = 0;
                                        gDataMean = 0;
                                        gDataPoints = null;

                                    }
                                    gText = "N=" + gDataCount;
                                }
                                else {
                                    gError = WatchUi.loadResource((gDataPoints != null ? Rez.Strings.label_notPresent : Rez.Strings.label_noData));
                                }
                            }

                            saveDataPoints();

                            mOps[mOps_pos] = null;
                            break;
                    }
                    break;
            }

            if (mOps_pos == 0 && mOps[0] == null && gAnswer == null) {
                if (mRestoreOnLaunch == true) {
                    Storage.deleteValue("pendingOps");
                    Storage.deleteValue("mOps_pos");
                    Storage.deleteValue("gAnswer");
                }
            }
            else {
                if (mRestoreOnLaunch == true) {
                    Storage.setValue("pendingOps", mOps);
                    Storage.setValue("mOps_pos", mOps_pos);
                    Storage.setValue("gAnswer", gAnswer);
                }
            }
        }
        else {
            if (mRestoreOnLaunch == true) {
                Storage.deleteValue("pendingOps");
                Storage.deleteValue("mOps_pos");
                Storage.deleteValue("gAnswer");
            }
            gText = null;

            if (mOps[mOps_pos] == null) {
                mOps[mOps_pos] = gAnswer;
            }
            if (mOps[mOps_pos] != null) {
                calcPrevious(Oper_Equal);
                gAnswer = stripTrailingZeros(mOps[mOps_pos]);
                // See if we have empty slots for our history
                if (mCountHistory) {
                    var count = 0;
                    for (var i = 0; i < mHistorySize; i++) {
                        if (Storage.getValue("history_" + i) != null) {
                            count++;
                        }
                    }

                    // If we have less history value than our requested size, add to the end
                    if (count < mHistorySize) {
                        gCurrentHistoryIndex = count;
                    }
                    // Otherwise use the current position and don't count again
                    else {
                        mCountHistory = false;
                        gCurrentHistoryIndex = Storage.getValue("HistoryIndex");
                    }
                }
                else {
                    gCurrentHistoryIndex = Storage.getValue("HistoryIndex");
                }

                if (gCurrentHistoryIndex == null || gCurrentHistoryIndex >= mHistorySize) {
                    gCurrentHistoryIndex = 0;
                }
                Storage.setValue("history_" + gCurrentHistoryIndex, gAnswer);
                gCurrentHistoryIndex++;
                if (gCurrentHistoryIndex >= mHistorySize) {
                    gCurrentHistoryIndex = 0;
                }
                Storage.setValue("HistoryIndex", gCurrentHistoryIndex);
                gCurrentHistoryIncIndex = null;

                mParenCount = 0;
                mUnaryPending = false;
                mPercentPending = false;
                mOps_pos = 0;
                mOps[mOps_pos] = null;
                gOpText = "=";
            }
        }

        /*DEBUG
        for (var i = 0; i <= mOps_pos; i++) {
            if (i == 0) {
                System.print("After : " + mOps_pos.format("%02d") + " ");
            }
            System.print("[" + i.format("%02d") + "]=");
            var c = mOps[i];
            if (c == null) {
                System.print("{null}");
            }
            else if (c instanceof Lang.String) {
                System.print(c);
            }
            else if (c instanceof Lang.Number) {
                var opsArray = ["DOT", "(", ")", "CA", "DD", "+", "-", "*", "/", "%", "MS", "MR"];
                System.print("'" + opsArray[c] + "'");
            }
            else {
                System.print("Unknown: '" + c + "'");
            }
        }
        System.println("");
        /*DEBUG*/


        WatchUi.requestUpdate();
 
        return true;
    }

    function saveDataPoints() {
        Storage.setValue("DataPoints", gDataPoints);
    }

    function restoreDataPoints() {
        gDataPoints = Storage.getValue("DataPoints");
        if (gDataPoints != null) {
            gDataCount = gDataPoints.size();
            gDataMean = 0.0d;
            if (gDataCount > 0) {
                for (var i = 0; i < gDataCount; i++) {
                    gDataMean += gDataPoints[i];
                }
                gDataMean /= gDataCount;
            }
        }
    }

    function calcFinancial(which) {
        var double;
        var futureValue;
        var missing = false;

        mCalc = false;

        switch (gFinancialMode) {
            case FutureValue:
                // F=PV∗(1+Int)^n + PMT∗((1+I)^n-1)/I
                switch (which) {
                    case 4: // PV
                        if (mFutureValue == null) {
                            mFinancialMissingFV = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "PV=";
                        try {
                            futureValue = mFutureValue;
                            if (mPayment != null) {
                                double = mPayment * (Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0d) / (mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1 : (1.0d + mInterestPerYear / mPeriodsPerYear)); // Recurrent deposit
                                futureValue -= double; 

                            }
                            double = futureValue / Math.pow((1.0d + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // From future value
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mPresentValue =  (double == 0.0d ? null : double);
                        }
                        break;

                    case 5: // FV
                        if (mPayment == null && mPresentValue == null) {
                            mFinancialMissingPV = true;
                            mFinancialMissingDEP = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "FV=";
                        try {
                            double = 0.0d;
                            if (mPresentValue != null) {
                                double = mPresentValue * Math.pow((1.0d + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // From present value
                            }
                            if (mPayment != null) {
                                double += mPayment * (Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0d) / (mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1 : (1.0d + mInterestPerYear / mPeriodsPerYear)); // Adding it recurrent deposit
                            }
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mFutureValue = double;
                        }
                        break;

                    case 6: // DEP
                        if (mFutureValue == null) {
                            mFinancialMissingFV = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "DEP=";
                        try {
                            futureValue = mFutureValue;
                            if (mPresentValue != null) {
                                double = mPresentValue * Math.pow((1.0d + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // Present value
                                futureValue -= double;
                            }
                            double = futureValue / (((Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0d) / (mInterestPerYear / mPeriodsPerYear)) * (gFinancialBeginEnd == End ? 1 : (1.0d + mInterestPerYear / mPeriodsPerYear))); // From payment
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mPayment = (double == 0.0d ? null : double);
                        }
                        break;

                    case 7: // YEARS
                        if (mFutureValue == null) {
                            mFinancialMissingFV = true;
                            missing = true;
                        }
                        if (mPresentValue == null && mPayment == null) {
                            mFinancialMissingPV = true;
                            mFinancialMissingDEP = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "YEARS=";
                        try {
                            if (mPresentValue != null && mPayment == null) {
                                double = Math.ln(mFutureValue / mPresentValue) / Math.ln(1.0d + mInterestPerYear / mPeriodsPerYear) / mPeriodsPerYear;
                            }
                            else if (mPresentValue == null && mPayment != null) {
                                // ln(1 + (FV / P) * r) / ln(1 + r)
                                // ln(1 + (FV / (P * (1 + r))) * r) / ln(1 + r)
                                double = Math.ln(1.0d + mFutureValue / (mPayment * (gFinancialBeginEnd == End ? 1 : (1.0d + mInterestPerYear / mPeriodsPerYear)))  * (mInterestPerYear / mPeriodsPerYear)) / Math.ln(1.0d + ((mInterestPerYear / mPeriodsPerYear)));
                            }
                            else {
                                // End:   ln{(FV+PD/r)/(PV+PD/r)}/ln(1+r)
                                // Begin: ln{(FV+PD/[r*(1+r)])/(PV+PD/[r*(1+r)])}/ln(1+r)
                                // double = Math.ln((mFutureValue + mPayment / ((mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1.0d : (1.0d + (mInterestPerYear / mPeriodsPerYear))))) / (mPresentValue + mPayment / ((mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1.0d : (1.0d + (mInterestPerYear / mPeriodsPerYear)))))) / Math.ln(1.0d + ((mInterestPerYear / mPeriodsPerYear)));
                                var int = mInterestPerYear / mPeriodsPerYear;
                                var intCalc = 1.0d + int;
                                var beginEnd = (gFinancialBeginEnd == End ? 1.0d : intCalc);
                                var pmt = mFutureValue + mPayment / (int * beginEnd);
                                var pv = mPresentValue + mPayment / (int *  beginEnd);

                                double = Math.ln(pmt / pv) / Math.ln(intCalc);
                                if (gFinancialBeginEnd == Begin) {
                                    double /= intCalc;
                                }

                                double /= mPeriodsPerYear;
                            }
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mYears = double;
                        }
                        break;

                    case 8: // I/Y
                        if (mFutureValue == null) {
                            mFinancialMissingFV = true;
                            missing = true;
                        }
                        if (mPresentValue == null) {
                            mFinancialMissingPV = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "I/Y=";
                        try {
                            double = (Math.pow(mFutureValue / mPresentValue, (1.0d / (mYears * mPeriodsPerYear))) - 1.0d) * 100.0d * mPeriodsPerYear;
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mInterestPerYear = double / 100.0d;
                        }
                        break;

                    case 9: // P/Y
                        gError = WatchUi.loadResource(Rez.Strings.label_unavailable);
                        break;
                }
                break;
            case Loan:
                switch (which) {
                    case 4: // L
                        if (mPayment == null) {
                            mFinancialMissingDEP = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "LOAN=";
                        try {
                            double = mPayment / (mInterestPerYear / mPeriodsPerYear * Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear)) * (Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0d);
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mPresentValue = (double == 0.0d ? null : double);
                        }
                        break;

                    case 5: // TC
                        if (mPayment == null) {
                            mFinancialMissingDEP = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "TC=";
                        try {
                            double = mPayment * mYears * mPeriodsPerYear;
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mFutureValue = (double == 0.0d ? null : double);
                        }
                        break;

                    case 6: // PMT
                        if (mPresentValue == null) {
                            mFinancialMissingPV = true;
                            missing = true;
                        }
                        if (mYears == null) {
                            mFinancialMissingYears = true;
                            missing = true;
                        }
                        if (mInterestPerYear == null) {
                            mFinancialMissingIY = true;
                            missing = true;
                        }
                        if (mPeriodsPerYear == null || mPeriodsPerYear == 0.0d) {
                            mFinancialMissingPY = true;
                            missing = true;
                        }
                        if (missing) {
                            gError = WatchUi.loadResource(Rez.Strings.label_missingData);
                            break;
                        }
                        gText = "PMT=";
                        try {
                            double = mPresentValue * (mInterestPerYear / mPeriodsPerYear * Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear)) / (Math.pow(1.0d + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0d);
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(double)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailingZeros(double);
                            mPayment = (double == 0.0d ? null : double);
                        }
                        break;

                    case 7: // YEARS
                        gError = WatchUi.loadResource(Rez.Strings.label_unavailable);
                        break;

                    case 8: // I/Y
                        gError = WatchUi.loadResource(Rez.Strings.label_unavailable);
                        break;

                    case 9: // P/Y
                        gError = WatchUi.loadResource(Rez.Strings.label_unavailable);
                        break;
                }

                break;
        }

    }

    function prefillmOps() {
        // See if we should use gAnswer for our value. 
        // Conditions are:
        //      We currently have nothing stored in our stack
        //      We're at the top of our stack or
        //      What we have before us is a command (allows us to change command as long as we dont type a number or a '-' (which means negative number will follow))
        //      But if we have a % command pending, it's ok to have a command so do use gAnswer
        if (mOps[mOps_pos] == null && (mOps_pos == 0 || (mOps_pos > 0 && (!(mOps[mOps_pos - 1] instanceof Lang.Number) || mUnaryPending || mPercentPending)))) {
            mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
        }
 
        mUnaryPending = false; // Wether we used mUnaryPending or not, we reset it to false so it doesn't linger around

        // Make sure that 'number' is not a lone '-'
        if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
            if (mOps[mOps_pos].equals("-")) { // Can't be just a '-'
                gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                return 0;  // Error, abort
            }
            return 1; // We're a number
        }
        else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
            return 2; // We're a command other than an open parenthesis
        }
        return 3; // If we get here, we ignore what was entered (so far)
    }

    function clearStack() {
        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
        do {
            mOps[mOps_pos] = null;
            mOps_pos--;
        } while (mOps_pos >= 0);
        mOps_pos = 0;
        mParenCount = 0;
        mUnaryPending = false;
        mPercentPending = false;
    }

    function getDouble(double)
    {
        if (double != null) {
            try {
                double = double.toDouble();
            }
            catch (e) {
                // Clear up the stack so we don't get stuck in an infinite loop
                clearStack();
                return null;
            }
        }
        
        if (double == null) {
            // Clear up the stack so we don't get stuck in an infinite loop
            clearStack();
            return null;
        }
        
        return double;
    }

    function calcPrevious(oper) {
        if (mOps_pos < 2) {
            // Nothing to calculate
            return;
        }

        if (mOps[mOps_pos - 1] != null && mOps[mOps_pos - 1] instanceof Lang.Number && mOps[mOps_pos - 1] == Oper_ParenOpen) {
        //if (left != null && left instanceof Lang.Number && left == Oper_ParenOpen) {
            // Right behind us is an opened parenthesis, skip the calculation until we reach that corresponding close parenthesis
            return;
        }

        var left = mOps[mOps_pos - 2];
        var right = mOps[mOps_pos];
        if (right == null) {
            right = gAnswer;
        }

        left = getDouble(left);
        right = getDouble(right);
        if (left == null || right == null) {
            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
            return;
        }

        switch (mOps[mOps_pos - 1]) {
            case Oper_Add:
                if ((oper == Oper_Multiply || oper == Oper_Divide || oper == Oper_Exponent) && mPercentPending == false) {
                    return;
                }

                mPercentPending = false;
                gAnswer = stripTrailingZeros(left + right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Substract:
                if ((oper == Oper_Multiply || oper == Oper_Divide || oper == Oper_Exponent) && mPercentPending == false) {
                    return;
                }

                mPercentPending = true;
                gAnswer = stripTrailingZeros(left - right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Multiply:
                gAnswer = stripTrailingZeros(left * right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                calcPrevious(oper);
                break;

            case Oper_Divide:
                if (right != 0.0d) {
                    gAnswer = stripTrailingZeros(left / right);
                    mOps[mOps_pos] = null;
                    mOps_pos--;
                    mOps[mOps_pos] = null;
                    mOps_pos--;
                    mOps[mOps_pos] = gAnswer;
                    calcPrevious(oper);
                }
                else {
                    gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                    clearStack();
                }
                break;

            case Oper_Exponent:
                if (gInvActive) {
                    if (right != 0.0d) {
                        gAnswer = stripTrailingZeros(Math.pow(left, 1.0d / right));
                    }
                    else {
                        gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                        clearStack();
                    }
                }
                else {
                    gAnswer = stripTrailingZeros(Math.pow(left, right));
                }

                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                calcPrevious(oper);
                break;

            case Oper_ParenOpen:
                break; // Just a place holder so I know we saw it and nothing was done to it here
        }
    }

    function doUpdate()
    {
        gHilight = 0;
 
        WatchUi.requestUpdate();
    }

    function onBack() {
        return false;
    }

    function onDrag(dragEvent ) {
        var coord = dragEvent.getCoordinates();

        if (dragEvent.getType() == WatchUi.DRAG_TYPE_START) {
            mDragStartX = coord[0];
            mDragStartY = coord[1];
        }
        else if (dragEvent.getType() == WatchUi.DRAG_TYPE_STOP) {
            if (mDragStartY == null || mDragStartX == null) { // This shouldn't happened but I've seen unhandled exception for mDragStartY below!
                return true;
            }
            var height = System.getDeviceSettings().screenHeight;
            if (mDragStartY < height / 5) { // 'Swiped' the answer portion, only test if left or right
                if (gDataEntry) {
                    return true; // No digit resizing while entering data
                }

                gDigitsChanged = true;

                if (mDragStartX > coord[0]) {  // 'Swiped' left
                    gDigits++;
                    if (gDigits > 8) {
                        gDigits = 8;
                    }
                }
                else {   // 'Swiped' right
                    var answerStr = limitDigits(gAnswer); // Get the number we should be displaying so we can drop the last digit
                    var dotPos = answerStr.find(".");
                    if (dotPos != null) {
                        gDigits = answerStr.length() - (dotPos + 1) - 1;
                    }
                    else { // No dot, simply decrease by one
                        gDigits--;
                    }

                    if (gDigits < 0) {
                        gDigits = 0;
                    }
                }

                gText = "D=" + gDigits;
                Storage.setValue("digits", gDigits);
            }
            // Main area of the screen was swiped, keep the direction with the most movement
            else {
                gDigitsChanged = false;

                var xMovement = (mDragStartX - coord[0]).abs();
                var yMovement = (mDragStartY - coord[1]).abs();

                if (xMovement > yMovement) { // We 'swiped' left or right predominantly
                    if (mDragStartX > coord[0]) { // Like WatchUi.SWIPE_LEFT
                        gInvActive = false;
                        gText = null;
                        gDataView = false;
                        gGrid++;
                        if (gGrid > GRID_COUNT) {
                            gGrid = 1;
                        }
                    }
                    else { // Like  WatchUi.SWIPE_RIGHT
                        gInvActive = false;
                        gText = null;
                        gDataView = false;
                        gGrid--;
                        if (gGrid < 1) {
                            gGrid = GRID_COUNT;
                        }
                    }
                }
                else { // We 'swiped' up or down predominantly
                    if (mDragStartY > coord[1]) { // Like WatchUi.SWIPE_UP
                        if (gDataView) {
                            gDataViewPos--;
                            if (gDataViewPos < 0) {
                                gDataViewPos = gDataCount - 1;
                            }
                            gAnswer = stripTrailingZeros(gDataPoints[gDataViewPos]);
                            mUnaryPending = true;
                        }
                        else {
                            if (mHistorySize == 0) {
                                return false;
                            }

                            gText = null;
                            var index;
                            if (gCurrentHistoryIndex != null) { // We've been through this path already, grab where we were at
                                if (gCurrentHistoryIncIndex == null) {
                                    gCurrentHistoryIncIndex = 1;
                                }
                                index = gCurrentHistoryIndex;
                            }
                            else {
                                gCurrentHistoryIncIndex = 1; // First time around. Start from where we'll store our next answer
                                index = Storage.getValue("HistoryIndex");
                            }
                            if (index == null) {
                                index = 1; // We will decrement it to 0 in the do/while loop below
                            }

                            var start = index;
                            var answer;
                            do {
                                index--;
                                if (index < 0) { // Wrap around if we've hit the top of our list
                                    index = mHistorySize - 1;
                                }
                                answer = Storage.getValue("history_" + index);
                            } while (answer == null && index != start);

                            if (answer != null) {
                                gCurrentHistoryIndex = index; // This is the one we're at now. Keep for the next swipe up/down
                                gCurrentHistoryIncIndex--; // We got a new one so decrease our index on screen
                                if (gCurrentHistoryIncIndex < 0) {
                                    // Need to find the quantity of non null in our history list
                                    var count = 0;
                                    for (var i = 0; i < mHistorySize; i++) {
                                        if (Storage.getValue("history_" + i) != null) {
                                            count++;
                                        }
                                    }
                                    gCurrentHistoryIncIndex = count - 1;
                                }
                                gAnswer = answer;
                                mUnaryPending = true;
                            }
                            else {
                                gCurrentHistoryIncIndex = null;
                            }
                        }
                    }
                    else { // Like WatchUi.SWIPE_UP
                        if (gDataView) {
                            gDataViewPos++;
                            if (gDataViewPos >= gDataCount) {
                                gDataViewPos = 0;
                            }
                            gAnswer = stripTrailingZeros(gDataPoints[gDataViewPos]);
                            mUnaryPending = true;
                        }
                        else {
                            if (mHistorySize == 0) {
                                return false;
                            }

                            gText = null;
                            var index;
                            if (gCurrentHistoryIndex != null) { // We've been through this path already, grab where we were at
                                if (gCurrentHistoryIncIndex == null) {
                                    gCurrentHistoryIncIndex = 0;
                                }
                                index = gCurrentHistoryIndex;
                            }
                            else {
                                gCurrentHistoryIncIndex = 0; // First time around. Start from where we'll store our next answer
                                index = Storage.getValue("HistoryIndex");
                            }
                            if (index == null || index >= mHistorySize) {
                                index = -1; // We'll increase it to 0 in the do/while loop below
                            }

                            // Find the next non null entry in our history
                            var start = index;
                            var answer;
                            do {
                                index++; // Get the next one since we point to the current one
                                if (index >= mHistorySize) {
                                    if (start == -1) {
                                        start = index;
                                        break;
                                    }
                                    index = 0;
                                }

                                answer = Storage.getValue("history_" + index);

                            } while (answer == null && index != start);

                            if (answer != null) {
                                gCurrentHistoryIndex = index; // This is the one we're at now. Keep for the next swipe up/down
                                gCurrentHistoryIncIndex++; // We got a new one so increase our index on screen
                                var count = 0;
                                for (var i = 0; i < mHistorySize; i++) {
                                    if (Storage.getValue("history_" + i) != null) {
                                        count++;
                                    }
                                }
                                if (gCurrentHistoryIncIndex > count - 1) {
                                    gCurrentHistoryIncIndex = 0;
                                }
                                gAnswer = answer;
                                mUnaryPending = true;
                            }
                            else {
                                gCurrentHistoryIncIndex = null;
                            }
                        }
                    }
                }
            }
        }
        WatchUi.requestUpdate();

        return true;
    }

    function onSwipe(swipeEvent) {
        return true; // Required otherwise a swipe right would kill the app
    }
    
    function findTapPos(x, y) {
        var width = System.getDeviceSettings().screenWidth;
        var h_separation = width / 3;
        var height = System.getDeviceSettings().screenHeight;
        var v_separation = height / 5;

        for (var ty = v_separation, i = 0; ty <= height - v_separation * 2; ty += v_separation, i++) {
            for (var tx = 0, j = 0; tx <= width - h_separation; tx += h_separation, j++) {
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

    function isFinite(x) {

        var float = x.toFloat();
        return !float.equals(NaN) && !float.equals(Math.acos(45));
    }

    function bubble_sort(array) {
        var n = array.size();

        do {
            var newn = 0;
            for (var i = 1; i < n; ++i) {
                if (array[i] < array[i - 1]) {
                    var tmp = array[i - 1];
                    array[i - 1] = array[i];
                    array[i] = tmp;

                    newn = i;
                }
            }
            n = newn;
        } while (n != 0);
    }
}
