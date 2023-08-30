import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

private enum MyEnum: String {
    case val1 = "VALUE 1"
    case val2 = "VALUE 2"
}

extension MyEnum: HeapPropertyValue {
    var heapValue: String { rawValue }
}

final class TruncationAndSanitizationSpec: HeapSpec {
    
    override func spec() {
        
        describe("[String: HeapPropertyValue].sanitized") {
            
            beforeEach {
                HeapLogger.shared.logLevel = .trace
            }
            
            afterEach {
                HeapLogger.shared.logLevel = .info
            }
            
            it("removes empty and whitespace-only keys") {
                
                let inputValue: [String: HeapPropertyValue] = [
                    "\n\t key\n\t " : "value",
                    ""              : "empty",
                    "   "           : "blank",
                    "\n\t \n\t "    : "assorted",
                ]
                
                let expectedValue: [String: String] = [
                    "\n\t key\n\t " : "value",
                ]
                
                expect(inputValue.sanitized(methodName: "test")).to(equal(expectedValue))
            }
            
            it("removes empty and whitespace-only values") {
                
                let inputValue: [String: HeapPropertyValue] = [
                    "key"      : "\n\t value\n\t ",
                    "empty"    :  "",
                    "blank"    : "   ",
                    "assorted" : "\n\t \n\t ",
                ]
                
                let expectedValue: [String: String] = [
                    "key"      : "\n\t value\n\t ",
                ]
                
                expect(inputValue.sanitized(methodName: "test")).to(equal(expectedValue))
            }
            
            it("does not omit properties where the key is the maximum length") {
                
                let inputValue: [String: HeapPropertyValue] = [
                    String(repeating: "あ", count: 512) : "value",
                ]
                
                let expectedValue: [String: String] = [
                    String(repeating: "あ", count: 512) : "value",
                ]
                
                expect(inputValue.sanitized(methodName: "test")).to(equal(expectedValue))
            }
            
            it("omits properties where the key is above the maximum length") {
                
                let inputValue: [String: HeapPropertyValue] = [
                    String(repeating: "あ", count: 513) : "value",
                ]
                
                expect(inputValue.sanitized(methodName: "test")).to(beEmpty())
            }
            
            it("truncates properties that are more than 1024 characters long") {
                
                let inputValue: [String: HeapPropertyValue] = [
                    "key" : String(repeating: "あ", count: 1030)
                ]
                
                let expectedValue: [String: String] = [
                    "key" : String(repeating: "あ", count: 1024)
                ]
                
                expect(inputValue.sanitized(methodName: "test")).to(equal(expectedValue))
            }
            
            context("compatible types") {
                
                it("supports Int values") {
                    
                    let inputValue: [String: HeapPropertyValue] = [
                        "a": 1,
                        "b": 0,
                        "c": -1,
                    ]
                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "1",
                        "b": "0",
                        "c": "-1",
                    ]))
                }

                it("supports Double values") {

                    let inputValue: [String: HeapPropertyValue] = [
                        "a": 7.5,
                        "b": 0.0,
                        "c": -7.25,
                    ]

                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "7.5",
                        "b": "0.0",
                        "c": "-7.25",
                    ]))
                }

                it("supports boolean values") {
                    
                    let inputValue: [String: HeapPropertyValue] = [
                        "a": true,
                        "b": false,
                        "c": true,
                    ]

                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "true",
                        "b": "false",
                        "c": "true",
                    ]))
                }

                it("supports string values") {
                    
                    let inputValue: [String: HeapPropertyValue] = [
                        "a": "😀",
                        "b": "🤨",
                        "c": "😫",
                    ]

                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "😀",
                        "b": "🤨",
                        "c": "😫",
                    ]))
                }

                it("supports custom values") {
                    
                    let inputValue: [String: HeapPropertyValue] = [
                        "a": MyEnum.val1,
                        "b": MyEnum.val2,
                        "c": MyEnum.val1,
                    ]
                    
                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "VALUE 1",
                        "b": "VALUE 2",
                        "c": "VALUE 1",
                    ]))
                }
                
                it("supports common non-literal types") {
                    
                    let inputValue: [String: HeapPropertyValue] = [
                        "a": 1 as Int64,
                        "b": 2 as Int32,
                        "c": 3 as Int16,
                        "d": 4 as Int8,
                        "e": 5.2 as Float,
                        "f": "test"[...],
                    ]
                    
                    expect(inputValue.sanitized(methodName: "test")).to(equal([
                        "a": "1",
                        "b": "2",
                        "c": "3",
                        "d": "4",
                        "e": "5.2",
                        "f": "test",
                    ]))
                }
            }
        }
        
        describe("String.truncated") {
            
            it("does not truncate text exactly 1024 characters long") {

                let inputValue = String(repeating: "あ", count: 1024)
                let expectedValue = inputValue
                
                let result = inputValue.truncated()
                
                expect(result.result).to(equal(expectedValue))
                expect(result.wasTruncated).to(beFalse())
            }

            it("truncates text that is more than 1024 characters long") {

                let inputValue = String(repeating: "あ", count: 1030)
                let expectedValue = String(repeating: "あ", count: 1024)
                
                let result = inputValue.truncated()
                
                expect(result.result).to(equal(expectedValue))
                expect(result.wasTruncated).to(beTrue())
            }

            it("does not partially truncate emoji") {

                let inputValue = String(repeating: "あ", count: 1020).appending("👨‍👨‍👧‍👧")
                let expectedValue = String(repeating: "あ", count: 1020)
                
                let result = inputValue.truncated()
                
                expect(result.result).to(equal(expectedValue))
                expect(result.wasTruncated).to(beTrue())

            }
            
            it("does not partially truncate diacritics") {

                let inputValue = String(repeating: "あ", count: 1000).appending("A̶̧̨̨̡̡̼̯̯͖̖͔̗̞̣̯̲̰̞̹͎̝̱̪̬̹̰͔̹̫̙̤̞̯͓̖̣͉̻̣̙͉̰̦͔͚̔̍̍̃͌͆̎̊̈̇̽̿̕͜͠͝ͅ")
                let expectedValue = String(repeating: "あ", count: 1000)
                
                let result = inputValue.truncated()
                
                expect(result.result).to(equal(expectedValue))
                expect(result.wasTruncated).to(beTrue())
            }
        }
        
        describe("String.trimmed") {
            
            it("trims leading and trailing whitespace and new lines") {
                
                let expectedValue = "inputValue"
                let inputValue = "  \t\n \(expectedValue)     \t\t\n"
                
                let result = inputValue.trimmed
                expect(result).to(equal(expectedValue))
            }
            
            it("returns nil if string was only whitespace") {
                
                let inputValue = "    \t\n    "
                
                let result = inputValue.trimmed
                expect(result).to(beNil())
            }
        }
    }
}
