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
V1.4.0 Added the following:
- Setting to restore unfinished calculation at next launch. Useful if your watch stops the widget after a certain time. With this option set, you'll be exactly where you left of.
- Workaround for crash when swiping the screen because of an internal Garmin bug. 

V1.3.0 Added the following:
- Calculating number of years for Savings terms now work with Present Value AND/OR Deposit, for both Begin and End.
- MS will be switched to M+ once a number is stored in memory. Storing 0 erases the memory.
- Internal calculations are performed in double precision to increase the accuracy of the result.
- When increasing/decreasing the number of decimals to display, the number of decimals will be shown in the lower right corner of the result area. 
- Unary operators are now being used correctly anywhere in arithmetic calculations, not just as the first value.

V1.2.2 Crash fix in the statistical function when summing number with invalid data in input queue. Reworked the arithmetic code to fix some weird issues.

V1.2.1 Crash fix in the parenthesis arithmetic code plus display how many levels of parenthesis are opened on the screen to help you track your calculations.

V1.2.0 Added the following:
- Added a Statistic panel with the following option. Similar to the Financial panel, I'm not a statistician. I got the formula from the web. I do not guaranty the result are accurate, although my tests yielded the right result. Use at your own risk.
  After said, that, here how it works. You input a number and press Add. If you want to remove a number instead, you press Del. The number has to be present to be removed. To clear the whole group of number, press Reset then Del to confirm. Numbers entered are get in non volatile memory and are reloaded once the app is started again. Once all the numbers are entered, you can use the statistical buttons, which are:
  MEAN: The mean of the number set
  SSDEV: Sample Standard Deviation
  PSDEV: Population Standard Deviation
  MEDIAN: The median of the number set
  VARIAN: The variance of the number set
  MODE: The mode of the number set
  RANGE: The range of the number set
You can view what was entered by pressing View. You scroll through the list like you do for the history by swiping up and down.

- Fixed another crash while stripping trailing zeros from the answer

V1.1.0 Added the following: 

- Added a financial panel. USE AT YOUR OWN RISK. I make no guaranty about the quality of the responses, although my tests yielded the right result. I got the formulas from the web. I'm not a financial specialist.
  After that said, here how it works. Both Saving and Loan works similarly. The fields are:
  Saving: 
    - Begin/End: For recurrent deposit, specify if the deposit happens at the start or the end of the period
    - PV: Present Value
    - FV: Future Value
    - DEP: Deposit
    - YEARS: The term of the saving in years
    - I/Y: The YEARLY interest rate (enter 10 for 10%)
    - P/Y: Period per year. If monthly, enter 12. For yearly, enter 1.
    - Recall: Press this followed by one of the buttons above to retrieve the current saved or calculated value.
    - Calc: Calculate the corresponding field. Currently, the following work: PV, FV, DEP, YEARS and I/Y. For PV, FV, and DEP, you can enter PV or DEP or BOTH.
  Loan:
    - L: Loan
    - TC: Total Cost
    - PMT: Payment
    - YEARS: The term of the saving in years
    - I/Y: The YEARLY interest rate (enter 10 for 10%)
    - P/Y: Period per year. If monthly, enter 12. For yearly, enter 1.
    - Recall: Press this followed by one of the buttons above to retrieve the current saved or calculated value.
    - Calc: Calculate the corresponding field. Currently, the following work: L, TC, PMT.

  A field with data in it will show a '*' beside it. Entering 0 in a field clears the value. A field with a '?' beside it means that this data is missing for the calculation you tried to do.

  For example, to calculate the future value of $1,000 after 5 years at 6%, you would enter:
      1000 PV
      5 YEARS
      6 I/Y
      1 P/Y
      Calc FV

   If you have the missing formulas, get in contact with me (github or email) and I'll see what I can do.
   
- The memory value is saved and restored when the app is relaunched. Storing 0 deletes it.
- Swiping the result window left or right changes the number of digits after the decimal points. Works when a value is displayed, not when entering a number. The number of digits is saved and restored on the next launch.
- When an arithmetic operation is selected, it will show up on the right edge of the result windows.

V1.0.2 Fixed a crash while calculating

V1.0.1 Fixed a crash while stripping trailing zeros from the answer

V1.0.0 Initial release

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[AGPL-3.0](https://choosealicense.com/licenses/agpl-3.0/)

## Other Licenses
None
