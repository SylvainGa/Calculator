import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Math;
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
    var mOps = new [100];
    var mOps_pos; 
    var mHistorySize;
    var mCountHistory;

    // Financial var
    var mPresentValue;
    var mFutureValue;
    var mPayment;
    var mYears;
    var mInterestPerYear;
    var mPeriodsPerYear;
    var mRecall;
    var mCalc;

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
        gOpText = null;
        gDataEntry = false;
        gDigitsChanged = false;

        mTimer.start(method(:doUpdate), 100, false);

        gHilight = findTapPos(x, y);
        if (gHilight > 0) {
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
                    switch (gHilight) {
                        case 1: // ParenOpen
                            // We just tag its place in the queue so ParenClose can do its thing
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                break;
                            }
                            mOps[mOps_pos] = Oper_ParenOpen;
                            mOps_pos++;
                            mOps[mOps_pos] = null;
                            gOpText = "(";
                            break;

                        case 2: // ParenClose
                            do {
                                calcPrevious(Oper_ParenClose);
                            } while (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen);

                            if (mOps_pos > 0) {
                                mOps[mOps_pos - 1] = mOps[mOps_pos];
                                mOps_pos--;
                            }
                            mOps[mOps_pos + 1] = null;
                            gOpText = ")";
                            break;

                        case 3: // CA
                            for (var i = 0; i < mOps.size(); i++) {
                                mOps[i] = null;
                            }
                            mOps_pos = 0;
                            gAnswer = null;
                            gError = null;
                            gInvActive = false;
                            gText = null;
                            break;

                        case 4: // Add
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                calcPrevious(Oper_Add);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Add;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            // Not a number, must be an operation (other than open parenthesise), replace it with this
                            else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
                                mOps[mOps_pos - 1] = Oper_Add;
                            }
                            gOpText = "+";
                            break;

                        case 5: // Substract (or negative number)
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = gAnswer; // Different from the other here to accomodate for the leading '-'
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
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                calcPrevious(Oper_Multiply);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Multiply;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            // Not a number, must be an operation (other than open parenthesise), replace it with this
                            else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
                                mOps[mOps_pos - 1] = Oper_Multiply;
                            }
                            gOpText = "*";
                            break;

                        case 8: // Divide
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                calcPrevious(Oper_Divide);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Divide;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            // Not a number, must be an operation (other than open parenthesise), replace it with this
                            else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
                                mOps[mOps_pos - 1] = Oper_Divide;
                            }
                            gOpText = "÷";
                            break;

                        case 9: // Percent
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                calcPrevious(Oper_Percent);
                            }
                            gOpText = "%";
                            break;

                        case 10: // MS
                            if (mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = gAnswer;
                            }
                            if (mOps[mOps_pos] != null) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos]);
                                if (gAnswer.toFloat() != 0.0) {
                                    gMemory = gAnswer;
                                    Storage.setValue("Memory", gMemory);
                                }
                                // Storing 0 is like erasing it
                                else {
                                    gMemory = null;
                                    Storage.deleteValue("Memory");
                                }
                                mOps[mOps_pos] = null;
                            }

                            break;

                        case 11: // MR
                            if (gMemory != null) {
                                gAnswer = gMemory;
                                mOps[mOps_pos] = null;
                            }
                            break;
                    }
                    break;

                case 3:
                    switch (gHilight) {
                        case 1: // INV
                            gInvActive = !gInvActive;
                            break;

                        case 2: // Deg/Rad
                            gDegRad = (gDegRad == Degree ? Radian : Degree);
                            break;

                        case 3: // Pi
                            gAnswer = stripTrailinZeros(Math.PI);
                            mOps[mOps_pos] = gAnswer;
                            break;

                        case 4: // SIN
                        case 5: // COSIN
                        case 6: // TANGEANT
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                try {
                                    if (gInvActive) {
                                        var rad;
                                        switch (gHilight) {
                                            case 4:
                                                rad = Math.asin(float);
                                                break;
                                            case 5:
                                                rad = Math.acos(float);
                                                break;
                                            case 6:
                                                rad = Math.atan(float);
                                                break;
                                        }
                                        if (isFinite(rad) == false) {
                                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                        }

                                        gAnswer = stripTrailinZeros(gDegRad == Degree ? Math.toDegrees(rad) : rad);
                                        mOps[mOps_pos] = null;
                                    }
                                    else {
                                        var rad = (gDegRad == Degree ? Math.toRadians(float) : float);
                                        switch (gHilight) {
                                            case 4:
                                                float = Math.sin(rad);
                                                break;
                                            case 5:
                                                float = Math.cos(rad);
                                                break;
                                            case 6:
                                                float = Math.tan(rad);
                                                break;
                                        }

                                        if (isFinite(float) == false) {
                                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                        }
                                        else {
                                            gAnswer = stripTrailinZeros(float);
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
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                try {
                                    if (gInvActive) {
                                        if (gHilight == 7) {
                                            float = Math.pow(10, float);
                                        }
                                        else {
                                            float = Math.pow(2.718281828, float);
                                        }
                                    }
                                    else {
                                        if (gHilight == 7) {
                                            float = Math.log(float, 10);
                                        }
                                        else {
                                            float = Math.ln(float);
                                        }
                                    }

                                    if (isFinite(float) == false) {
                                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                    }
                                    else {
                                        gAnswer = stripTrailinZeros(float);
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
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (float != 0.0) {
                                    gAnswer = stripTrailinZeros(1.0 / float);
                                    mOps[mOps_pos] = null;
                                }
                                else {
                                    gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                                }
                            }

                            gInvActive = false;

                            break;

                        case 10: // x^2
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                try {
                                    if (gInvActive) {
                                        float = Math.sqrt(float);
                                    }
                                    else {
                                        float *= float;
                                    }

                                    if (isFinite(float) == false) {
                                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                                    }
                                    else {
                                        gAnswer = stripTrailinZeros(float);
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
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                calcPrevious(Oper_Exponent);
                                mOps_pos++;
                                mOps[mOps_pos] = Oper_Exponent;
                                mOps_pos++;
                                mOps[mOps_pos] = null;
                            }
                            // Not a number, must be an operation (other than open parenthesise), replace it with this
                            else if (mOps_pos > 0 && mOps[mOps_pos - 1] != Oper_ParenOpen) {
                                mOps[mOps_pos - 1] = Oper_Exponent;
                            }

                            gInvActive = false;

                            break;

                    }
                    break;

                case 4:
                    switch (gHilight) {
                        case 1: // INV
                            gInvActive = !gInvActive;
                            break;

                        case 2: // Imp/USA
                            gConvUnit = (gConvUnit == Imperial ? USA : Imperial);
                            break;

                        case 3: // F->C
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    float = float * 9.0 / 5.0;
                                    float += 32.0;
                                    gAnswer = stripTrailinZeros(float);
                                }
                                else {
                                    float -= 32.0;
                                    float = float * 5.0 / 9.0;
                                    gAnswer = stripTrailinZeros(float);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 4: // GAL/LITRE
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                var convUnit = (gConvUnit == Imperial ? 4.54609 : 3.78541);
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / convUnit);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * convUnit);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 5: // OZ/ML
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 29.5735);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 29.5735);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 6: // CUP/ML
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                var convUnit = (gConvUnit == Imperial ? 284.131 : 240);
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / convUnit);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * convUnit);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 7: // MILE/KM
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 1.60934);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 1.60934);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 8: // FT/CM
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 30.48);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 30.48);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 9: // LB/KG
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 0.453592);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 0.453592);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 10: // MPH/KMH
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 1.60934);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 1.60934);
                                }
                                mOps[mOps_pos] = null;
                            }

                            gInvActive = false;
                            break;

                        case 11: // ACRE/M2
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string)
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                var float = mOps[mOps_pos].toFloat();
                                if (gInvActive) {
                                    gAnswer = stripTrailinZeros(float / 4046.86);
                                }
                                else {
                                    gAnswer = stripTrailinZeros(float * 4046.86);
                                }
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
                                gAnswer = stripTrailinZeros(mPresentValue);
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mPresentValue = gAnswer.toFloat();
                            if (mPresentValue == 0.0) {
                                mPresentValue = null;
                            }
                            mOps[mOps_pos] = null;
                            break;


                        case 5: // FV
                            if (mRecall) {
                                gAnswer = stripTrailinZeros(mFutureValue);
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mFutureValue = gAnswer.toFloat();
                            if (mFutureValue == 0.0) {
                                mFutureValue = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 6: // DEP/PMT
                            if (mRecall) {
                                gAnswer = stripTrailinZeros(mPayment);
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mPayment = gAnswer.toFloat();
                            if (mPayment == 0.0) {
                                mPayment = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 7: // YEARS
                            if (mRecall) {
                                gAnswer = stripTrailinZeros(mYears);
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mYears = gAnswer.toFloat();
                            if (mYears == 0.0) {
                                mYears = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 8: // I/Y
                            if (mRecall) {
                                if (mInterestPerYear != null) {
                                    gAnswer = stripTrailinZeros(mInterestPerYear * 100.0);
                                }
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mInterestPerYear = gAnswer.toFloat() / 100.0;
                            if (mInterestPerYear == 0.0) {
                                mInterestPerYear = null;
                            }
                            mOps[mOps_pos] = null;
                            break;

                        case 9: // P/Y
                            if (mRecall) {
                                gAnswer = stripTrailinZeros(mPeriodsPerYear);
                                mRecall = false;
                                break;
                            }
                            if (mCalc) {
                                calcFinancial(gHilight);
                                break;
                            }
                            // If we didn't type a number, use what's on the display for the first number
                            if (mOps_pos == 0 && mOps[mOps_pos] == null) {
                                mOps[mOps_pos] = (gAnswer == null ? "0" : gAnswer);
                            }
                            // We currently have something in the input queue and that something is a 'number' (shown as a string), use that
                            if (mOps[mOps_pos] != null && mOps[mOps_pos] instanceof Lang.String) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos].toFloat());
                            }
                            mPeriodsPerYear = gAnswer.toFloat();
                            if (mPeriodsPerYear == 0.0) {
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
            }
        }
        else {
            if (mOps[mOps_pos] == null) {
                mOps[mOps_pos] = gAnswer;
            }
            if (mOps[mOps_pos] != null) {
                calcPrevious(Oper_Equal);
                gAnswer = stripTrailinZeros(mOps[mOps_pos]);
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

                mOps_pos = 0;
                mOps[mOps_pos] = null;
            }
        }

        WatchUi.requestUpdate();
 
        return true;
    }

    function calcFinancial(which) {
        var float;
        var futureValue;

        mCalc = false;

        switch (gFinancialMode) {
            case FutureValue:
                // F=PV∗(1+Int)^n + PMT∗((1+I)^n-1)/I
                switch (which) {
                    case 4: // PV
                        if (mFutureValue == null || mYears == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "PV=";
                        try {
                            futureValue = mFutureValue;
                            if (mPayment != null) {
                                float = mPayment * (Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0) / (mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1 : (1.0 + mInterestPerYear / mPeriodsPerYear)); // Recurrent deposit
                                futureValue -= float; 

                            }
                            float = futureValue / Math.pow((1.0 + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // From future value
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mPresentValue =  (float == 0.0 ? null : float);
                        }
                        break;

                    case 5: // FV
                        if ((mPayment == null && mPresentValue == null) || mYears == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "FV=";
                        try {
                            float = 0.0;
                            if (mPresentValue != null) {
                                float = mPresentValue * Math.pow((1.0 + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // From present value
                            }
                            if (mPayment != null) {
                                float += mPayment * (Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0) / (mInterestPerYear / mPeriodsPerYear) * (gFinancialBeginEnd == End ? 1 : (1.0 + mInterestPerYear / mPeriodsPerYear)); // Adding it recurrent deposit
                            }
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mFutureValue = float;
                        }
                        break;

                    case 6: // DEP
                        if (mFutureValue == null || mYears == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "DEP=";
                        try {
                            futureValue = mFutureValue;
                            if (mPresentValue != null) {
                                float = mPresentValue * Math.pow((1.0 + mInterestPerYear / mPeriodsPerYear), mYears * mPeriodsPerYear); // Present value
                                futureValue -= float;
                            }
                            float = futureValue / (((Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0) / (mInterestPerYear / mPeriodsPerYear)) * (gFinancialBeginEnd == End ? 1 : (1.0 + mInterestPerYear / mPeriodsPerYear))); // From payment
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mPayment = (float == 0.0 ? null : float);
                        }
                        break;

                    case 7: // YEARS
                        if (mPresentValue == null || mFutureValue == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "YEARS=";
                        try {
                            float = Math.ln(mFutureValue / mPresentValue) / Math.ln(1.0 + mInterestPerYear / mPeriodsPerYear) / mPeriodsPerYear;
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mPeriodsPerYear = float;
                        }
                        break;

                    case 8: // I/Y
                        if (mPresentValue == null || mFutureValue == null || mYears == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "I/Y=";
                        try {
                            float = (Math.pow(mFutureValue / mPresentValue, (1.0 / (mYears * mPeriodsPerYear))) - 1.0) * 100.0 * mPeriodsPerYear;
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }

                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mInterestPerYear = float / 100.0;
                        }
                        break;

                    case 9: // P/Y
                        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        break;
                }
                break;
            case Loan:
                switch (which) {
                    case 4: // L
                        if (mPayment == null || mYears == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "LOAN=";
                        try {
                            float = mPayment / (mInterestPerYear / mPeriodsPerYear * Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear)) * (Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0);
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mPresentValue = (float == 0.0 ? null : float);
                        }
                        break;

                    case 5: // TC
                        if (mPayment == null || mYears == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "TC=";
                        try {
                            float = mPayment * mYears * mPeriodsPerYear;
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mFutureValue = (float == 0.0 ? null : float);
                        }
                        break;

                    case 6: // PMT
                        if (mPresentValue == null || mYears == null || mInterestPerYear == null || mPeriodsPerYear == null || mPeriodsPerYear == 0.0) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        gText = "PMT=";
                        try {
                            float = mPresentValue * (mInterestPerYear / mPeriodsPerYear * Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear)) / (Math.pow(1.0 + mInterestPerYear / mPeriodsPerYear, mYears * mPeriodsPerYear) - 1.0);
                        }
                        catch (e) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                            break;
                        }
                        if (!isFinite(float)) {
                            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
                        }
                        else {
                            gAnswer = stripTrailinZeros(float);
                            mPayment = (float == 0.0 ? null : float);
                        }
                        break;
                }

                break;
        }

    }
    function calcPrevious(oper) {
        if (mOps_pos < 2) {
            return;
        }

        var left = mOps[mOps_pos - 2];
        var right = mOps[mOps_pos];

        // Since try/catch doesn't "catch" null, we need to check for them first.
        if (left == null || right == null) {
            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
            return;
        }

        if (left instanceof Lang.Number && left == 1) {
            // left is an opened parenthesis, skip the calculation until we reach that corresponding close parenthesis
            return;
        }

        try {
            left = left.toFloat();
            right = right.toFloat();
        }
        catch (e) {
            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
            return;
        }

        if (left == null || right == null) {
            gError = WatchUi.loadResource(Rez.Strings.label_invalid);
            return;
        }

        if (oper == Oper_Percent) {
            right = left * right / 100.0;
        }

        switch (mOps[mOps_pos - 1]) {
            case Oper_Add:
                if (oper == Oper_Multiply || oper == Oper_Divide || oper == Oper_Exponent) {
                    return;
                }
                gAnswer = stripTrailinZeros(left + right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Substract:
                if (oper == Oper_Multiply || oper == Oper_Divide || oper == Oper_Exponent) {
                    return;
                }
                gAnswer = stripTrailinZeros(left - right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Multiply:
                gAnswer = stripTrailinZeros(left * right);
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = null;
                mOps_pos--;
                mOps[mOps_pos] = gAnswer;
                calcPrevious(oper);
                break;

            case Oper_Divide:
                if (right != 0.0) {
                    gAnswer = stripTrailinZeros(left / right);
                    mOps[mOps_pos] = null;
                    mOps_pos--;
                    mOps[mOps_pos] = null;
                    mOps_pos--;
                    mOps[mOps_pos] = gAnswer;
                    calcPrevious(oper);
                }
                else {
                    gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                }
                break;

            case Oper_Exponent:
                if (gInvActive) {
                    if (right != 0.0) {
                        gAnswer = stripTrailinZeros(Math.pow(left, 1.0 / right));
                    }
                    else {
                        gError = WatchUi.loadResource(Rez.Strings.label_divide0);
                    }
                }
                else {
                    gAnswer = stripTrailinZeros(Math.pow(left, right));
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
                        gGrid++;
                        if (gGrid > GRID_COUNT) {
                            gGrid = 1;
                        }
                    }
                    else { // Like  WatchUi.SWIPE_RIGHT
                        gInvActive = false;
                        gText = null;
                        gGrid--;
                        if (gGrid < 1) {
                            gGrid = GRID_COUNT;
                        }
                    }
                }
                else { // We 'swiped' up or down predominantly
                    if (mDragStartY > coord[1]) { // Like WatchUi.SWIPE_UP
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
                        }
                        else {
                            gCurrentHistoryIncIndex = null;
                        }
                    }
                    else { // Like WatchUi.SWIPE_UP
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
                        }
                        else {
                            gCurrentHistoryIncIndex = null;
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
        return !x.equals(NaN) && !x.equals(Math.acos(45));
    }
}