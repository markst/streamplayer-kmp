import Combine
import Foundation
import AVFoundation

public protocol StreamPlayerType {
    var state: AnyPublisher<StreamPlayerState, Never> { get }
    var playbackState: AnyPublisher<StreamPlayerPlaybackState, Never> { get }
    var playProgress: AnyPublisher<Progress, Never> { get }
    var isPlaying: AnyPublisher<Bool, Never> { get }
    var didPlayToEndTime: AnyPublisher<NowPlayingInfo?, Never> { get }
    var timedMetadata: AnyPublisher<TimedMetadata, Never> { get }

    // Rename load media?
    func play(url: URL)
    func play(url: URL, at position: NSNumber?)
    func play(url: URL, at position: NSNumber?, info: NowPlayingInfo?)

    func play()
    func pause()
    func stop()
    func togglePlaying()

    func skip(_ delta: Double)
    func seek(position: TimeInterval)
}

public struct Progress {
    public let id: Int
    // TODO: Rename elapsed time to indicate it's the time in seconds rather than floating point
    public let progress: TimeInterval
    public let duration: TimeInterval
}

/// Live in-stream metadata (HLS ID3 `TIT2` title / `TPE1` artist).
/// Both fields nil means metadata was cleared (new item or stopped).
public struct TimedMetadata: Equatable {
    public let title: String?
    public let artist: String?

    static let empty = TimedMetadata(title: nil, artist: nil)

    init(title: String?, artist: String?) {
        self.title = title
        self.artist = artist
    }

    /// Returns nil when the payload carries neither a title nor an artist.
    init?(items: [AVMetadataItem]) {
        let title = items.first {
            $0.commonKey == .commonKeyTitle || $0.identifier == .id3MetadataTitleDescription
        }?.stringValue
        let artist = items.first {
            $0.commonKey == .commonKeyArtist || $0.identifier == .id3MetadataLeadPerformer
        }?.stringValue
        guard title != nil || artist != nil else { return nil }
        self.init(title: title, artist: artist)
    }
}
