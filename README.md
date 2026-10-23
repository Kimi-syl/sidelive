# SideLive

SideStore and LiveContainer in **one app**, with an instant in-app switch between the two UIs.

Upstream already ships a combined `LiveContainer+SideStore` build, but SideStore there is a
separate guest app: opening it takes over the process, and getting back to LiveContainer means
relaunching. SideLive embeds the built-in SideStore scene in a tab instead, so both UIs stay
alive and you can flip between them without a relaunch.

> **Status:** experimental. CI builds and packages the IPA; the tab integration has not been
> verified on a physical device yet. Expect rough edges.

## How it works

- LiveContainer is the host app (bundle id `com.kdt.livecontainer`).
- The built-in SideStore (`Frameworks/SideStoreApp.framework`, dylibified) runs inside
  LiveContainer's `LiveProcess` extension, exactly like LiveContainer's multitasking guest apps.
- `LiveProcess`'s scene is hosted with `AppSceneViewController` (`_UISceneHostingController`
  on iOS 18+) inside a SwiftUI tab.
- A segmented control at the top switches between `LiveContainer` and `SideStore`; both stay
  mounted, so switching is immediate.
- Small patches make the embedded SideStore path work outside the "refresh intent" flow:
  - pass the `Documents/SideStore` home bookmark to `LiveProcess`
  - make the XPC refresh endpoint optional when SideStore is started as UI

## Build

GitHub Actions (`.github/workflows/build.yml`) does everything on a `macos-26` runner with
Xcode 26.2:

1. fetch pinned LiveContainer + SideStore (LiveContainer fork) revisions from `pins.env`
2. apply `patches/*.patch`
3. build SideStore unsigned (`make build`, `make fakesign`, `make ipa`)
4. archive LiveContainer unsigned
5. dylibify SideStore, merge it into the LiveContainer bundle, repackage the widget
6. upload `SideLive.ipa`

The result is unsigned. Install it with SideStore/AltStore (keep app extensions), or sign it
with your own certificate. Because SideStore itself runs inside the app, the host bundle needs
the `group.com.SideStore.SideStore` app group and the `sidestore://` URL scheme, which the
packaging step injects.

## Pins

See `pins.env`. Bumping a pin may require refreshing the patches.

- LiveContainer `main` @ `9108ae6`
- SideStore `LiveContainerSupport` @ `ee3cc16`

## Licensing

Both upstream projects are AGPL-3.0. This repository is a derivative work and is licensed under
AGPL-3.0 as well; see `LICENSE`. Upstream credits: SideStore (AltStore fork) and LiveContainer.
