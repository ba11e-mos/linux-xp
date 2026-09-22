// ---- Windows XP / IE6 skin for Firefox ----------------------------
// Let userChrome.css load at all
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Hand the title bar back to the window manager -> Luna blue bar, red X
user_pref("browser.tabs.inTitlebar", 0);
// Compact rows, like XP's 21px toolbars
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
// Never let a dark theme through
user_pref("browser.theme.toolbar-theme", 1);
user_pref("browser.theme.content-theme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 1);
// IE's Links bar is always out
user_pref("browser.toolbars.bookmarks.visibility", "always");
