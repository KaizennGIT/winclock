# winclock

A Windows 11-style clock for the KDE Plasma 6 panel. Click it to open a flyout
with your notifications and a calendar.

Built and tested on Fedora 44, KDE Plasma 6.8.2, Wayland. It is inspired by the
Windows 11 flyout and is not affiliated with Microsoft.

## Features

- Panel clock with a time and date you can format any way you like
- Floating flyout with no frame: notifications on top, calendar below
- Three themes, picked in settings: Windows 11, Modern Plasma (compact), and
  Classic Plasma (same size as KDE's own calendar popup, docked to the panel)
- An arrow next to the clock folds the calendar away so the notifications get
  the room
- Notifications grouped by app, clear-all button, Do Not Disturb bell
- Calendar with a big clock header, month arrows, and a collapse button
- If the floating flyout ever fails, it falls back to Plasma's normal popup, so
  the clock never disappears

## Install

    git clone https://github.com/KaizennGIT/winclock.git
    cd winclock
    ./install.sh --restart

Then right-click the panel, choose "Add or Manage Widgets", and search for
the widget. Remove your old clock if you want to replace it.

## Settings

Right-click the clock and choose "Configure". You can pick a time and date
preset or type your own format. In the format box, h or hh is the hour (12-hour),
H or HH is the hour (24-hour), m is minutes, s is seconds, AP is AM/PM, d is the
day, M is the month, and yyyy is the year. The settings page lists the rest.

## Update

Open the settings, scroll to "Updates", press "Check for updates", then
"Install update" and "Restart panel now". It only talks to GitHub when you
press the button. This needs `git` installed.

Or by hand:

    git pull
    ./install.sh --restart

The first time, install with `./install.sh` (this version or newer) so the
widget knows which version it is. Until then the updater says it can't tell.

## Uninstall

    ./install.sh --uninstall

## Limits

- The flyout is flat: no blur behind it.
- There is no Focus timer.
- Notifications use KDE's notification API, which could change in a future
  Plasma release.

## License

MIT. See the LICENSE file.
