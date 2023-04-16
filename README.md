## screenhook
originally made to make up for features BTT lacks like:
- running applescript when monitor is attached/detached
- running applescript when you click on a corner
- running applescript for any click (without modifiers keys held)

**Note*:* best if used w/ the BetterTouchTool triggers included in "steviaOS"

["steviaOS"](https://github.com/steventheworker/applescripts) exclusive features:
- make sure afterBTTLaunched.applescript (steviaOS script) ran, launch DockAltTab after
- "Spotlight Search.app" will only work with screenhook (dock app to toggle Spotlight / Alfred)
- firefox
    - left-edge of window = sidebar peak
    - top-edge of window = more consistent window dragging (compensate for userChrome.css w/ auto-reveal location bar (prevent drag))
    - cmd+shift+T to reopen tabs AND windows (requires BTT bindings)

planned features:
- awareness of spaces
- applescript definitions - to share space awareness
- change middle mouse button behavior

other:
- sets KeyCastr overlay position to {0, 820} (currently hardcoded for m1 air's dimensions (bottom left))
