# Calculator Widget

Calculator Widget is a Garmin ConnectIQ widget to perform standard, scientific and unit conversion calculations on a touch-enabled watch. Round and rectangular/square watches are supported

**If you enjoy this app, you can support my work with a small donation:**
https://bit.ly/sylvainga

## Installation

Install the widget from the [Connect IQ Store](https://apps.garmin.com/en-US/apps/5270a7c6-33c9-4114-8cc6-e513f6866440).

## Description

Calculator allows to perform simple, scientific and unit conversion calculations from your touch-enabled watches.

Features include:

- Four panels - Numbers, arithmetic, scientific and unit conversion;
- The panel order is configurable through the app Settings;
- Uses order of precedence for the arithmetic, plus parenthesis. There is enough place for over 50 pending operations in its buffer;
- Includes a Memory function to store something for use later;
- History of the last x result. You can choose to save from 0 to 50 results in the history buffer (defaults to 10). Settable in the app Settings;
- Simple gesture to switch panels and view history;
- Support Glance mode where it displays the last result;
- Support Complication so it can be launched directly from a watch face. Simply use 0 for Type and Calculator for the Long Name;
- Available in both French and English;

Please raise an issue if anything doesn't work correctly, or if you use an unsupported Garmin device, via the [Github issues page](https://github.com/SylvainGa/Calculator/issues).

## Usage

To use, launch it, preferably from a Glance. Reason is when launched from a Glance, gestures are available right away, instead of having to spawn a subview. If not launched from a Glance, you'll be asked to press the screen so the subview can be launched and activate the gestures.

Press any of the corresponding 'buttons' to activate it. The top of the screen has the result. Touch it to simulate an '=' and terminate the equation. The answer will then be stored in its history buffer.

To delete the last digit, use Delete Digit (DD). To clear the line, use Clear All (CA). To enter a negative number, before its first digit, enter a '-'.

You scroll through the history by a swipe down/up gesture. A swipe down moves forward in the history while an up gesture moves backward. The latest result is in Position 0 (H=0) as well as viewable from the Glance view.

You change panel by left and right swipes. Right swipes move forward in the panel order while left swipes move backward.

The calculator follows order of operations, so multiplications, divisions and "x power of y" are performed before additions and subtractions. These can be overridden by usage of parenthesis. You can nest parenthesis to perform complex operations.

Unary operations are perform before any arithmetic operations are performed. 

In the Scientific panel, INV can be used to toggle between sin, cos, tan, x^2 and asin, acos, atan, squareroot respectively. Trigonometric operations can be performed in degrees or radians by choosing the corresponding mode.

In the Unit conversion panel, you can change the order of operation through the INV button. The IMP/USA button applies to Gallons and Cups.

If you like the widget, please consider [leaving a positive review](https://apps.garmin.com/en-US/apps/5270a7c6-33c9-4114-8cc6-e513f6866440).

If you want to have the widget translated to your language, contact me through email or github.

## Changelog

V1.1.0 Added the following: 

- Started the financial panel. USE AT YOUR OWN RISK. I make no garanty about the quality of the responses. I got the formulas from the web. I'm not a financial specialist.
  After said, that, here how it works. Both Saving and Loan works similarely. The fields are:
  Saving: 
    - Begin/End: For recurent deposit, specify if the deposit happens at the start or the end of the period
    - PV: Present Value
    - FV: Future Value
    - DEP: Deposit
    - YEARS: The term of the saving in years
    - I/Y: The YEARLY interest rate (enter 10 for 10%)
    - P/Y: Period per year. If monthly, enter 12. For yearly, enter 1.
    - Recall: Press this followed by one of the buttons above to retreive the current saved or4 calculated value.
    - Calc: Calculate the corresponding field. Currently, the following work: PV, FV, DEP, YEARS and I/Y. For PV, FV, and DEP, you can enter PV or DEP or BOTH.
  Loan:
    - L: Loan
    - TC: Total Cost
    - PMT: Payment
    - YEARS: The term of the saving in years
    - I/Y: The YEARLY interest rate (enter 10 for 10%)
    - P/Y: Period per year. If monthly, enter 12. For yearly, enter 1.
    - Recall: Press this followed by one of the buttons above to retreive the current saved or4 calculated value.
    - Calc: Calculate the corresponding field. Currently, the following work: L, TC, PMT.

  A field with data in it will show a '*' beside it. Entering 0 in a field clears the value.

  For example, to calculate the future value of $1,000 after 5 years at 6%, you would enter:
      1000 PV
      5 YEARS
      6 I/Y
      1 P/Y
      Calc FV

- The memory value is saved and restored when the app is relaunched. Storing 0 deletes it.
- Swiping the result window left and right changes the number of digits after the decimal points. Works when a value is displayed, not when entering a number
- When a arithmetic operation is selected, it will show up on the right edge of the result windows.

V1.0.2 Fixed a crash while calculating

V1.0.1 Fixed a crash while stripping trailing zeros from the answer

V1.0.0 Initial release

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[AGPL-3.0](https://choosealicense.com/licenses/agpl-3.0/)

## Other Licenses
None
