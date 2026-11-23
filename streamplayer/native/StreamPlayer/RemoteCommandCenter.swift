import Foundation
#if os(iOS)
import UIKit
#endif
import Combine
import MediaPlayer

class RemoteCommandCenter {
    
    private var streamPlayer: StreamPlayerType

    /// Called for the lock-screen / headphone next- and previous-track buttons.
    var onNextTrack: (() -> Void)? {
        didSet { MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = onNextTrack != nil }
    }
    var onPreviousTrack: (() -> Void)? {
        didSet { MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = onPreviousTrack != nil }
    }
    @Published
    private var state: StreamPlayerState = .stopped
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Init
    
    init(streamPlayer: StreamPlayerType, nowPlayingInfo: AnyPublisher<NowPlayingInfo?, Never>) {
        self.streamPlayer = streamPlayer
        self.streamPlayer.state.assign(to: &$state)

        // Skip and seek only make sense for items with a duration that are not live streams.
        // Servers that answer range requests (most Icecast) make AVPlayer report a large finite
        // duration for a live stream, so `NowPlayingInfo.isLive` takes precedence over it.
        Publishers.CombineLatest(
            streamPlayer.playProgress.map { $0.duration > 0 },
            nowPlayingInfo.map { $0?.isLive ?? false }
        )
        .map { hasDuration, isLive in hasDuration && !isLive }
        .removeDuplicates()
        .sink { [weak self] seekable in self?.setSeekingEnabled(seekable) }
        .store(in: &cancellables)

        setupRemoteCommandCenter()
    }
    
    deinit {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
        remoteCommandCenter.nextTrackCommand.removeTarget(self)
        remoteCommandCenter.previousTrackCommand.removeTarget(self)
        remoteCommandCenter.playCommand.removeTarget(self)
        remoteCommandCenter.pauseCommand.removeTarget(self)
        remoteCommandCenter.stopCommand.removeTarget(self)
        remoteCommandCenter.skipForwardCommand.removeTarget(self)
        remoteCommandCenter.skipBackwardCommand.removeTarget(self)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self)
        
#if os(iOS)
        UIApplication.shared.endReceivingRemoteControlEvents()
#endif
    }
    
    func setupRemoteCommandCenter() {
#if os(iOS)
        UIApplication.shared.beginReceivingRemoteControlEvents() /// Required for `MPNowPlayingInfoCenter`
#endif

        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [streamPlayer] _ -> MPRemoteCommandHandlerStatus in
            streamPlayer.togglePlaying()
            return .success
        }
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.playCommand.addTarget { [streamPlayer] event -> MPRemoteCommandHandlerStatus in
            if self.state != .playing {
                streamPlayer.play()
                return .success
            } else {
                return .noActionableNowPlayingItem
            }
        }
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.addTarget { [streamPlayer] event -> MPRemoteCommandHandlerStatus in
            if self.state == .playing {
                streamPlayer.pause()
                return .success
            } else {
                return .noActionableNowPlayingItem
            }
        }
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            guard let handler = self?.onNextTrack else { return .noActionableNowPlayingItem }
            handler()
            return .success
        }
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            guard let handler = self?.onPreviousTrack else { return .noActionableNowPlayingItem }
            handler()
            return .success
        }
        remoteCommandCenter.stopCommand.isEnabled = true
        remoteCommandCenter.stopCommand.addTarget { [streamPlayer] _ -> MPRemoteCommandHandlerStatus in
            streamPlayer.stop()
            return .success
        }
        
        remoteCommandCenter.skipForwardCommand.isEnabled = true
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [30]
        remoteCommandCenter.skipForwardCommand.addTarget { [streamPlayer] (event) -> MPRemoteCommandHandlerStatus in
            if let interval = (event as? MPSkipIntervalCommandEvent)?.interval {
                streamPlayer.skip(interval)
                return .success
            }
            return .commandFailed
        }
        
        remoteCommandCenter.skipBackwardCommand.isEnabled = true
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [30]
        remoteCommandCenter.skipBackwardCommand.addTarget { [streamPlayer] (event) -> MPRemoteCommandHandlerStatus in
            if let interval = (event as? MPSkipIntervalCommandEvent)?.interval {
                streamPlayer.skip(-interval)
                return .success
            }
            return .commandFailed
        }
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { [streamPlayer] (event) -> MPRemoteCommandHandlerStatus in
            if let positionTime = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                streamPlayer.seek(position: positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    /// Toggle the skip buttons visibility, such as when live stream.
    private func setSeekingEnabled(_ enabled: Bool) {
        skip(enabled: enabled)
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = enabled
    }

    func skip(enabled: Bool) {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.skipForwardCommand.isEnabled = enabled
        remoteCommandCenter.skipBackwardCommand.isEnabled = enabled
    }
}
