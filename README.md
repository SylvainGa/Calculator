# The Swiss army knife of calculators Widget

The Swiss army knife of calculators Widget is a Garmin ConnectIQ widget to perform standard, scientific, unit conversion, loans/savings and statistical calculations on a touch-enabled watch using either BEDMAS or RPN calculation methods. Round and rectangular/square watches are supported

**If you enjoy this app, you can support my work with a small donation:**
https://bit.ly/sylvainga

## Installation

Install the widget from the [Connect IQ Store](https://apps.garmin.com/en-US/apps/5270a7c6-33c9-4114-8cc6-e513f6866440).

## Description

The Swiss army knife of calculators allows to perform simple, scientific, unit conversion, loans/savings and statistical calculations from your touch-enabled watches using either BEDMAS or RPN calculation methods.

Features include:

- Six panels - Numbers, arithmetic, scientific, unit conversion, loans/savings and statistical;
- The panel order is configurable through the app Settings;
- Can be used for BEDMAS (order of operations are Brackets, Exponent, Multiplication, Division, Addition and Substraction) or RPN (Reverse Polish Notation). There is enough place for over 50 pending operations in its buffer;
- Includes a Memory function to store something for use later;
- History of the last x result. You can choose to save from 0 to 50 results in the history buffer (defaults to 10). Settable in the app Settings;
- Simple gesture to switch panels, adjust rounding precisions and view history/RPN stack;
- Support Glance mode where it displays the last result;
- Support Complication so it can be launched directly from a watch face. Simply use 0 for Type and Calculator for the Long Name;
- Available in both French and English. If you want to help translating in another language, get in contact with me.

Please raise an issue if anything doesn't work correctly, or if you use an unsupported Garmin device, via the [Github issues page](https://github.com/SylvainGa/Calculator/issues).

## Usage

To use, simply launch it, preferably from a Glance. Reason is when launched from a Glance, gestures are available right away, instead of having to spawn a subview. If not launched from a Glance, you'll be asked to press the screen so the subview can be launched and activate the gestures. Sorry, that's a Garmin limitation.

Press any of the corresponding 'buttons' to activate it. There is no EQUAL (or Enter for RPN) button because THE TOP OF THE SCREEN acts as an EQUAL sign (in BEDMAS) or Enter (in RPN). TOUCH IT TO SIMULATE AN '=' (EQUAL) AND TERMINATE THE EQUATION in BEDMAS or to push the current data into the stack. In RPN, when the stack is empty, pressing '-' after a number, push the number into the stack and also changes it sign. Pressing '+' on an empty stack pushes the current value into the stack.

To enter an exponent, first press the '.' button if you haven't already entered a decimal point and the button will change to an 'E'. Press it followed by the corresponding exponent number.

You scroll through the history/RPN stack by a swipe down/up gesture. A swipe down moves forward in the history while an up gesture moves backward. The latest result is in Position 0 (H=0) as well as viewable from the Glance view. In RPN, you'll scroll through the stack BEFORE showing the history (S=). Th stack or history value displayed can be used as part of the current equation.

You change panel by left and right swipes. Right swipes move forward in the panel order while left swipes move backward. The operators +, -, x, ÷ and CA will autoreturn to the number panel. In the settings, you can adjust the order of the panels.

In BEDMAS, the calculator follows order of operations, unary operators are performed first (like x^2), followed by multiplications, divisions and "x power of y". Additions and subtractions are performed last (so 2+3*4 equals 14, not 20). These can be overridden by usage of parenthesis ( (2+3)*4 is equal to 20). You can nest parenthesis to perform complex operations.

In RPN, you push numbers into the stack in the order you want the opertion to be performed then you use the operands. For example, to do 2+3*4, you can type either 2 Enter, 3 Enter, 4 * + or 3 Enter, 5 * 2 +.

In the Scientific panel, INV can be used to toggle between sin, cos, tan, x^2 and asin, acos, atan, squareroot respectively. Trigonometric operations can be performed in degrees or radians by choosing the corresponding mode.

In the Unit conversion panel, you can change the order of operation through the INV button. The IMP/USA button applies to Gallons and Cups.

In the Loan/Savings panel, you fill the value you know (a * will appear beside a field that has a value) and then pressed Calc followed by the field you want to be calculated. Although only one of Present Value (PV) and DEP (Deposit) could be entered, the other fields must all be entered except for the field to find its value. For example, to find the Future Value (FV) of a Present Value (PV) of $1000, with a compound interest of 10% yearly (I/Y) after 5 Years (YEARS) with I Payment per year (P/Y), you fill these field and then press Calc FV.

In the Statistical panel, you enter the data one by one by pressing 'Add' once the data is on screen. If you want to delete an entry, type its value and press Del. The operations that can be performed are Mean, Sum of Square Deviation (SSDEV), Population Standard Deviation (PSDEV), Median, Variance (VARIAN), Mode and Range. Data entered survive an application close so if the app terminates before you have time to enter all the data, just continue where you left off. You need to press Reset then Del to erase the data. Pressin View acts just like the history buffer, allowing you to cycle between all the data you entered.

If you like the widget, please consider [leaving a positive review](https://apps.garmin.com/en-US/apps/5270a7c6-33c9-4114-8cc6-e513f6866440).

If you want to have the widget translated to your language, contact me through email or github.

## Changelog
V1.7.0 Added the following
  Inv transforms x^2 and x^y into √x and y√x, thank you jwessel for your contribution
  Allow the use of RPN (Reverse Polish Notation) to do calculations. Settable in the App Settings.
  Crash fix in the statistical calculation when continuing from saved data

V1.6.0 Added the following
  Large and small numbers are now displayed/entered using exponents. The '.' button becomes a 'E' button once a decimal is entered so you can enter an exponent.
  As soon as an operation is entered (+, -, x, ÷ and CA), the screen autoreturns to the number panel so you cam right away start entering number without having to swipe.

V1.5.2 Added support for the VivoActive5

V1.5.1 Fixes the order of precedence for the exponent (x^y) code so it's performed before any other operation (so 50 x 1.03^5 yields 57.9637 now and not 362273148.21875)

V1.5.0 Allow the removal of some panels

V1.4.2 Added Venu3 and Venu3S as supported devices

V1.4.1 Some watches, like the VivoActive 4S behaves differently in the simulator than on the real device. On those devices, don't swipe too fast or it won't record the swipe. You'll also have to press the Back button TWICE to leave the app.

Fixed a crash when just a '-' was in memory and a M+ was performed to it.

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
