import Foundation
import AVFoundation
import Combine

class CustomAVPlayerItem: AVPlayerItem, AVPlayerItemMetadataOutputPushDelegate {
    let info: NowPlayingInfo?

    /// Timed metadata (e.g. HLS ID3) pushed by `AVPlayerItemMetadataOutput`, which replaces the
    /// `AVPlayerItem.timedMetadata` property deprecated in iOS 13.
    let pushedMetadata = PassthroughSubject<TimedMetadata, Never>()

    init(url: URL, info: NowPlayingInfo?, userAgent: String? = nil, preferredForwardBufferDuration: TimeInterval = 0) {
        self.info = info
        // "AVURLAssetHTTPHeaderFieldsKey" is the long-standing (if undocumented) way to set request
        // headers such as User-Agent; some radio servers reject requests without one.
        let options: [String: Any]? = userAgent.flatMap { $0.isEmpty ? nil : ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": $0]] }
        super.init(asset: AVURLAsset(url: url, options: options), automaticallyLoadedAssetKeys: nil)
        self.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        if preferredForwardBufferDuration > 0 {
            self.preferredForwardBufferDuration = preferredForwardBufferDuration
        }

        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        output.setDelegate(self, queue: .main)
        add(output)
    }

    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        if let metadata = TimedMetadata(items: groups.flatMap { $0.items }) {
            pushedMetadata.send(metadata)
        }
    }
}
