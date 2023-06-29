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

    function initialize() {
        BehaviorDelegate.initialize();

        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
    
        mOps_pos = 0;
        mCountHistory = true;

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

        mTimer.start(method(:doUpdate), 100, false);

        gHilight = findTapPos(x, y);
        if (gHilight > 0) {
            switch (gPanelOrder[gGrid - 1]) {
                case 1:
                    array = ["N/A", "7", "8", "9", "4", "5", "6", "1", "2", "3", "0", Oper_DOT ];
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
                            mOps[mOps_pos] += ".";
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
                            break;

                        case 3: // CA
                            for (var i = 0; i < mOps.size(); i++) {
                                mOps[i] = null;
                            }
                            mOps_pos = 0;
                            gAnswer = null;
                            gError = null;
                            gInvActive = false;
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
                            break;

                        case 10: // MS
                            if (mOps[mOps_pos] != null) {
                                gAnswer = stripTrailinZeros(mOps[mOps_pos]);
                                gMemory = gAnswer;
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

    function calcPrevious(oper) {
        if (mOps_pos < 2) {
            return;
        }

        var left;
        var right;

        try {
            left = mOps[mOps_pos - 2].toFloat();
            right = mOps[mOps_pos].toFloat();
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

    function onSwipe(swipeEvent) {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
            gGrid++;
            if (gGrid > GRID_COUNT) {
                gGrid = 1;
            }
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
            gGrid--;
            if (gGrid < 1) {
                gGrid = GRID_COUNT;
            }
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_UP) {
            if (mHistorySize == 0) {
                return false;
            }

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
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_DOWN) {
            if (mHistorySize == 0) {
                return false;
            }

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
        WatchUi.requestUpdate();

        return true;
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