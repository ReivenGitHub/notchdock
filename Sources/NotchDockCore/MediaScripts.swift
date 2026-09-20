import Foundation

/// App-owned scripts, also compiled against Music’s dictionary by the macOS regression test.
public enum MediaScripts {
    public enum Browser: String { case chrome, safari }
    public static func metadata(spotify: Bool) -> String {
        let duration = spotify ? "((duration of current track) / 1000)" : "(duration of current track)"
        let identifier = spotify ? "id of current track" : "persistent ID of current track"
        let artwork = spotify ? "try\nset coverURL to artwork url of current track as string\nend try" : ""
        let body = """
        if player state is stopped then return "stopped"
        set trackID to ""
        try
            set trackID to \(identifier) as string
        end try
        set coverURL to ""
        \(artwork)
        set separator to ASCII character 31
        return (player state as string) & separator & (name of current track as string) & separator & (artist of current track as string) & separator & (album of current track as string) & separator & (player position as string) & separator & (\(duration) as string) & separator & trackID & separator & coverURL
        """
        let bundleID = spotify ? "com.spotify.client" : "com.apple.Music"
        return """
        with timeout of 5 seconds
            if application id "\(bundleID)" is not running then return "stopped"
            tell application id "\(bundleID)"
                \(body)
            end tell
        end timeout
        """
    }
    public static let musicArtwork = """
    on run argv
        with timeout of 5 seconds
            if application id "com.apple.Music" is not running then return "none"
            tell application id "com.apple.Music"
                if player state is stopped then return "none"
                set selectedTrack to current track
                set selectedID to ""
                try
                    set selectedID to persistent ID of selectedTrack as string
                end try
                if selectedID is not (item 2 of argv) then return "stale"
                if (name of selectedTrack as string) is not (item 3 of argv) then return "stale"
                if (artist of selectedTrack as string) is not (item 4 of argv) then return "stale"
                if (album of selectedTrack as string) is not (item 5 of argv) then return "stale"
                try
                    if (count of artworks of selectedTrack) is 0 then return "none"
                    set imageBytes to raw data of artwork 1 of selectedTrack
                on error
                    return "none"
                end try
            end tell
            set destination to POSIX file (item 1 of argv)
            set outputFile to open for access destination with write permission
            try
                set eof outputFile to 0
                write imageBytes to outputFile
                close access outputFile
            on error
                try
                    close access outputFile
                end try
                return "none"
            end try
            return "ok"
        end timeout
    end run
    """

    /// Runs inside a YouTube tab only after the user enables JavaScript from Apple Events.
    public static let youtubeMetadataJavaScript = """
    (()=>{const v=document.querySelector('video');if(!v||v.readyState===0)return 'none';const m=navigator.mediaSession&&navigator.mediaSession.metadata;const clean=s=>String(s||'').replace(/[\\u001f\\r\\n]/g,' ').trim();const q=s=>clean(document.querySelector(s)?.textContent);const u=new URL(location.href);const id=u.searchParams.get('v')||u.pathname.split('/').filter(Boolean).pop()||location.href;const title=clean(m?.title)||q('h1 yt-formatted-string')||clean(document.title.replace(/ - YouTube$/,''));if(!title)return 'none';const artist=clean(m?.artist)||q('#channel-name a')||q('yt-formatted-string.byline a')||'YouTube';const album=clean(m?.album)||(location.hostname==='music.youtube.com'?'YouTube Music':'YouTube');const art=(m?.artwork&&m.artwork.length?m.artwork[m.artwork.length-1].src:'')||(u.searchParams.get('v')?'https://i.ytimg.com/vi/'+u.searchParams.get('v')+'/hqdefault.jpg':'');return [v.paused?'paused':'playing',title,artist,album,String(v.currentTime||0),String(v.duration||0),'youtube:'+id,art].map(clean).join('\\u001f')})()
    """

    public static func youtubeCommandJavaScript(_ command: String) -> String {
        switch command {
        case "playpause": return "(()=>{const v=document.querySelector('video');if(!v)return 'none';if(v.paused){v.play()}else{v.pause()}return 'ok'})()"
        case "previous track": return "(()=>{const b=document.querySelector('.ytp-prev-button,.previous-button');if(!b)return 'none';b.click();return 'ok'})()"
        case "next track": return "(()=>{const b=document.querySelector('.ytp-next-button,.next-button');if(!b)return 'none';b.click();return 'ok'})()"
        default: return "'none'"
        }
    }

    public static func youtube(browser: Browser) -> String {
        switch browser {
        case .chrome:
            return """
            on run argv
                if application id "com.google.Chrome" is not running then return "stopped"
                set jsCode to item 1 of argv
                set pausedAnswer to "stopped"
                tell application id "com.google.Chrome"
                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            if (URL of browserTab contains "youtube.com/") then
                                try
                                    set answer to execute browserTab javascript jsCode
                                    if answer is "ok" then return answer
                                    if answer starts with "playing" then return answer
                                    if answer starts with "paused" then set pausedAnswer to answer
                                on error
                                    return "browser-js-disabled"
                                end try
                            end if
                        end repeat
                    end repeat
                end tell
                return pausedAnswer
            end run
            """
        case .safari:
            return """
            on run argv
                if application id "com.apple.Safari" is not running then return "stopped"
                set jsCode to item 1 of argv
                set pausedAnswer to "stopped"
                tell application id "com.apple.Safari"
                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            if (URL of browserTab contains "youtube.com/") then
                                try
                                    set answer to do JavaScript jsCode in browserTab
                                    if answer is "ok" then return answer
                                    if answer starts with "playing" then return answer
                                    if answer starts with "paused" then set pausedAnswer to answer
                                on error
                                    return "browser-js-disabled"
                                end try
                            end if
                        end repeat
                    end repeat
                end tell
                return pausedAnswer
            end run
            """
        }
    }
}
