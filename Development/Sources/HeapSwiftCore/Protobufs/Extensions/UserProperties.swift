extension UserProperties {
    
    init(withInitialPayloadFor user: UserToUpload) {
        self.init()
        
        envID = user.environmentId
        userID = user.userId
        initialDevice = SDKInfo.shared.deviceInfo
        initialApplication = SDKInfo.shared.applicationInfo
        library = SDKInfo.shared.libraryInfo
    }
    
    init(withUserPropertiesFor user: UserToUpload) {
        self.init()
        
        envID = user.environmentId
        userID = user.userId
        properties = user.pendingUserProperties.mapValues(Value.init(value:))
        library = SDKInfo.shared.libraryInfo
    }
}
