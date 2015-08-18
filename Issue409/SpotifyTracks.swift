import Foundation

class SpotifyTracks {

    class func newInstanceAsyncFromURIs(uris: [String], callback: (SpotifyTracks) -> ()) -> Void {
        var tracks = [SPTTrack]()
        let count = uris.count
        for uri in uris {
            SPTTrack.trackWithURI(NSURL(string:uri), session: nil, callback: {
               (error: NSError!, untypedSptTrack: AnyObject!) -> Void in
               assert((nil == error),"oops: \(error)")
               let track = untypedSptTrack as! SPTTrack
               tracks.append(track)
               if (tracks.count == count) {
                   callback(SpotifyTracks(uris:tracks))
                   NSLog("HAVE SPTTrack's.")
               }
            })
        }
    }

    init(uris: [SPTTrack]) {
        assert((uris.count >= 1),"oops -- no uri's")
        self.uris = uris
    }

    private var ix = -1
    private let uris: [SPTTrack]

    func nextTrack() -> SPTTrack {
        ix = (++ix % uris.count)
        return uris[ix]
    }

}
