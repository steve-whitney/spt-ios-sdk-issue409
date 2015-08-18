import Foundation

let SPOTIFY_CLIENT_ID = "redacted"
let SPOTIFY_CALLBACK_URL = "redacted"
let SPOTIFY_TOKEN_SWAP_SERVICE_URL = "redacted"
let SPOTIFY_TOKEN_REFRESH_SERVICE_URL = "redacted"
let SPOTIFY_SESSION_USER_DEFAULTS_KEY = "redacted"
let SPOTIFY_DISK_CACHE_CAPACITY: UInt = 16 * 1024 * 1024

protocol ISpotifyProxy {
    var currentSession: SPTSession? { get }
    func loginViaUI() -> Void
    func playURI(uri: SPTTrack) -> Void
    func workaround() -> Void
    func sptPlaylistList_playlistsForUserWithSession(#callback: SPTRequestCallback) -> Void
    func sptPlaylistSnapshot_playlistWithURI(uri: NSURL, callback: SPTRequestCallback) -> Void
    func sptPlaylistList_createPlaylistWithName(name: String, callback: SPTPlaylistCreationCallback) -> Void
    func sptPlaylistSnapshot_addTrackToPlaylist(sptPlaylistSnapshot: SPTPlaylistSnapshot, track: SPTTrack, callback: SPTErrorableOperationCallback) -> Void
}

class DefaultSpotifyProxyImpl : NSObject, ISpotifyProxy, SPTAuthViewDelegate, SPTAudioStreamingDelegate {

    let spotifyAuthenticator = SPTAuth.defaultInstance()
    let underneathViewController: UIViewController
    private var _currentSession: SPTSession?
    private var playbackDelegate: SPTAudioStreamingPlaybackDelegate!
    private var isWorkingAround = false
    private var currSptTrack: SPTTrack!
    let player: SPTAudioStreamingController
    var currentSession: SPTSession? {
        get { return _currentSession }
    }

    func workaround() {
        if (isWorkingAround) { return }
        mywarn(__FUNCTION__,msg:"STARTING workaround.")
        isWorkingAround = true
        player.stop(nil)
        return
    }

    init(underneathViewController: UIViewController) {
        self.underneathViewController = underneathViewController
        player = SPTAudioStreamingController(clientId: SPOTIFY_CLIENT_ID)
        player.diskCache = SPTDiskCache(capacity: SPOTIFY_DISK_CACHE_CAPACITY)
        uris = ["fu","bar"]
        super.init()
        spotifyAuthenticator.clientID = SPOTIFY_CLIENT_ID
        spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPublicScope, SPTAuthUserReadPrivateScope]
        spotifyAuthenticator.redirectURL = NSURL(string: SPOTIFY_CALLBACK_URL)
        spotifyAuthenticator.tokenSwapURL = NSURL(string: SPOTIFY_TOKEN_SWAP_SERVICE_URL)
        spotifyAuthenticator.tokenRefreshURL = NSURL(string: SPOTIFY_TOKEN_REFRESH_SERVICE_URL)
        spotifyAuthenticator.sessionUserDefaultsKey = SPOTIFY_SESSION_USER_DEFAULTS_KEY
    }

    func loginViaUI() {
        let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
        spotifyAuthenticationViewController.delegate = self
        spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        spotifyAuthenticationViewController.definesPresentationContext = true
        underneathViewController.presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
    }

    // SPTAuthViewDelegate protocol methods
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        assert((nil != session),"oops")
        let accessToken = session!.accessToken
        SPTUser.requestCurrentUserWithAccessToken(accessToken, callback: handleRequestCurrentUserWithAccessTokenCallback)
        self._currentSession = session!
    }

    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        assert(false,"*** SPOTIFY LOGIN CANCELLED")
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        assert(false,"*** SPOTIFY AUTH FAILURE: error=\(error)")
    }

    private func handleRequestCurrentUserWithAccessTokenCallback(error: NSError!, object: AnyObject!) {
        assert((nil == error),"oops -- \(error)")
        self.player.loginWithSession(self.currentSession, callback: self.spotifyHandlerForLoginWithSession)
    }
    func spotifyHandlerForLoginWithSession (error: NSError!) -> Void {
        assert((nil==error),"spotify.com -- error activating streaming controller: \(error)")
        self.player.delegate = self as SPTAudioStreamingDelegate
        self.player.playbackDelegate = self.playbackDelegate  /*FIXME: spot-prox should implement delegate and so this should be 'self as SPTAudioStreamingPlaybackDelegate'*/
    }

    func sptPlaylistList_playlistsForUserWithSession(#callback: SPTRequestCallback) -> Void {
        SPTPlaylistList.playlistsForUserWithSession(self.currentSession, callback: callback)
    }
    func sptPlaylistSnapshot_playlistWithURI(uri: NSURL, callback: SPTRequestCallback) -> Void {
        SPTPlaylistSnapshot.playlistWithURI(uri, session: self.currentSession, callback: callback)
    }
    func sptPlaylistList_createPlaylistWithName(name: String, callback: SPTPlaylistCreationCallback) -> Void {
        SPTPlaylistList.createPlaylistWithName(name, publicFlag:true, session:self.currentSession, callback: callback)
    }
    func sptPlaylistSnapshot_addTrackToPlaylist(sptPlaylistSnapshot: SPTPlaylistSnapshot, track: SPTTrack, callback: SPTErrorableOperationCallback) -> Void {
        var nsArrTracks: NSArray = NSArray(array:[track])
        sptPlaylistSnapshot.addTracksToPlaylist(nsArrTracks as [AnyObject], withSession:self.currentSession, callback: callback)
    }

    func assignPlaybackDelegate(pbDelegate: SPTAudioStreamingPlaybackDelegate) {
        self.playbackDelegate = pbDelegate
        player.playbackDelegate = pbDelegate
    }

    private var ix = -1
    let uris: [String]

    func playURI(uri: SPTTrack) {
        currSptTrack = uri
        let sptTrackProvider = uri as SPTTrackProvider
        let playableUri = sptTrackProvider.playableUri() // i know right?
        player.playURIs([playableUri], withOptions:nil, callback:nil)
    }

    //MARK - SPTAudioStreamingDelegate

    /** Called when the streaming controller logs in successfully.
     @param audioStreaming The object that sent the message.
     */
    //-(void)audioStreamingDidLogin:(SPTAudioStreamingController *)audioStreaming;
    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController?) -> Void {
        myinfo(__FUNCTION__,msg:"invoked")
    }

    /** Called when the streaming controller logs out.
     @param audioStreaming The object that sent the message.
     */
    //-(void)audioStreamingDidLogout:(SPTAudioStreamingController *)audioStreaming;
    func audioStreamingDidLogout(audioStreaming: SPTAudioStreamingController?) -> Void {
        myinfo(__FUNCTION__,msg:"invoked")
    }

    /** Called when the streaming controller encounters a temporary connection error.
     You should not throw an error to the user at this point. The library will attempt to reconnect without further action.
     @param audioStreaming The object that sent the message.
     */
    //-(void)audioStreamingDidEncounterTemporaryConnectionError:(SPTAudioStreamingController *)audioStreaming;
    func audioStreamingDidEncounterTemporaryConnectionError(audioStreaming: SPTAudioStreamingController?) -> Void {
        myinfo(__FUNCTION__,msg:"invoked")
    }

    /** Called when the streaming controller encounters a fatal error.
     At this point it may be appropriate to inform the user of the problem.
     @param audioStreaming The object that sent the message.
     @param error The error that occurred.
     */
    //-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didEncounterError:(NSError *)error;
    func audioStreaming(audioStreaming: SPTAudioStreamingController?, didEncounterError error: NSError?) -> Void {
        myerr(__FUNCTION__,msg:"error=\(error)")
    }

    /** Called when the streaming controller recieved a message for the end user from the Spotify service.
     This string should be presented to the user in a reasonable manner.
     @param audioStreaming The object that sent the message.
     @param message The message to display to the user.
     */
    //-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message;
    func audioStreaming(# audioStreaming: SPTAudioStreamingController?, didReceiveMessage message: NSString?) -> Void {
        myinfo(__FUNCTION__,msg:"message=\(message)")
    }

    /** Called when network connectivity is lost.
     @param audioStreaming The object that sent the message.
     */
    //-(void)audioStreamingDidDisconnect:(SPTAudioStreamingController *)audioStreaming;
    func audioStreamingDidDisconnect(audioStreaming: SPTAudioStreamingController?) -> Void {
        myinfo(__FUNCTION__,msg:"invoked")
    }

    /** Called when network connectivitiy is back after being lost.
     @param audioStreaming The object that sent the message.
     */
    //-(void)audioStreamingDidReconnect:(SPTAudioStreamingController *)audioStreaming;
    func audioStreamingDidReconnect(audioStreaming: SPTAudioStreamingController?) -> Void {
        myinfo(__FUNCTION__,msg:"invoked")
        if (isWorkingAround) {
            mywarn(__FUNCTION__,msg:"FINISHING workaround.")
            self.playURI(currSptTrack)
            isWorkingAround = false
        }
            
    }
    
    //logging junk.
    lazy var classname_: String? = nil
    func classname() -> String {
        classname_ = classname_ ?? split(reflect(self).summary, maxSplit: 1, isSeparator: {$0 == "."})[1]
        return classname_!
    }
    private func myerr(fn: String, msg: String) {
        NSLog("ERROR - %@:\(fn) - \(msg)",classname())
    }
    private func mywarn(fn: String, msg: String) {
        NSLog("WARN  - %@:\(fn) - \(msg)",classname())
    }
    private func myinfo(fn: String, msg: String) {
        NSLog("INFO  - %@:\(fn) - \(msg)",classname())
    }
    private func mydbg(fn: String, msg: String) {
        NSLog("DEBUG - %@:\(fn) - \(msg)",classname())
    }
    private func mytrace(fn: String, msg: String) {
        NSLog("TRACE - %@:\(fn)() - \(msg)",classname())
    }

}
