package dev.markturnip.streamplayer

data class Progress(val elapsed : Double, val duration : Double)

/**
 * Live in-stream metadata (HLS ID3 `TIT2` title / `TPE1` artist). Both fields null means
 * metadata was cleared because a new item started or playback stopped.
 */
data class StreamMetadata(val title: String?, val artist: String?)

enum class PlaybackState {
    PLAYING, PAUSED, STOPPED, BUFFERING, ERROR
}

interface MediaPlayerItem {
    val id: String
    val title: String
    val artist: String?
    val url: String // Use String to be platform-agnostic
    val isLive: Boolean
    val artworkUrl: String?
}

interface PlatformMediaPlayerInterface {
    fun play()
}

expect final class PlatformMediaPlayer constructor() {
    fun playItem(mediaPlayerItem: MediaPlayerItem)
    fun play()
    fun pause()
    fun stop()

    fun skip(delta: Double) // skip
    fun seekWithPosition(position: Double)

    fun subscribeState(callback: (PlaybackState) -> Unit)
    fun subscribeProgress(callback: (Progress) -> Unit)
    fun subscribeMetadata(callback: (StreamMetadata) -> Unit)
}
