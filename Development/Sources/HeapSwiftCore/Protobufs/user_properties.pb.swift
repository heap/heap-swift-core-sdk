// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: user_properties.proto
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

/// User properties that will be attached to a user.
struct CoreSdk_V1_UserProperties {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var envID: String {
    get {return _storage._envID}
    set {_uniqueStorage()._envID = newValue}
  }

  var userID: String {
    get {return _storage._userID}
    set {_uniqueStorage()._userID = newValue}
  }

  var properties: Dictionary<String,CoreSdk_V1_Value> {
    get {return _storage._properties}
    set {_uniqueStorage()._properties = newValue}
  }

  var initialDevice: CoreSdk_V1_DeviceInfo {
    get {return _storage._initialDevice ?? CoreSdk_V1_DeviceInfo()}
    set {_uniqueStorage()._initialDevice = newValue}
  }
  /// Returns true if `initialDevice` has been explicitly set.
  var hasInitialDevice: Bool {return _storage._initialDevice != nil}
  /// Clears the value of `initialDevice`. Subsequent reads from it will return its default value.
  mutating func clearInitialDevice() {_uniqueStorage()._initialDevice = nil}

  var initialApplication: CoreSdk_V1_ApplicationInfo {
    get {return _storage._initialApplication ?? CoreSdk_V1_ApplicationInfo()}
    set {_uniqueStorage()._initialApplication = newValue}
  }
  /// Returns true if `initialApplication` has been explicitly set.
  var hasInitialApplication: Bool {return _storage._initialApplication != nil}
  /// Clears the value of `initialApplication`. Subsequent reads from it will return its default value.
  mutating func clearInitialApplication() {_uniqueStorage()._initialApplication = nil}

  var library: CoreSdk_V1_LibraryInfo {
    get {return _storage._library ?? CoreSdk_V1_LibraryInfo()}
    set {_uniqueStorage()._library = newValue}
  }
  /// Returns true if `library` has been explicitly set.
  var hasLibrary: Bool {return _storage._library != nil}
  /// Clears the value of `library`. Subsequent reads from it will return its default value.
  mutating func clearLibrary() {_uniqueStorage()._library = nil}

  var initialSessionInfo: CoreSdk_V1_SessionInfo {
    get {return _storage._initialSessionInfo ?? CoreSdk_V1_SessionInfo()}
    set {_uniqueStorage()._initialSessionInfo = newValue}
  }
  /// Returns true if `initialSessionInfo` has been explicitly set.
  var hasInitialSessionInfo: Bool {return _storage._initialSessionInfo != nil}
  /// Clears the value of `initialSessionInfo`. Subsequent reads from it will return its default value.
  mutating func clearInitialSessionInfo() {_uniqueStorage()._initialSessionInfo = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

#if swift(>=5.5) && canImport(_Concurrency)
extension CoreSdk_V1_UserProperties: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "core_sdk.v1"

extension CoreSdk_V1_UserProperties: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".UserProperties"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "env_id"),
    2: .standard(proto: "user_id"),
    3: .same(proto: "properties"),
    4: .standard(proto: "initial_device"),
    5: .standard(proto: "initial_application"),
    6: .same(proto: "library"),
    7: .standard(proto: "initial_session_info"),
  ]

  fileprivate class _StorageClass {
    var _envID: String = String()
    var _userID: String = String()
    var _properties: Dictionary<String,CoreSdk_V1_Value> = [:]
    var _initialDevice: CoreSdk_V1_DeviceInfo? = nil
    var _initialApplication: CoreSdk_V1_ApplicationInfo? = nil
    var _library: CoreSdk_V1_LibraryInfo? = nil
    var _initialSessionInfo: CoreSdk_V1_SessionInfo? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _envID = source._envID
      _userID = source._userID
      _properties = source._properties
      _initialDevice = source._initialDevice
      _initialApplication = source._initialApplication
      _library = source._library
      _initialSessionInfo = source._initialSessionInfo
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
        case 3: try { try decoder.decodeMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,CoreSdk_V1_Value>.self, value: &_storage._properties) }()
        case 4: try { try decoder.decodeSingularMessageField(value: &_storage._initialDevice) }()
        case 5: try { try decoder.decodeSingularMessageField(value: &_storage._initialApplication) }()
        case 6: try { try decoder.decodeSingularMessageField(value: &_storage._library) }()
        case 7: try { try decoder.decodeSingularMessageField(value: &_storage._initialSessionInfo) }()
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
      if !_storage._userID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._userID, fieldNumber: 2)
      }
      if !_storage._properties.isEmpty {
        try visitor.visitMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,CoreSdk_V1_Value>.self, value: _storage._properties, fieldNumber: 3)
      }
      try { if let v = _storage._initialDevice {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      } }()
      try { if let v = _storage._initialApplication {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
      } }()
      try { if let v = _storage._library {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
      } }()
      try { if let v = _storage._initialSessionInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
      } }()
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: CoreSdk_V1_UserProperties, rhs: CoreSdk_V1_UserProperties) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._envID != rhs_storage._envID {return false}
        if _storage._userID != rhs_storage._userID {return false}
        if _storage._properties != rhs_storage._properties {return false}
        if _storage._initialDevice != rhs_storage._initialDevice {return false}
        if _storage._initialApplication != rhs_storage._initialApplication {return false}
        if _storage._library != rhs_storage._library {return false}
        if _storage._initialSessionInfo != rhs_storage._initialSessionInfo {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
