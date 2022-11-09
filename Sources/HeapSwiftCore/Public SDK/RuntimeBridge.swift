import Foundation

// TODO: Wire up and document RuntimeBridge.
public protocol RuntimeBridge {
    
    func didStartRecording(options: [Option: Any], complete: @escaping () -> Void)
    func didStopRecording(complete: @escaping () -> Void)
    func sessionDidStart(sessionId: String, timestamp: Date, foregrounded: Bool, complete: @escaping () -> Void)
    
    func applicationDidEnterForeground(timestamp: Date, complete: @escaping () -> Void)
    func applicationDidEnterBackground(timestamp: Date, complete: @escaping () -> Void)

    func reissuePageview(_ pageview: Pageview, sessionId: String, timestamp: Date, complete: @escaping (_ pageview: Pageview?) -> Void)
}
