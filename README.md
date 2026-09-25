# App Exposé Restore

App Exposé Restore brings minimized windows back into **App Exposé** on macOS 27. Open App Exposé with your existing Control–Down Arrow shortcut or trackpad gesture, then click a card to restore a minimized window. Cards can show a still preview of the window's contents. Finder windows are supported.

This is an independent workaround for the missing minimized-window row in macOS 27. It does not modify macOS or replace your App Exposé shortcut. Detection relies on undocumented Dock and WindowManager window layers, so a macOS update may require an app update.

## Build it yourself

Requires macOS 27 and a full installation of Xcode 27 or later. There are no external packages, services, or build accounts.

```sh
git clone https://github.com/moritzlg/AppExposeRestore.git
cd AppExposeRestore
./test.sh
./build.sh
```

`build.sh` creates `../AppExposeRestore.zip`, outside the repository. Open the ZIP, move `AppExposeRestore.app` to your Applications folder, and launch it. On first use, grant the macOS permissions described below. To update the app, quit it and replace the old app bundle with the newly built one.

The default build uses **ad hoc code signing**. You do not need an Apple Developer account or a certificate to build from source on your own Mac. If you build frequently, you can optionally use your own local code-signing identity so macOS is less likely to ask for permissions again after each build:

```sh
APP_EXPOSE_SIGNING_IDENTITY="Your local code-signing identity" ./build.sh
```

Keep its private key in your own Keychain; never commit or share it. This repository distributes **source code only**. Downloadable binaries would need a separate [Developer ID signing and notarization](https://developer.apple.com/developer-id/) process for normal Gatekeeper handling.

## Permissions

| Permission | Why it is needed |
| --- | --- |
| Accessibility | Find minimized windows and restore the selected window. |
| Screen Recording | Show a still image of a minimized window in its card. This is optional; cards show the app icon when permission or an unambiguous image is unavailable. |

The app links to the relevant macOS settings. It processes window titles and preview images in memory. It does not save or transmit them, has no analytics, and makes no network requests. Local diagnostic logs contain timing phases, counts, and error codes, without titles or images.

## Controls and languages

The menu and Settings window let you turn automatic display, the menu bar icon, and content previews on or off. With the menu bar icon hidden, the app stays accessible from the Dock. The cards use a fixed Clear Liquid Glass appearance; these settings do not change their glass style.

English and German are included. macOS chooses the language from your preferred app languages.

## Limitations and testing

- The app has been tested on macOS 27. Other versions may expose windows differently.
- Previews are still images, not live streams. If a preview cannot be matched safely to its window, the card keeps the app icon.
- Some apps expose minimized windows through Accessibility children instead of their ordinary window list. Both are checked, but a window hidden from both cannot be shown.
- Changing a local app signature can make macOS ask for Accessibility or Screen Recording permission again.

`./test.sh` checks Exposé detection, window enumeration and preview matching, preferences, rendering, and localization. For a manual check, open two windows in one app, minimize one, open App Exposé, and click the added card. Mission Control should not show the added row.

## License

MIT — see [LICENSE](LICENSE). App Exposé Restore is not affiliated with Apple.
