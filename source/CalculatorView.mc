import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
using Toybox.Application.Storage;
using Toybox.Application.Properties;

const GRID_COUNT = 4;

enum { Degree, Radian }
enum { Imperial, USA }

var gAnswer = null;
var gGrid = 1;
var gHilight = 0;
var gMemory = null;
var gError = null;
var gDegRad = Degree;
var gConvUnit = USA;
var gInvActive = false;
var gCurrentHistoryIndex = null;
var gCurrentHistoryIncIndex = null;
var gPanelOrder = [1, 2, 3, 4];

class CalculatorView extends WatchUi.View {
    function initialize() {
        View.initialize();

        var panelOrderStr;
        try {
            panelOrderStr = Properties.getValue("panelOrder");
        }
        catch (e) {
            Properties.setValue("panelOrder", "1,2,3,4");
        }

        if (panelOrderStr != null) {
            var array = to_array(panelOrderStr, ",");
            if (array.size() == 4) {
                for (var i = 0; i < 4; i++) {
                    var val;
                    try {
                        val = array[i].toNumber();
                    }
                    catch (e) {
                        gPanelOrder = [1, 2, 3, 4];
                        break;
                    }

                    if (val > 0 && val < 5) {
                        gPanelOrder[i] = val;
                    }
                    else {
                        gPanelOrder = [1, 2, 3, 4];
                        break;
                    }
                }
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
                font = Graphics.FONT_SMALL;
                
                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, " 0 ", false, Graphics.FONT_SMALL);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, " . ", false, Graphics.FONT_SMALL);
                break;

            case 2:
                array1 = [" ( ", " ) ", "CA"];
                array2 = [" + ", " - ", "DD"];
                array3 = [" * ", " ÷ ", " % "];
                array = [array1, array2, array3];
                font = Graphics.FONT_SMALL;

                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, "MS", false, Graphics.FONT_SMALL);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "MR", false, Graphics.FONT_SMALL);
                break;

            case 3:
                array1 = ["INV", (gDegRad == Degree ? "DEG" : "RAD"), "Pi"];
                array2 = ["SIN", "COS", "TAN"];
                array3 = ["Log", "Ln", "1/x"];
                array = [array1, array2, array3];
                font = Graphics.FONT_SMALL;

                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 10, "x^2", false, Graphics.FONT_SMALL);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 8), height - height / 10, 11, "x^y", false, Graphics.FONT_SMALL);
                break;

            case 4:
                array1 = ["INV", (gConvUnit == Imperial ? "IMP" : "US"), (gInvActive ? "°F<-°C" : "°F->°C")];
                array2 = (gInvActive ? ["GAL<-LITRE", "OZ<-ML", "CUP<-ML"] : ["GAL->LITRE", "OZ->ML", "CUP->ML"]);
                array3 = (gInvActive ? ["MILE<-KM", "FT<-CM", "LB<-KG"] : ["MILE->KM", "FT->CM", "LB->KG"]);
                array = [array1, array2, array3];
                font = Graphics.FONT_XTINY;

                drawInside(dc, width / 4 + (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 10 : 8), 10, (gInvActive ? "MPH<-KMH" : "MPH->KMH"), false, Graphics.FONT_XTINY);
                drawInside(dc, width - width / 4 - (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 12), height - height / (screenShape == System.SCREEN_SHAPE_RECTANGLE ? 10 : 8), 11, (gInvActive ? "ACRE<-M2" : "ACRE->M2"), false, Graphics.FONT_XTINY);
                break;
        }

        for (var row = 0; row < 3; row++) {
            for (var col = 0; col < 3; col++) {
                if ((gPanelOrder[gGrid - 1] == 3 || gPanelOrder[gGrid - 1] == 4) && row == 0 && col == 0) {
                    drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], gInvActive, font);
                }
                else {
                    drawInside(dc, width / 3 * col + width / 6, height / 5 * (row + 1) + height / 10, row * 3 + col + 1, array[row][col], false, font);
                }
            }
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(0, 0, width, h_separation - 2);

        if (gError != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, screenShape == System.SCREEN_SHAPE_RECTANGLE ? height / 16 : height / 11, Graphics.FONT_SMALL, gError, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        }
        else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, screenShape == System.SCREEN_SHAPE_RECTANGLE ? height / 16 : height / 11, Graphics.FONT_SMALL, (gAnswer != null ? gAnswer : "0"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            if (gAnswer != null) {
                 Storage.setValue("answer", gAnswer);
            }
        }

        if (gMemory != null || gCurrentHistoryIncIndex != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (gCurrentHistoryIncIndex == null) {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2 + height / 70 - 2, Graphics.FONT_XTINY, "M=" + stripTrailinZeros(gMemory), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            else {
                dc.drawText((screenShape == System.SCREEN_SHAPE_RECTANGLE ? 0 : width / 3 - width / 6), height / 5 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2 + height / 70 - 2, Graphics.FONT_XTINY, "H=" + gCurrentHistoryIncIndex, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
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
