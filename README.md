# Podium

A click-wheel music player for iPhone that controls the Spotify app, written in SwiftUI.

## Features

- Full-screen dark UI that fits on one screen
- Carousel of Spotify's recommended content with artwork and a now-playing indicator
- Circular wheel: rotate to browse, press to play, with haptic feedback
- Play/pause, previous/next and seeking with live playback progress
- Spotify App Remote connection: authorization, player state and controls
- Mock remote that simulates playback, so the UI runs in the Simulator without Spotify

## Requirements

- Xcode 26 (tested with 26.6)
- iOS 17+
- To connect to Spotify: an iPhone with the Spotify app and a Spotify Premium account (Spotify requires Premium for apps in Development Mode)

## Getting started

Open `Podium.xcodeproj`, pick an iPhone simulator and Run (⌘R). The Simulator uses the mock remote, so no setup is needed.

From the command line:

```bash
xcodebuild -project Podium.xcodeproj -scheme Podium -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

The Spotify iOS SDK (`SpotifyiOS`) is added through Swift Package Manager and resolved on the first build.

## Connecting to Spotify

1. Create an app at https://developer.spotify.com/dashboard and select **iOS** under APIs/SDKs.
2. Add the Redirect URI `podium-player://spotify-login-callback`, and your bundle ID under **iOS app bundles**.
3. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and fill in `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM` and `SPOTIFY_CLIENT_ID`. Git ignores this file.
4. Connect your iPhone, turn on Developer Mode, and Run from Xcode.
5. Start playing something in Spotify, open Podium and tap **Connect**. Spotify opens to authorize and switches back.

Notes:

- Development Mode apps work for their owner plus up to 5 users added under User Management in the dashboard.
- With a free Apple developer account, apps installed on a device expire after 7 days; Run from Xcode again to reinstall.
- The access token is kept in memory only. After Podium is relaunched, tapping Connect authorizes again, which briefly opens Spotify and resumes playback.
- The Simulator always uses `MockSpotifyRemote`. Launch arguments `-PodiumRemote spotify` / `-PodiumRemote mock` override the choice.

## Controls

- Connect / center button while disconnected: connect to Spotify
- Rotate the wheel: browse the carousel
- Center button: play the browsed item (or play/pause if it is the one playing)
- MENU: jump back to what is playing
- Previous / next: change track (previous restarts the current track after 3 seconds)
- Bottom button: play / pause
- Drag the progress bar: seek

## Architecture

- `PlayerViewModel`: UI/player state; extrapolates playback progress between remote updates
- `SpotifyRemoteControlling`: transport abstraction (commands, connection state, `onStateChange` / `onLibraryChange`)
- `SpotifyRemoteManager`: App Remote implementation (authorization, player state, recommended content, artwork)
- `SpotifyConfiguration`: Client ID (from `Config/Secrets.xcconfig`) and redirect URL
- `PlayerState`: remote player snapshot (track, paused, position, context)
- `MockSpotifyRemote`: development implementation simulating a queue, playback and auto-advance
- `MockLibrary`: demo albums and tracks
- `ClickWheelView`: angular finger tracking + haptics
- `CoverFlowView`: carousel
- `ProgressViewBar`: scrubbing
- `PodiumPlayerView`: main composition

## Disclaimer

Podium is an independent project and is not affiliated with, endorsed or sponsored by Spotify or Apple. Spotify is a trademark of Spotify AB; iPhone is a trademark of Apple Inc.

The Spotify Developer Terms allow apps like this for personal, non-commercial use. Don't publish builds of Podium to the App Store or monetize them.

## License

MIT — see [LICENSE](LICENSE).
