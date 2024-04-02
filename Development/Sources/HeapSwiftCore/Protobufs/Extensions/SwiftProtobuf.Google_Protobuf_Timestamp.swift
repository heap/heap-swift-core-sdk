import SwiftProtobuf

extension Google_Protobuf_Timestamp {
    
    var truncatedToSeconds: Google_Protobuf_Timestamp {
        var output = self
        output.nanos = 0
        return output
    }
}
