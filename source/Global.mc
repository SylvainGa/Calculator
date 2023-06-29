import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
using Toybox.Application.Storage;

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

function stripTrailinZeros(number) {
    var dotPos;
    var numberStr = number.toDouble().toString();

    dotPos = numberStr.find(".");
    if (dotPos == null) {
        numberStr = number.toNumber();
    }
    else {
        var numberArray = numberStr.toCharArray(); 
        var i;
        for (i = numberStr.length() - 1; i > dotPos; i--) {
            if (numberArray[i] != '0') {
                break;
            }
        }
        if (numberArray[i] == '.') {
            i--;
        }

        numberStr = numberStr.substring(0, i + 1);
    }

    if (numberStr instanceof Lang.String && numberStr.equals("-0")) {
        numberStr = "0";
    }
    return numberStr.toString();
}
