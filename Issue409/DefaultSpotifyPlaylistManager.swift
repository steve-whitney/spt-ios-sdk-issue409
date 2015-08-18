import Foundation

protocol IPlaylistManager {
    func start() -> Void
}

class DefaultSpotifyPlaylistManager : IPlaylistManager
{
    let spotifyProxy: ISpotifyProxy
    private(set) var playlistSnapshot: SPTPlaylistSnapshot?

    init(spotifyProxy: ISpotifyProxy) {
        self.spotifyProxy = spotifyProxy
    }

    func start() {
        recallPlaylistPagination()
    }

    private func recallPlaylistPagination() {
        let lambda = self.generateCallbackFor_playlistsForUserWithSession(__FUNCTION__, msg: "looking for playlist names")
        spotifyProxy.sptPlaylistList_playlistsForUserWithSession(callback: lambda)
    }

    private func generateCallbackFor_playlistsForUserWithSession(fn: String, msg: String) -> (NSError?, AnyObject?) -> Void {
        let _fn = fn
        let _msg = msg
        func rv(error: NSError?, object: AnyObject?) -> Void {
            assert(false,"OOPS, Issue409 REPRODUCTION FAILED: error=\(error) object=\(object)")
        }
        return rv
    }

}
