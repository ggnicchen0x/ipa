import Foundation

public enum ErrorSanitizer {
    /// Sanitizes any user-facing error message or system description to prevent revealing internal paths,
    /// game bundle folders, mod file names, or container directory structures.
    public static func sanitize(_ message: String) -> String {
        var text = message
        
        // 1. Detect target occupied / conflict messages
        if text.localizedCaseInsensitiveContains("already patched by another") ||
           text.localizedCaseInsensitiveContains("target_occupied") ||
           text.localizedCaseInsensitiveContains("已被另一个补丁") ||
           text.localizedCaseInsensitiveContains("đã được một dự án patch khác") {
            return "A conflicting feature is already active. Please reset changes or revert active mods before applying this one."
        }
        
        // 2. Replace container roots, game paths, assetindexers, and directory structures
        let patterns = [
            #"(?:/private)?/var/mobile/Containers/Data/Application/[A-Fa-f0-9\-]+/[^\s'"]+"#,
            #"(?:/private)?/var/mobile/[^\s'"]+"#,
            #"com\.dts\.[a-zA-Z0-9_\-\./~]+"#,
            #"Documents/contentcache/[^\s'"]+"#,
            #"gameassetbundles/[^\s'"]+"#,
            #"assetindexer\.[^\s'"]+"#,
            #"Library/Preferences/[^\s'"]+"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                text = regex.stringByReplacingMatches(
                    in: text,
                    options: [],
                    range: NSRange(location: 0, length: (text as NSString).length),
                    withTemplate: "game resource"
                )
            }
        }
        
        return text
    }
}
