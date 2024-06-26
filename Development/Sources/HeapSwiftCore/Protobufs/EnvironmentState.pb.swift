// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: EnvironmentState.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct EnvironmentState {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var envID: String {
    get {return _storage._envID}
    set {_uniqueStorage()._envID = newValue}
  }

  var userID: String {
    get {return _storage._userID ?? String()}
    set {_uniqueStorage()._userID = newValue}
  }
  /// Returns true if `userID` has been explicitly set.
  var hasUserID: Bool {return _storage._userID != nil}
  /// Clears the value of `userID`. Subsequent reads from it will return its default value.
  mutating func clearUserID() {_uniqueStorage()._userID = nil}

  var identity: String {
    get {return _storage._identity ?? String()}
    set {_uniqueStorage()._identity = newValue}
  }
  /// Returns true if `identity` has been explicitly set.
  var hasIdentity: Bool {return _storage._identity != nil}
  /// Clears the value of `identity`. Subsequent reads from it will return its default value.
  mutating func clearIdentity() {_uniqueStorage()._identity = nil}

  var properties: Dictionary<String,CoreSdk_V1_Value> {
    get {return _storage._properties}
    set {_uniqueStorage()._properties = newValue}
  }

  var sessionInfo: CoreSdk_V1_SessionInfo {
    get {return _storage._sessionInfo ?? CoreSdk_V1_SessionInfo()}
    set {_uniqueStorage()._sessionInfo = newValue}
  }
  /// Returns true if `sessionInfo` has been explicitly set.
  var hasSessionInfo: Bool {return _storage._sessionInfo != nil}
  /// Clears the value of `sessionInfo`. Subsequent reads from it will return its default value.
  mutating func clearSessionInfo() {_uniqueStorage()._sessionInfo = nil}

  var unattributedPageviewInfo: CoreSdk_V1_PageviewInfo {
    get {return _storage._unattributedPageviewInfo ?? CoreSdk_V1_PageviewInfo()}
    set {_uniqueStorage()._unattributedPageviewInfo = newValue}
  }
  /// Returns true if `unattributedPageviewInfo` has been explicitly set.
  var hasUnattributedPageviewInfo: Bool {return _storage._unattributedPageviewInfo != nil}
  /// Clears the value of `unattributedPageviewInfo`. Subsequent reads from it will return its default value.
  mutating func clearUnattributedPageviewInfo() {_uniqueStorage()._unattributedPageviewInfo = nil}

  var sessionExpirationDate: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _storage._sessionExpirationDate ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_uniqueStorage()._sessionExpirationDate = newValue}
  }
  /// Returns true if `sessionExpirationDate` has been explicitly set.
  var hasSessionExpirationDate: Bool {return _storage._sessionExpirationDate != nil}
  /// Clears the value of `sessionExpirationDate`. Subsequent reads from it will return its default value.
  mutating func clearSessionExpirationDate() {_uniqueStorage()._sessionExpirationDate = nil}

  var lastObservedVersion: CoreSdk_V1_ApplicationInfo {
    get {return _storage._lastObservedVersion ?? CoreSdk_V1_ApplicationInfo()}
    set {_uniqueStorage()._lastObservedVersion = newValue}
  }
  /// Returns true if `lastObservedVersion` has been explicitly set.
  var hasLastObservedVersion: Bool {return _storage._lastObservedVersion != nil}
  /// Clears the value of `lastObservedVersion`. Subsequent reads from it will return its default value.
  mutating func clearLastObservedVersion() {_uniqueStorage()._lastObservedVersion = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

#if swift(>=5.5) && canImport(_Concurrency)
extension EnvironmentState: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension EnvironmentState: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "EnvironmentState"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "env_id"),
    2: .standard(proto: "user_id"),
    3: .same(proto: "identity"),
    4: .same(proto: "properties"),
    8: .standard(proto: "session_info"),
    9: .standard(proto: "unattributed_pageview_info"),
    10: .standard(proto: "session_expiration_date"),
    7: .standard(proto: "last_observed_version"),
  ]

  fileprivate class _StorageClass {
    var _envID: String = String()
    var _userID: String? = nil
    var _identity: String? = nil
    var _properties: Dictionary<String,CoreSdk_V1_Value> = [:]
    var _sessionInfo: CoreSdk_V1_SessionInfo? = nil
    var _unattributedPageviewInfo: CoreSdk_V1_PageviewInfo? = nil
    var _sessionExpirationDate: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
    var _lastObservedVersion: CoreSdk_V1_ApplicationInfo? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _envID = source._envID
      _userID = source._userID
      _identity = source._identity
      _properties = source._properties
      _sessionInfo = source._sessionInfo
      _unattributedPageviewInfo = source._unattributedPageviewInfo
      _sessionExpirationDate = source._sessionExpirationDate
      _lastObservedVersion = source._lastObservedVersion
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        // The use of inline closures is to circumvent an issue where the compiler
        // allocates stack space for every case branch when no optimizations are
        // enabled. https://github.com/apple/swift-protobuf/issues/1034
        switch fieldNumber {
        case 1: try { try decoder.decodeSingularStringField(value: &_storage._envID) }()
        case 2: try { try decoder.decodeSingularStringField(value: &_storage._userID) }()
        case 3: try { try decoder.decodeSingularStringField(value: &_storage._identity) }()
        case 4: try { try decoder.decodeMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,CoreSdk_V1_Value>.self, value: &_storage._properties) }()
        case 7: try { try decoder.decodeSingularMessageField(value: &_storage._lastObservedVersion) }()
        case 8: try { try decoder.decodeSingularMessageField(value: &_storage._sessionInfo) }()
        case 9: try { try decoder.decodeSingularMessageField(value: &_storage._unattributedPageviewInfo) }()
        case 10: try { try decoder.decodeSingularMessageField(value: &_storage._sessionExpirationDate) }()
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every if/case branch local when no optimizations
      // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
      // https://github.com/apple/swift-protobuf/issues/1182
      if !_storage._envID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._envID, fieldNumber: 1)
      }
      try { if let v = _storage._userID {
        try visitor.visitSingularStringField(value: v, fieldNumber: 2)
      } }()
      try { if let v = _storage._identity {
        try visitor.visitSingularStringField(value: v, fieldNumber: 3)
      } }()
      if !_storage._properties.isEmpty {
        try visitor.visitMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,CoreSdk_V1_Value>.self, value: _storage._properties, fieldNumber: 4)
      }
      try { if let v = _storage._lastObservedVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
      } }()
      try { if let v = _storage._sessionInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 8)
      } }()
      try { if let v = _storage._unattributedPageviewInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 9)
      } }()
      try { if let v = _storage._sessionExpirationDate {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 10)
      } }()
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: EnvironmentState, rhs: EnvironmentState) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._envID != rhs_storage._envID {return false}
        if _storage._userID != rhs_storage._userID {return false}
        if _storage._identity != rhs_storage._identity {return false}
        if _storage._properties != rhs_storage._properties {return false}
        if _storage._sessionInfo != rhs_storage._sessionInfo {return false}
        if _storage._unattributedPageviewInfo != rhs_storage._unattributedPageviewInfo {return false}
        if _storage._sessionExpirationDate != rhs_storage._sessionExpirationDate {return false}
        if _storage._lastObservedVersion != rhs_storage._lastObservedVersion {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
