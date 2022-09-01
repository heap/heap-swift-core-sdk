extension Event.Custom {
    init(name: String, properties: [String: Value]) {
        self.init()
        self.name = name
        self.properties = properties
    }
}

extension Event.OneOf_Kind {
    static func custom(name: String, properties: [String: Value]) -> Event.OneOf_Kind {
        return .custom(.init(name: name, properties: properties))
    }
}
