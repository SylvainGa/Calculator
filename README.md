# Flashlight companion
Can be used as a standalone flashlight in the Widget/Glance or App wheel or as a companion app for the Crystal-Tesla watch face. The flashlight has three white intensity and two red/green intensity. Fenix 7 Pro watches will use its builtin flashlight LED instead. See the what's new for more details.


**If you enjoy this app, you can support my work with a small donation:**
https://bit.ly/sylvainga

## Installation

Install the widget from the [Connect IQ Store](https://apps.garmin.com/apps/5b90bdbc-d4ea-486a-b18c-8049bb1de857).

## Description

Can be used as a standalone flashlight in the Widget/Glance or App wheel or as a companion app for the Crystal-Tesla watch face. The flashlight has three white intensity and two red/green intensity. Fenix 7 Pro watches will use its builtin flashlight LED instead. See the what's new for more details.

The intensity is selected by pressing anywhere on the screen or through the Select button, the color is selected through the Up button/swipe and Strobe/Normal mode through the Down button/swipe.

NOTE that because of backlit intensity limitation of MIP (Memory In Pixels) devices, the light emitted by these watches might be disappointing to some.

In the Crystal-Tesla watch face for Complication compatible watches, when Complications are enabled, pressing the screen anywhere but on a Complication enabled Field, Indicator or Goal, it will launch this widget.

If you use a different watch face that supports launching custom (CIQ) Complications, the complication long name is Flashlight and the complication type is 0.

WARNING: Keeping the backlight on will drain the battery and according to Garmin, an AMOLED display could get burn in damage if it stays on for too long (https://developer.garmin.com/connect-iq/core-topics/getting-the-users-attention/#Flashlight), so use sporadically and at your own risk.

## Changelog
V1.5.4 Removed devices that do not support the Storage module and shouldn't have been included in the first place. This module was implemented in CIQ 2.4.0, so it's really old watches that are dropped, unfortunately, These are: the first VívoActive, the Forerunner 230/235/630/920XT, the D2 Bravo/Titanium, The Fēnix 3/Fēnix 3 HR/Tactix Bravo/Quatix 3 and the Oregon 7 Series.

V1.5.3 Fixes the backlight staying full bright on exit

V1.5.2 Fixed a crash when using the flashlight on a Fenix 7 Pro/Epix Pro (Gen 2) built-in flashlight

V1.5.1 Added support for the VivoActive5

V1.5.0 Now remembers the previous settings that was used

V1.4.0 Adds a delay of one second when launched (from the scroll wheel) to give time to the user to keep scrolling the widgets in the widget wheel. Can be toggled by pressing the menu key or holding the screen pressed until it vibrates and display the current state of the delay (on or off). Another method (but annoying) to allow scrolling pass the widget in the scroll wheel is to press Back once the flashlight appears. Once at the 'black' screen, the wheel should work again.

V1.3.1 Oops, forgot to re-add the Venu3 and Venu3s to the list of supported watches

V1.3.0 Fixed color switching not working and added Blue and Yellow as available color. Now it cycles through white, red, green, blue and yellow.

V1.2.1 Compiled with SDK 6.3.0 to add support to the Venu3 and Venu3s

V1.2.0 Adds the Red and Green color (two intensities for displays and three for LED) and Strobe mode for LED. Color is selected through the Up button/swipe and Strobe/Normal through the Down button/swipe.

V1.1.1 Fixed an 'unhandled exception' in the new backlight code.

V1.1.0 Added support for the 'backlight' call that allows the backlight to be on for longer than what the configured on time for backlight is set to for MIP watches. For AMOLED watches, it will also stay longer than what the on time is set to.

For Fenix 7 Pro variants, it will try to turn on the builtin flashlight instead of using the display. I do not own that device and the simulator doesn't simulate that feature so I can't confirm if it works or not.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[AGPL-3.0](https://choosealicense.com/licenses/agpl-3.0/)

## Other Licenses
None
