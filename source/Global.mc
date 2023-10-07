import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
using Toybox.Application.Storage;

(:glance)
function to_array(string, splitter) {
	var array = new [30]; //Use maximum expected length
	var index = 0;
	var location;

	do {
		location = string.find(splitter);
		if (location != null) {
			array[index] = string.substring(0, location);
			string = string.substring(location + 1, string.length());
			index++;
		}
	} while (location != null);

	array[index] = string;

	var result = new [index + 1];
	for (var i = 0; i <= index; i++) {
		result[i] = array[i];
	}
	return result;
}

(:glance)
function stripTrailingZeros(number) {
    if (number == null) {
        number = "0";
    }

    if (number instanceof Lang.String) {
        if (number.equals("-0")) {
        return("0");
        }
        if (number.equals("-")) {
        return("-");
        }
    }

    var numberStr = number.toDouble().toString();
    var dotPos = numberStr.find(".");
    if (dotPos == null) {
        numberStr = number.toNumber();
    }
    else {
        var numberArray = numberStr.toCharArray(); 
        var index;

        for  (index = numberStr.length() - 1; index > dotPos; index--) {
            if (numberArray[index] != '0') {
                break;
            }
        }

        numberStr = numberStr.substring(0, index + 1); // Keep only what's necessary
    }

    if (numberStr == null || (numberStr instanceof Lang.String && numberStr.equals("-0"))) {
        numberStr = "0";
    }

    return numberStr.toString();
}

// Limit the number of digits
(:glance)
function limitDigits(answer) {
    if (answer == null) {
        answer = "0";
    }

//    var answerStr = answer.toString();

    // Convert to exponential format if too big or too small
    var exp = 0;
    var expStr = "";

    // We shouldn't get a lone "-" here, flag it as invalid
    if (answer instanceof Lang.String && answer.equals("-")) {
        gError = WatchUi.loadResource(Rez.Strings.label_invalid);
        return("");
    }

    var answerDbl = answer.toDouble();
    var answerStr = answerDbl.toString();

    // Because of precision error, it could try to display "-0", don't
    if (answerStr.equals("-0")) {
        answerStr = "0";
    }

    // Split exponent and mantissa if any
/*    var expPos = answerStr.find("E");
    if (expPos != null) {
        expStr = answerStr.substring(expPos, expPos + 4);
        answerStr = answerStr.substring(0, expPos - 1);
    }
*/
    if (answerDbl != 0) {
        exp = Math.log(answerDbl.abs(), 10);
        exp = (exp  + 0.000000005).toNumber(); // Stupid precision error of Monkey C
        if (exp > 7 || exp < -7) {
            answerStr = (answerDbl / Math.pow(10, exp)).toString();
            expStr = "E" + exp;
        }
    }

    // Because of precision error, it could try to display "-0", don't
    if (answerStr.equals("-0")) {
        answerStr = "0";
    }

    var dotPos = answerStr.find(".");
    if (dotPos != null) {
        if (dotPos + gDigits + 1 < answerStr.length()) { // (+ 1 because dotPos is zero based)
            answerStr = answerStr.toDouble().format("%0." + gDigits + "f");
        }
    }

    if (gDigitsChanged) {
        return answerStr.toString() + expStr;
    }
    else {
        return stripTrailingZeros(answerStr.toString()) + expStr;
    }
}
