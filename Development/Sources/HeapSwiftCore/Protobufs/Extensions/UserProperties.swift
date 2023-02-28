extension UserProperties {
    
    init(withInitialPayloadFor user: UserToUpload, sdkInfo: SDKInfo) {
        self.init()
        
        envID = user.environmentId
        userID = user.userId
        initialDevice = sdkInfo.deviceInfo
        initialApplication = sdkInfo.applicationInfo
        library = sdkInfo.libraryInfo
    }
    
    init(withUserPropertiesFor user: UserToUpload, sdkInfo: SDKInfo) {
        self.init()
        
        envID = user.environmentId
        userID = user.userId
        properties = user.pendingUserProperties.mapValues(Value.init(value:))
        library = sdkInfo.libraryInfo
    }
}
