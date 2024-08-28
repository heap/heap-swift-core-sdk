import Foundation

extension NotificationInteractionSource {
    var protoValue: NotificationInteraction.NotificationSource {
        switch self {
        case .unknown: return .sourceUnknown
        case .pushService: return .sourcePushService
        case .geofence: return .sourceGeofence
        case .interval: return .sourceTimeInterval
        case .calendar: return .sourceCalendar
        @unknown default: return .sourceUnknown
        }
    }
}
