import Foundation
import Nimble

func haveMetadata(environmentId: String, userId: String, identity: String?, library: String) -> Predicate<URLRequest> {
    
    .init { actualExpression in
        
        let msg = ExpectationMessage.expectedActualValueTo("have appropriate metadata")
        
        func doesNotMatch(_ reason: @autoclosure () -> String) -> PredicateResult {
            return .init(
                status: .doesNotMatch,
                message: msg.appended(message: " (\(reason()))")
            )
        }
        
        guard let request = try actualExpression.evaluate() else {
            return .init(
                status: .fail,
                message: msg.appendedBeNilHint()
            )
        }
        
        guard let url = request.url else {
            return doesNotMatch("no URL")
        }
        
        guard let headerEnvId = request.allHTTPHeaderFields?["X-Heap-Env-Id"] else {
            return doesNotMatch("X-Heap-Env-Id header was missing")
        }
        
        guard headerEnvId == environmentId else {
            return doesNotMatch("X-Heap-Env-Id header was \(headerEnvId)")
        }
        
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
              let lastItem = queryItems.last else {
            return doesNotMatch("no query parameters")
        }
        
        guard !["b", "i"].contains(lastItem.name) else {
            return doesNotMatch("last query item was named \(lastItem.name)")
        }
        
        guard let queryEnvId = queryItems.first(where: { $0.name == "a" })?.value else {
            return doesNotMatch("no query parameter named \"a\"")
        }
        
        guard queryEnvId == environmentId else {
            return doesNotMatch("a=\(queryEnvId)")
        }
        
        guard let queryUserId = queryItems.first(where: { $0.name == "u" })?.value else {
            return doesNotMatch("no query parameter named \"u\"")
        }
        
        guard queryUserId == userId else {
            return doesNotMatch("u=\(queryUserId)")
        }
        
        let queryIdentity = queryItems.first(where: { $0.name == "i" })?.value
        
        if let identity = identity {
            guard let queryIdentity = queryIdentity else {
                return doesNotMatch("no query parameter named \"i\"")
            }
            
            guard queryIdentity == identity else {
                return doesNotMatch("i=\(queryIdentity)")
            }
        } else if let queryIdentity = queryIdentity {
            guard queryIdentity == "" else {
                return doesNotMatch("i=\(queryIdentity)")
            }
        }
        
        guard let queryLibrary = queryItems.first(where: { $0.name == "b" })?.value else {
            return doesNotMatch("no query parameter named \"b\"")
        }
        
        guard queryLibrary == queryLibrary else {
            return doesNotMatch("b=\(queryLibrary)")
        }
        
        return .init(status: .matches, message: msg)
    }
}
