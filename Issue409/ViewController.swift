import UIKit

class ViewController: UIViewController {

    var sptProx: ISpotifyProxy!
    var playlistMgr: IPlaylistManager!
    private(set) var sptTracks: SpotifyTracks?

    @IBAction func loginDidTouchDown(sender: AnyObject) {
        NSLog("\(__FUNCTION__) invoked.")
        sptProx.loginViaUI()
    }

    @IBAction func playFirstSong() {
        sptProx.playURI(sptTracks!.nextTrack())
    }
    @IBAction func skipToNextSong() {
        sptProx.playURI(sptTracks!.nextTrack())
    }
    @IBAction func workaround() {
        sptProx.workaround()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        sptProx = DefaultSpotifyProxyImpl(underneathViewController: self as UIViewController)
        // Do any additional setup after loading the view, typically from a nib.
        SpotifyTracks.newInstanceAsyncFromURIs(["spotify:track:2HXxga0tVhjAFp3ky2Xc7u","spotify:track:4s0O8MtLsh6LhbEVkoTwv6"], callback: {
            (val: SpotifyTracks) -> () in
            self.sptTracks = val
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

