import Foundation
import AVFoundation
import Combine

class CustomAVPlayerItem: AVPlayerItem, AVPlayerItemMetadataOutputPushDelegate {
    let info: NowPlayingInfo?

    /// Timed metadata (e.g. HLS ID3) pushed by `AVPlayerItemMetadataOutput`, which replaces the
    /// `AVPlayerItem.timedMetadata` property deprecated in iOS 13.
    let pushedMetadata = PassthroughSubject<TimedMetadata, Never>()

    init(url: URL, info: NowPlayingInfo?) {
        self.info = info
        super.init(asset: .init(url: url), automaticallyLoadedAssetKeys: nil)
        self.canUseNetworkResourcesForLiveStreamingWhilePaused = false

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
