import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
using Toybox.Application.Storage;
using Toybox.Application.Properties;

const GRID_COUNT = 6;

enum { Degree, Radian }
enum { Imperial, USA }
enum { FutureValue = 0, Loan }
enum { Begin, End }

var gAnswer = null;
var gDigits = 2;
var gDigitsChanged = false;
var gDataEntry = false; // When true, we are actively inputing digits
var gGrid = 1;
var gHilight = 0;
var gMemory = null;
var gError = null;
var gText = null;
var gOpText = null;
var gInvActive = false;
var gCurrentHistoryIndex = null;
var gCurrentHistoryIncIndex = null;
var gStackHistory = null;
var gPanelOrder = [1, 2, 3, 4, 5, 6];
var gPanelSize = 6;

var gDegRad = Degree;

var gConvUnit = USA;

var gFinancialMode = FutureValue;
var gFinancialBeginEnd = Begin;

var gDataCount = 0;
var gDataSum = 0;
var gDataMean = 0;
var gDataPoints = null;
var gDataReset = false;
var gDataView = false;
var gDataViewPos = 0;

class CalculatorView extends WatchUi.View {
    var mDelegate;
    var mUsingFont = new [7];
    var mUsingFontLine2;
    var mThousandsSep;
    var mDecimalSep;

    function initialize(delegate) {
        View.initialize();
        mDelegate = delegate;

        onSettingsChanged();
        
        gDigits = Storage.getValue("digits");
        if (gDigits == null || gDigits < 0 || gDigits > 10) {
            gDigits = 6;
            Storage.setValue("digits", gDigits);
        }

        gMemory = Storage.getValue("Memory");

    }

    function onSettingsChanged() {
        var panelOrderStr;
        try {
            panelOrderStr = Properties.getValue("panelOrder");
        }
        catch (e) {
            Properties.setValue("panelOrder", "1,2,3,4,5,6");
        }

        mThousandsSep = 0;
        try {
            mThousandsSep = Properties.getValue("thousandsSep");
        }
        catch (e) {
            Properties.setValue("thousandsSep", 0);
        }

        mDecimalSep = 0;
        try {
            mDecimalSep = Properties.getValue("decimalSep");
        }
        catch (e) {
            Properties.setValue("mDecimalSep", 0);
        }

        if (panelOrderStr != null) {
            var array = to_array(panelOrderStr, ",");
            if (array.size() > 1 && array.size() <= GRID_COUNT) {
                var i;
                for (i = 0; i < array.size(); i++) {
                    var val;
                    try {
                        val = array[i].toNumber();
                    }
                    catch (e) {
                        gPanelOrder = [1, 2, 3, 4, 5, 6];
                        i = 6;
                        break;
                    }

                    if (val != null && val > 0 && val <= GRID_COUNT) {
                        gPanelOrder[i] = val;
                    }
                    else {
                        gPanelOrder = [1, 2, 3, 4, 5, 6];
                        i = 6;
                        break;
                    }
                }

                gPanelSize = i;

                while (i < GRID_COUNT) {
                    gPanelOrder[i] = null;
                    i++;
                }
            }
        }

        WatchUi.requestUpdate();
    }

    function onLayout(dc) {
        var fonts = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_MEDIUM, Graphics.FONT_LARGE];
        var dcHeight = dc.getHeight();
        var dcWidth = dc.getWidth();
        mDelegate.mHeight = dcHeight;
        mDelegate.mWidth = dcWidth;

        for (var i = fonts.size() - 1; i >= 0 ; i--) {
            var fontHeight = Graphics.getFontHeight(fonts[i]); // Font for the result area (two lines in this area so half of a fifth of the screen)
            if (mUsingFont[0] == null && fontHeight < dcHeight * 3 / 20) {
                mUsingFont[0] = fonts[i];

                for (var j = i; j >= 0; j--) {
                    var fontHeightLine2 = Graphics.getFontHeight(fonts[j]);
                    if (fontHeightLine2 < dcHeight * 2 / 30) {
                        mUsingFontLine2 = fonts[j];
                        break;
                    }
                }
                if (mUsingFontLine2 == null) {
                    mUsingFontLine2 = Graphics.FONT_XTINY;
                }
            }
            else if (i == 0 && mUsingFont[0] == null) {
                mUsingFont[0] = Graphics.FONT_XTINY;
                mUsingFontLine2 = Graphics.FONT_XTINY;
            }

            var fontSize = dc.getTextDimensions(" 0 ", fonts[i]); // Font for the numeric page
            if (mUsingFont[1] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[1] = fonts[i];
            }
            else if (i == 0 && mUsingFont[1] == null) {
                mUsingFont[1] = Graphics.FONT_XTINY;
            }

            fontSize = dc.getTextDimensions(" SWAP ", fonts[i]); // Font for the arithmetic page
            if (mUsingFont[2] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[2] = fonts[i];
            }
            else if (i == 0 && mUsingFont[2] == null) { // Default if we can't find one
                mUsingFont[2] = Graphics.FONT_XTINY;
            }

            fontSize = dc.getTextDimensions(" DEG ", fonts[i]); // Font for the scientific page
            if (mUsingFont[3] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[3] = fonts[i];
            }
            else if (i == 0 && mUsingFont[3] == null) {
                mUsingFont[3] = Graphics.FONT_SMALL;
            }

            fontSize = dc.getTextDimensions(" GAL<-LITRE ", fonts[i]); // Font for the conversion
            if (mUsingFont[4] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[4] = fonts[i];
            }
            else if (i == 0 && mUsingFont[4] == null) {
                mUsingFont[4] = Graphics.FONT_XTINY;
            }

            fontSize = dc.getTextDimensions(" Saving ", fonts[i]); // Font for the saving page
            if (mUsingFont[5] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[5] = fonts[i];
            }
            else if (i == 0 && mUsingFont[5] == null) {
                mUsingFont[5] = Graphics.FONT_XTINY;
            }

            fontSize = dc.getTextDimensions(" MEDIAN ", fonts[i]); // Font for the statistical page
            if (mUsingFont[6] == null && fontSize[0] <= dcWidth / 3) {
                mUsingFont[6] = fonts[i];
            }
            else if (i == 0 && mUsingFont[6] == null) {
                mUsingFont[6] = Graphics.FONT_XTINY;
            }
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

		var width = dc.getWidth();
		var height = dc.getHeight();
        var w_separation = width / 3;
        var h_separation = height / 5;
        var screenShape = System.getDeviceSettings().screenShape;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw Vertical separations
        for (var i = 1; i < 3; i++) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.fillRectangle(w_separation * i - 3, h_separation, 6, 3 * h_separation);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillRectangle(w_separation * i - 1, h_separation, 2, 3 * h_separation);
        }

        // Draw Horizontal separations
        for (var i = 1; i < 5; i++) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.fillRectangle(0, h_separation * i - 3, width, 6);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillRectangle(0, h_separation * i - 1, width, 2);
        }

        // Draw bottom Vertical separation
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(width / 2 - 3, height - h_separation + 2, 6, h_separation);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillRectangle(width / 2 - 1, height - h_separation + 2, 2, h_separation);

        var array1;
        var array2;
        var array3;
        var array;
        var font;

        switch (gPanelOrder[gGrid - 1]) {
            case 1:
                array1 = [" 7 ", " 8 ", " 9 "];
                array2 = [" 4 ", " 5 ", " 6 "];
                array3 = [" 1 ", " 2 ", " 3 "];
                array = [array1, array2, array3];
                font = mUsingFont[1];
                
                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                    }
                }

                var dotOrE = mDecimalSep == 0 ? " . " : " , ";
                if (gDataEntry && gAnswer != null && gAnswer.toString().find(".") != null) {
                    dotOrE = " E ";
                }

                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, " 0 ", false, mUsingFont[1]);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, dotOrE, false, mUsingFont[1]);
                break;

            case 2:
                if (mDelegate.mCalcMode == 0) {
                    array1 = [" ( ", " ) ", "CA"];
                }
                else {
                    array1 = ["POP", "+/-", "CA"];
                }
                if (gDataEntry || mDelegate.mCalcMode == 0) {
                    array2 = [" + ", " - ", "DD"];
                }
                else {
                    array2 = [" + ", " - ", "SWAP"];
                }
                array3 = [" × ", " ÷ ", " % "];
                array = [array1, array2, array3];
                font = mUsingFont[2];

                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                    }
                }
                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, (gMemory == null ? "MS" : "M+"), false, mUsingFont[2]);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "MR", false, mUsingFont[2]);
                break;

            case 3:
                array1 = ["INV", (gDegRad == Degree ? "DEG" : "RAD"), "Pi"];
                array2 = ["SIN", "COS", "TAN"];
                array3 = ["Log", "Ln", "1/x"];
                array = [array1, array2, array3];
                font = mUsingFont[3];

                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        if (row == 0 && col == 0) {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], gInvActive, font);
                        }
                        else {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                        }
                    }
                }
                if (gInvActive) {
                    drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, "√x", false, mUsingFont[3]);
                    drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "y√x", false, mUsingFont[3]);
                } else {
                    drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, "x^2", false, mUsingFont[3]);
                    drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "x^y", false, mUsingFont[3]);
                }
                break;

            case 4:
                array1 = ["INV", (gConvUnit == Imperial ? "IMP" : "US"), (gInvActive ? "°F<-°C" : "°F->°C")];
                array2 = (gInvActive ? ["GAL<-LITRE", "OZ<-ML", "CUP<-ML"] : ["GAL->LITRE", "OZ->ML", "CUP->ML"]);
                array3 = (gInvActive ? ["MILE<-KM", "FT<-CM", "LB<-KG"] : ["MILE->KM", "FT->CM", "LB->KG"]);
                array = [array1, array2, array3];
                font = mUsingFont[4];

                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        dc.setClip(col * w_separation + (col == 0 ? 0 : 2), (row + 1) * h_separation + 1, w_separation - (col == 0 ? 3 : 6), h_separation - (col == 0 ? 3 : 6));
                        if (row == 0 && col == 0) {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], gInvActive, font);
                        }
                        else {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                        }
                        dc.clearClip();
                    }
                }
                dc.setClip(0, (height * 4) / 5 + 2, width / 2 - 4, height / 5 - 4);
                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 10 : 8), 10, (gInvActive ? "MPH<-KMH" : "MPH->KMH"), false, mUsingFont[4]);
                dc.setClip(width / 2 + 2, (height * 4) / 5 + 2, width / 2 - 4, height / 5 - 4);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 10 : 8), 11, (gInvActive ? "ACRE<-M2" : "ACRE->M2"), false, mUsingFont[4]);
                dc.clearClip();
                break;

            case 5:
                if (gFinancialMode == FutureValue) {
                    array1 = ["Saving", (gFinancialBeginEnd == Begin ? "Begin" : "End"), ""];
                    array2 = ["PV" + (mDelegate.mPresentValue != null ? "*" : (mDelegate.mFinancialMissingPV ? "?" : "")), "FV" + (mDelegate.mFutureValue != null ? "*" : (mDelegate.mFinancialMissingFV ? "?" : "")), "DEP" + (mDelegate.mPayment != null ? "*" : (mDelegate.mFinancialMissingDEP ? "?" : ""))];
                }
                else {
                    array1 = ["Loan", "", ""];
                    array2 = ["L" + (mDelegate.mPresentValue != null ? "*" : (mDelegate.mFinancialMissingPV ? "?" : "")), "TC" + (mDelegate.mFutureValue != null ? "*" : (mDelegate.mFinancialMissingFV ? "?" : "")), "PMT" + (mDelegate.mPayment != null ? "*" : (mDelegate.mFinancialMissingDEP ? "?" : ""))];
                }
                array3 = ["YEARS" + (mDelegate.mYears != null ? "*" : (mDelegate.mFinancialMissingYears ? "?" : "")), "I/Y" + (mDelegate.mInterestPerYear != null ? "*" : (mDelegate.mFinancialMissingIY ? "?" : "")), "P/Y" + (mDelegate.mPeriodsPerYear != null ? "*" : (mDelegate.mFinancialMissingPY ? "?" : ""))];
                array = [array1, array2, array3];
                font = mUsingFont[5];

                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        dc.setClip(col * w_separation + 2, (row + 1) * h_separation + 2, w_separation - 2, h_separation - 2);
                        drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                        dc.clearClip();
                    }
                }
                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / 9, 10, "Recall", (mDelegate.mRecall ? true : false), mUsingFont[5]);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / 9, 11, "Calc", (mDelegate.mCalc ? true : false), mUsingFont[5]);
                break;

            case 6:
                array1 = ["MEAN", "SSDEV", "PSDEV"];
                array2 = ["MEDIAN", "VARIAN", "MODE"];
                array3 = ["RANGE", "View", "Reset"];
                array = [array1, array2, array3];
                font = mUsingFont[6];

                for (var row = 0; row < 3; row++) {
                    for (var col = 0; col < 3; col++) {
                        dc.setClip(col * w_separation + 2, (row + 1) * h_separation + 2, w_separation - 2, h_separation - 2);
                        if (row == 2 && col == 2) {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], gDataReset, font);
                        }
                        else if (row == 2 && col == 1) {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], gDataView, font);
                        }
                        else {
                            drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                        }
                        dc.clearClip();
                    }

                }
                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, "Add", false, mUsingFont[6]);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "Del" + (gDataReset ? "?" : ""), false, mUsingFont[6]);
                break;
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(0, 0, width, h_separation - 2);

        if (gError != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, screenShape == System.SCREEN_SHAPE_RECTANGLE ? height / 16 : height / 11, mUsingFont[0], gError, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        }
        else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, screenShape == System.SCREEN_SHAPE_RECTANGLE ? height / 16 : height / 11, mUsingFont[0], (gDataEntry ? (gAnswer != null ? display(gAnswer) : "0") : display(limitDigits(gAnswer != null ? gAnswer : "0"))), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            if (gAnswer != null) {
                 Storage.setValue("answer", gAnswer);
            }
            if (gOpText != null && gText == null) {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? width - 1 : width - (width / 3 - width / 6)), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, gOpText, Graphics.TEXT_JUSTIFY_RIGHT);
            }
        }

        if (gText != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? width - 1 : width - (width / 3 - width / 6)), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, gText, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        else if (mDelegate.mCalcMode == 1) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? width - 1 : width - (width / 3 - width / 6)), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, "S=" + mDelegate.mOps_pos, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        if (gMemory != null || gCurrentHistoryIncIndex != null || gStackHistory != null || gDataView) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (gDataView) {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, "D=" + (gDataViewPos + 1), Graphics.TEXT_JUSTIFY_LEFT);
            }
            else if (gCurrentHistoryIncIndex != null) {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, "H=" + gCurrentHistoryIncIndex, Graphics.TEXT_JUSTIFY_LEFT);
            }
            else if (gStackHistory != null) {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, "S=" + gStackHistory, Graphics.TEXT_JUSTIFY_LEFT);
            }
            else {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(mUsingFontLine2) + 1, mUsingFontLine2, "M=" + display(stripTrailingZeros(gMemory)), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }
    }

    function display(value) {
        if (mThousandsSep == 0 && mDecimalSep == 0) { // If we keep the default, no point in trying to trandfor, return what we passed
            return value;
        }

        var char = value.toCharArray();
        var strlength = value.length();
        var length = strlength;
        var decimalPos = value.find(".");
        var output = "";
        var i = 0;
        var first = true;

        if (decimalPos != null) { // We have a decimal, what's before that decimal is what matters for the thousands separator
            length = decimalPos;
        }

        if (char[0] == '-') { // If we have a preceeding minus symbol, push it to our output string and skip processing it
            output = "-";
            i = 1;
            length--;
        }

        for (var j = length; j > 0 && i < strlength; j--, i++) { // Go through the input string (before the '.')
            if (j % 3 == 0 && !first) {
                // If we have a multitude of 3, add our separator
                switch (mThousandsSep) {
                    case 0:
                        break;
                    case 1:
                        output += " ";
                        break;
                    case 2:
                        output += ",";
                        break;
                }
            }
            output += char[i].toString();
            first = false;
        }

        // If we had a decimal point, that's where we're at now, process it
        if (decimalPos != null) {
            switch (mDecimalSep) {
                case 0:
                    output += ".";
                    break;
                case 1:
                    output += ",";
                    break;
            }

            // Now add what's after the decimal point (if there is anything)
            output += value.substring(decimalPos + 1, value.length());
        }

        return output;
    }

    function drawInside(dc, x, y, pos, text, perm_hilight, font) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        if (gHilight == pos || perm_hilight == true) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        }
        else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
