import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Math;
using Toybox.Application.Storage;

const GRID_COUNT = 2;

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

    function initialize() {
        BehaviorDelegate.initialize();

        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
    
        mOps_pos = 0;
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
            switch (gGrid) {
                case 0:
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

                case 1:
                    switch (gHilight) {
                        case 1: // ParenOpen
                            // We just tag its place in the queue so ParenClose can do its thing
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
                                calcPrevious(Oper_Equal);
                            }
                            mOps[mOps_pos + 1] = null;
                            break;

                        case 3: // CA
                            mOps_pos = 0;
                            mOps[mOps_pos] = null;
                            gAnswer = null;
                            gError = null;
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

                case 2:
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
                                            gError = "Invalid";
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
                                            gError = "Invalid";
                                        }
                                        else {
                                            gAnswer = stripTrailinZeros(float);
                                        }

                                        mOps[mOps_pos] = null;
                                    }
                                }
                                catch (e) {
                                    gError = "Invalid";
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
                                        gError = "Invalid";
                                    }
                                    else {
                                        gAnswer = stripTrailinZeros(float);
                                    }

                                    mOps[mOps_pos] = null;
                               }
                                catch (e) {
                                    gError = "Invalid";
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
                                    gError = "Divide by zero";
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
                                        gError = "Invalid";
                                    }
                                    else {
                                        gAnswer = stripTrailinZeros(float);
                                    }

                                    mOps[mOps_pos] = null;
                                }
                                catch (e) {
                                    gError = "Invalid";
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
            }
        }
        else {
            if (mOps[mOps_pos] != null) {
                calcPrevious(Oper_Equal);
                gAnswer = stripTrailinZeros(mOps[mOps_pos]);
                var index = Storage.getValue("HistoryIndex");
                if (index == null) {
                    index = 0;
                }
                Storage.setValue("history_" + index, gAnswer);
                index++;
                if (index >= 10) {
                    index = 0;
                }
                Storage.setValue("HistoryIndex", index);
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

        var left = mOps[mOps_pos - 2].toFloat();
        var right = mOps[mOps_pos].toFloat();

        if (oper == Oper_Percent) {
            right = left * right / 100.0;
        }

        switch (mOps[mOps_pos - 1]) {
            case Oper_Add:
                gAnswer = stripTrailinZeros(left + right);
                mOps_pos -= 2;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Substract:
                gAnswer = stripTrailinZeros(left - right);
                mOps_pos -= 2;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Multiply:
                gAnswer = stripTrailinZeros(left * right);
                mOps_pos -= 2;
                mOps[mOps_pos] = gAnswer;
                break;

            case Oper_Divide:
                if (right != 0.0) {
                    gAnswer = stripTrailinZeros(left / right);
                    mOps_pos -= 2;
                    mOps[mOps_pos] = gAnswer;
                }
                else {
                    gError = "Divide by zero";
                }
                break;

            case Oper_Exponent:
                if (gInvActive) {
                    if (right != 0.0) {
                        gAnswer = stripTrailinZeros(Math.pow(left, 1.0 / right));
                    }
                    else {
                        gError = "Divide by zero";
                    }
                }
                else {
                    gAnswer = stripTrailinZeros(Math.pow(left, right));
                }

                mOps_pos -= 2;
                mOps[mOps_pos] = gAnswer;
                break;
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
                gGrid = 0;
            }
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
            gGrid--;
            if (gGrid < 0) {
                gGrid = GRID_COUNT;
            }
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_UP) {
            var index;
            if (gCurrentHistoryIndex != null) {
                index = gCurrentHistoryIndex;
            }
            else {
                gCurrentHistoryIncIndex = 0;
                index = Storage.getValue("HistoryIndex");
            }
            if (index == null) {
                index = 0;
            }

            var start = index;
            var answer;
            do {
                index--;
                if (index < 0) {
                    index = 9;
                }
                answer = Storage.getValue("history_" + index);
            } while (answer == null && index != start);

            gCurrentHistoryIndex = index;
            if (answer != null) {
                gCurrentHistoryIncIndex--;
                if (gCurrentHistoryIncIndex < 1) {
                    gCurrentHistoryIncIndex = 10;
                }
            }
            gAnswer = answer;
        }
        else if (swipeEvent.getDirection() == WatchUi.SWIPE_DOWN) {
            var index;
            if (gCurrentHistoryIndex != null) {
                index = gCurrentHistoryIndex;
            }
            else {
                gCurrentHistoryIncIndex = 0;
                index = Storage.getValue("HistoryIndex");
            }
            if (index == null) {
                index = 0;
            }

            var start = index;
            var answer;
            do {
                answer = Storage.getValue("history_" + index);
                index++;
                if (index >= 10) {
                    index = 0;
                }
            } while (answer == null && index != start);

            gCurrentHistoryIndex = index;
            if (answer != null) {
                gCurrentHistoryIncIndex++;
                if (gCurrentHistoryIncIndex > 10) {
                    gCurrentHistoryIncIndex = 1;
                }
            }
            gAnswer = answer;
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

    function isFinite(x) {
        return !x.equals(NaN) && !x.equals(Math.acos(45));
    }
}