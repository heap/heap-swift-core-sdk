import Foundation

// See https://stackoverflow.com/a/45536811
let cookieAllowedCharacterSet = CharacterSet(charactersIn: "abdefghijklmnqrstuvxyzABDEFGHIJKLMNQRSTUVXYZ0123456789!#$%&'()*+-./:<>?@[]^_`{|}~")

extension String {
    func encodingForCookie() -> String? {
        addingPercentEncoding(withAllowedCharacters: cookieAllowedCharacterSet)
    }
}

extension State {
    func toHeapJsCookiePayload() -> String? {
        let payload = [
            "userId": AnyJSONEncodable(wrapped: environment.userID),
            "sessionId": AnyJSONEncodable(wrapped: sessionInfo.id),
            "identity": environment.hasIdentity ? AnyJSONEncodable(wrapped: environment.identity) : AnyJSONEncodable(wrapped: nil as String?),
        ]
        
        do {
            let data = try JSONEncoder().encode(payload._toHeapJSON())
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    func toHeapJsCookie(settings: HeapJsSettings, timestamp: Date = Date()) -> HTTPCookie? {
        guard let value = toHeapJsCookiePayload()?.encodingForCookie() else { return nil }
        
        var properties: [HTTPCookiePropertyKey : Any] = [
            .domain: settings.domain,
            .path: settings.path,
            .name: State.heapJsCookieName(for: environment.envID),
            .value: value,
            
            // There are nuances to session cookies that require specific
            // environment configuration, namely setting the `processPool`.
            // We're not going to handle that so we instead set a 1 year
            // cookie.
            //
            // This will have implications if the app removes the integration
            // since they will need to manually remove the cookie with
            // `removeHeapJsCookie`.
            .expires: timestamp.addingTimeInterval(60 * 60 * 24 * 365),
        ]
        
        if settings.secure {
            properties[.secure] = "TRUE"
        }
        
        // Use the same logic as heap.js for setting cookies.
        // Same site is not set on iOS 12 due to a Safari bug.
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *) {
            properties[.sameSitePolicy] = settings.secure ? "None" : "Lax"
        }
        
        return .init(properties: properties)
    }
    
    static func heapJsCookieName(for environmentId: String) -> String {
        // This cookie name follows the specific conventions of heap.js 4 and
        // overrides a cookie named "_hp2_id.\(environmentId)" when present.
        "_hp2_wv_id.\(environmentId)"
    }
}
