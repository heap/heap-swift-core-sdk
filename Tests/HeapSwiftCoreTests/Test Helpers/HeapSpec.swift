import Quick
import Foundation

import XCTest
import Quick

class HeapSpec: QuickSpec {
    override func record(_ issue: XCTIssue) {
        if issue.compactDescription.contains("HEAP_SPEC_RECORDED") { return }
        super.record(issue)
    }
}

func TestFailure(_ message: String, file: StaticString = #file, line: UInt = #line) -> NSError {
    if let spec = QuickSpec.current as? HeapSpec {
        let location = XCTSourceCodeLocation(filePath: file, lineNumber: line)
        let issue = XCTIssue(type: .assertionFailure, compactDescription: message, sourceCodeContext: XCTSourceCodeContext(location: location))
        spec.record(issue)
        return NSError(domain: "io.heap.TestFailure", code: 1, userInfo: [NSLocalizedDescriptionKey: "HEAP_SPEC_RECORDED: " + message])
    } else {
        return NSError(domain: "io.heap.TestFailure", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

func TestEnded() -> NSError {
    if QuickSpec.current is HeapSpec {
        return NSError(domain: "io.heap.TestEnded", code: 1, userInfo: [NSLocalizedDescriptionKey: "HEAP_SPEC_RECORDED"])
    } else {
        return NSError(domain: "io.heap.TestEnded", code: 2, userInfo: [:])
    }
}
