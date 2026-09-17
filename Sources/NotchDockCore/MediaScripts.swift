import Foundation

/// App-owned scripts, also compiled against Music’s dictionary by the macOS regression test.
public enum MediaScripts {
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
}
