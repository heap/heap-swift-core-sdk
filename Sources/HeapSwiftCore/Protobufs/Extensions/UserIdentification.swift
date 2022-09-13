import Foundation

extension UserIdentification {
    
    init?(forIdentificationOf user: UserToUpload, at timestamp: Date) {
        guard let unwrappedIdentity = user.identity else { return nil }
        
        self.init()
        
        envID = user.environmentId
        userID = user.userId
        identity = unwrappedIdentity
        time = .init(date: timestamp)
        library = SDKInfo.shared.libraryInfo
    }
}
