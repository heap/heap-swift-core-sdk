// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: identify.proto
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

struct CoreSdk_V1_UserIdentification {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var envID: String = String()

  var userID: String = String()

  var identity: String = String()

  var time: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _time ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_time = newValue}
  }
  /// Returns true if `time` has been explicitly set.
  var hasTime: Bool {return self._time != nil}
  /// Clears the value of `time`. Subsequent reads from it will return its default value.
  mutating func clearTime() {self._time = nil}

  var library: CoreSdk_V1_LibraryInfo {
    get {return _library ?? CoreSdk_V1_LibraryInfo()}
    set {_library = newValue}
  }
  /// Returns true if `library` has been explicitly set.
  var hasLibrary: Bool {return self._library != nil}
  /// Clears the value of `library`. Subsequent reads from it will return its default value.
  mutating func clearLibrary() {self._library = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _time: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
  fileprivate var _library: CoreSdk_V1_LibraryInfo? = nil
}

#if swift(>=5.5) && canImport(_Concurrency)
extension CoreSdk_V1_UserIdentification: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "core_sdk.v1"

extension CoreSdk_V1_UserIdentification: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".UserIdentification"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "env_id"),
    2: .standard(proto: "user_id"),
    3: .same(proto: "identity"),
    4: .same(proto: "time"),
    5: .same(proto: "library"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.envID) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.userID) }()
      case 3: try { try decoder.decodeSingularStringField(value: &self.identity) }()
      case 4: try { try decoder.decodeSingularMessageField(value: &self._time) }()
      case 5: try { try decoder.decodeSingularMessageField(value: &self._library) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.envID.isEmpty {
      try visitor.visitSingularStringField(value: self.envID, fieldNumber: 1)
    }
    if !self.userID.isEmpty {
      try visitor.visitSingularStringField(value: self.userID, fieldNumber: 2)
    }
    if !self.identity.isEmpty {
      try visitor.visitSingularStringField(value: self.identity, fieldNumber: 3)
    }
    try { if let v = self._time {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    } }()
    try { if let v = self._library {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: CoreSdk_V1_UserIdentification, rhs: CoreSdk_V1_UserIdentification) -> Bool {
    if lhs.envID != rhs.envID {return false}
    if lhs.userID != rhs.userID {return false}
    if lhs.identity != rhs.identity {return false}
    if lhs._time != rhs._time {return false}
    if lhs._library != rhs._library {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
