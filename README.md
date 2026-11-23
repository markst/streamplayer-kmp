# StreamPlayer

Demonstrating a multipurpose Kotlin Multiplatform and Swift Package media player.

**StreamPlayer** combines shared Kotlin logic with native implementations using [ExoPlayer](https://developer.android.com/media/media3/exoplayer) for Android and [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer/) in Swift for iOS, showcasing the future potential of Kotlin Multiplatform packages.

This repository demonstrates how a package can be structured to share implementation between:
- Kotlin Android Package
- Kotlin Android Multiplatform Package
- Kotlin iOS Multiplatform Package
- Swift Package

By leveraging the native Kotlin [SwiftPM import](https://kotlinlang.org/docs/multiplatform/multiplatform-spm-import.html) feature for importing Swift code into the Kotlin Multiplatform shared module, the iOS StreamPlayer implementation is native Swift code rather than using interpolation. This means we can serve the Swift code as its own independent `Package.swift`.

### Multi-Purpose

This means one repository can serve as both a Kotlin Multiplatform Package and a Native Swift Package, rather than using interpolation and writing native iOS sourceset in Kotlin.

<p align="center">
  <img src="docs/media/diagram.png" alt="StreamPlayer Diagram" width="512">
</p>

## iOS Package

By leveraging the native Kotlin SwiftPM import for importing Swift code into the Kotlin Multiplatform shared module, StreamPlayer is implemented as a native Swift package.

The iOS component can be developed and maintained independently using the Swift Package Manager, making it easier to manage native iOS code.

It can serve as a native iOS component:

![Swift Package](docs/media/swift-package.png)

## Android Package

On Android, it utilizes ExoPlayer, a powerful and flexible media player.

![Android Package](docs/media/android-package.png)

## Integration

### Android

Initialize the player in your `Application.onCreate()`:

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        PlatformMediaPlayer.initialize(this)
    }
}
```

Then create and retain a reference — call `stop()` when no longer needed:

```kotlin
val player = PlatformMediaPlayer()
player.playItem(myMediaItem)

// When finished:
player.stop()
```

### iOS

Add the KMP framework to your Xcode project, then use `PlatformMediaPlayer` directly — no additional setup required:

```swift
let player = PlatformMediaPlayer()
player.playItem(mediaPlayerItem: myItem)
```

### Stream metadata

Subscribe to live now-playing metadata (HLS timed ID3 `TIT2` title / `TPE1` artist):

```kotlin
player.subscribeMetadata { meta ->
    // meta.title, meta.artist
}
```

`StreamMetadata(title = null, artist = null)` is emitted when a new item starts or playback stops, so stale text from the previous stream can be cleared. Repeated identical tags are not re-emitted.

On iOS, in-stream metadata comes from an `AVPlayerItemMetadataOutput`, so it only appears when AVFoundation surfaces the ID3 tags. For packed-audio (`.aac`) HLS, that means a separate ID3 tag after the segment's leading `transportStreamTimestamp` tag (e.g. iHeart streams). Streams that put `TIT2`/`TPE1` inside the leading timestamp tag (e.g. StreamTheWorld) don't report in-stream metadata on iOS.

### Now Playing artwork

Pass an `artworkURL` and the player fetches the image asynchronously, publishing the text to Now Playing immediately and the artwork once it arrives:

```swift
player.play(url: stream, at: nil, info: NowPlayingInfo(title: "Show", artist: "Station", artworkURL: logoURL))
```

Fetching goes through an `ArtworkResolving`. The default, `URLSessionArtworkResolver`, uses `URLSession.shared` and its HTTP cache. Inject your own with `MediaPlayController(artworkResolver:)`. The `artwork:` image parameter still works and skips the resolver.
