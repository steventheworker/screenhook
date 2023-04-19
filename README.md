## screenhook

originally made to make up for features BTT lacks like:

-   running applescript when monitor is attached/detached
-   running applescript when you click on a corner
-   running applescript for any click (without modifiers keys held)

-   **Firefox (_new_ &nbsp;--vertical tabs support)** [(my config)](https://github.com/steventheworker/ff-chrome-folder)
    -   cmd+shift+T to reopen tabs AND windows (requires BTT bindings)
    -   _left-edge of window = sidebar peak_
    -   _top-edge of window = more consistent window dragging (compensate for userChrome.css w/ auto-reveal location bar (prevent drag))_

\*_Note_:\* best if used w/ the BetterTouchTool triggers included in "steviaOS" (but not required for all features)

["steviaOS"](https://github.com/steventheworker/applescripts) exclusive features:

-   make sure afterBTTLaunched.applescript (steviaOS script) ran, launch DockAltTab after
-   "Spotlight Search.app" will only work with screenhook (dock app to toggle Spotlight / Alfred)

planned features:

-   awareness of spaces
-   applescript definitions - to share space awareness
-   change middle mouse button behavior

startup:

-   waits to run some startup apps (7-14 seconds) that depend on programs that take a bit startup (eg: BetterTouchTool, AltTab & DockAltTab (opens on startup))
-   KeyCastr - set overlay position to {0, 820} (currently hardcoded for m1 air's dimensions (bottom left))
-   QuickShade - uncheck "Enable Shade"

&nbsp;

using screenhook (for **<u>Firefox</u> vertical tabs**) without BTT:

<details>
<summary>put in (~/.config/karabiner/assets/complex_modifications) </summary>

&nbsp;

<details>
<summary>as toggle-firefox-sidebar.json</summary>

```
{
	"title": "Rules for Karabiner-Elements | Tested Version: 11.6.0",
	"rules": [
		{
			"description": "Firefox cmd+s => (applescript) toggle the sidebar and tell screenhook it's visiblity",
			"manipulators": [
				{
					"conditions": [
						{
							"bundle_identifiers": ["^org\\.mozilla\\.firefox$"],
							"type": "frontmost_application_if"
						}
					],
					"from": {
						"key_code": "s",
						"modifiers": {
							"mandatory": ["command"]
						}
					},
					"to": [
						{
							"shell_command":
                            "osascript -e 'run script \"'/Users/YOUR_USER_NAME/Desktop/firefox-sidebar-toggle.scpt'\"'"
						}
					],
					"type": "basic"
				}
			]
		}
	]
}
```

</details>
<details>
<summary>as toggle-firefox-dev-sidebar.json</summary>

```
{
	"title": "Rules for Karabiner-Elements | Tested Version: 11.6.0",
	"rules": [
		{
			"description": "Firefox (dev) cmd+s => (applescript) toggle the sidebar and tell screenhook it's visiblity",
			"manipulators": [
				{
					"conditions": [
						{
							"bundle_identifiers": ["^org\\.mozilla\\.firefoxdeveloperedition$"],
							"type": "frontmost_application_if"
						}
					],
					"from": {
						"key_code": "s",
						"modifiers": {
							"mandatory": ["command"]
						}
					},
					"to": [
						{
							"shell_command":
                            "osascript -e 'run script \"'/Users/YOUR_USER_NAME/Desktop/firefox-dev-sidebar-toggle.scpt'\"'"
						}
					],
					"type": "basic"
				}
			]
		}
	]
}
```

</details>

&nbsp;

Change the "shell_path" to the path (of the .scpt),

or, if you replace "YOUR_USERNAME" in the example string, it will look on the Desktop

&nbsp;

</details>

... then enable in [Karabiner-Elements](https://karabiner-elements.pqrs.org/) in order to bind Command+S to [firefox-sidebar-toggle.scpt / firefox-dev-sidebar-toggle.scpt](https://github.com/steventheworker/applescripts/blob/main/firefox-dev-sidebar-toggle.applescript)
