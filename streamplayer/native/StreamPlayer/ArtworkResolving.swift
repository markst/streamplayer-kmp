import Combine
import Foundation

/// Turns an artwork URL into an image for Now Playing. Inject your own to share a cache,
/// add authentication, or stub images in tests. Emit `nil` when there is no image.
public protocol ArtworkResolving {
    func image(for url: URL) -> AnyPublisher<PlatformImage?, Never>
}

/// Default resolver; relies on the session's HTTP cache and does not keep images itself.
public struct URLSessionArtworkResolver: ArtworkResolving {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func image(for url: URL) -> AnyPublisher<PlatformImage?, Never> {
        session.dataTaskPublisher(for: url)
            .map { data, response in
                (response as? HTTPURLResponse)?.statusCode == 200 ? PlatformImage(data: data) : nil
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}
