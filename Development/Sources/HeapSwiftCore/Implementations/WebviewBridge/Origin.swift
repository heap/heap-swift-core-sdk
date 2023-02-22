#if canImport(WebKit)

import WebKit

enum Origin: Equatable {
    case all
    case exact(protocol: String, host: String, port: Int)
    case subdomains(protocol: String, host: String, port: Int)
}

extension Origin {
    func matches(_ frame: WKFrameInfo) -> Bool {
        matches(frame.securityOrigin)
    }
    
    func matches(_ securityOrigin: WKSecurityOrigin) -> Bool {
        switch self {
        case .all: return true
        case let .exact(protocol: `protocol`, host: host, port: port):
            return securityOrigin.protocol == `protocol` && securityOrigin.host == host && (securityOrigin.port == port || securityOrigin.port == 0)
        case let .subdomains(protocol: `protocol`, host: host, port: port):
            return securityOrigin.protocol == `protocol` && securityOrigin.host.hasSuffix(host) && (securityOrigin.port == port || securityOrigin.port == 0)
        }
    }
}

extension Origin: RawRepresentable {
    
    init?(rawValue: String) {
        guard rawValue != "*" else {
            self = .all
            return
        }
        
        guard
            let components = URLComponents(string: rawValue),
            let `protocol` = components.scheme,
            var host = components.host
        else {
            return nil
        }
        
        let defaultPort: Int
        switch `protocol` {
        case "https":
            defaultPort = 443
        case "http":
            defaultPort = 80
        default:
            return nil
        }
        
        if host.hasPrefix("*.") {
            host.removeFirst()
            self = .subdomains(protocol: `protocol`, host: host, port: components.port ?? defaultPort)
        } else {
            self = .exact(protocol: `protocol`, host: host, port: components.port ?? defaultPort)
        }
    }
    
    var rawValue: String {
        switch self {
        case .all: return "*"
        case let .exact(protocol: `protocol`, host: host, port: port):
            return "\(`protocol`)://\(host):\(port)"
        case let .subdomains(protocol: `protocol`, host: host, port: port):
            return "\(`protocol`)://*\(host):\(port)"
        }
    }
}

extension WKSecurityOrigin {
    @nonobjc var heapDescription: String {
        if port != 0 {
            return "\(self.protocol)://\(self.host):\(self.port)"
        } else {
            return "\(self.protocol)://\(self.host)"
        }
    }
}

extension Origin: CustomStringConvertible {
    
    var description: String {
        return rawValue
    }
}

#endif
