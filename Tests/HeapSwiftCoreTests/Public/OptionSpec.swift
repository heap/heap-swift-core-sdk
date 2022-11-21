import Foundation
import Quick
import Nimble
import XCTest
@testable import HeapSwiftCore

extension Option {
    static let something = register(name: "something", type: .string)
    static let string = register(name: "test.string", type: .string)
    static let boolean = register(name: "test.boolean", type: .boolean)
    static let timeInterval = register(name: "test.timeInterval", type: .timeInterval)
    static let integer = register(name: "test.integer", type: .integer)
    static let url = register(name: "test.url", type: .url)
    static let data = register(name: "test.data", type: .data)
    static let object = register(name: "test.object", type: .object)
}

final class OptionSpec: HeapSpec {
    
    override func spec() {
        describe("Option.register") {
            
            it("returns an option with applied values") {
                let option = Option.register(name: "option1", type: .object)
                expect(option.name).to(equal("option1"))
                expect(option.type).to(equal(.object))
            }
            
            it("returns the same object when called multiple times") {
                let option2A = Option.register(name: "option2", type: .boolean)
                let option2B = Option.register(name: "option2", type: .boolean)
                
                expect(ObjectIdentifier(option2A)).to(equal(ObjectIdentifier(option2B)))
            }
            
            it("does not overwrite the option if called with a different type") {
                let option3A = Option.register(name: "option3", type: .boolean)
                let option3B = Option.register(name: "option3", type: .data)
                
                // This would happen if two SDKs tried defining the same option with different types.
                // What will happen is that the second SDK will get back `nil` when it tries reading
                // the option.
                
                expect(ObjectIdentifier(option3A)).to(equal(ObjectIdentifier(option3B)))
            }
            
            it("exposes keys to Option.named") {
                
                _ = Option.register(name: "option4", type: .string)
                
                expect(Option.named("option4")).notTo(beNil())
                expect(Option.named("option4")?.name).to(equal("option4"))
                expect(Option.named("option4")?.type).to(equal(.string))
            }
        }
        
        describe("[Option: Any].string") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: "val"]
                expect(options.string(at: .something)).to(equal("val"))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: true]
                expect(options.string(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].boolean") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: true]
                expect(options.boolean(at: .something)).to(equal(true))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: "val"]
                expect(options.boolean(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].timeInterval") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: 0.25]
                expect(options.timeInterval(at: .something)).to(equal(0.25))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: true]
                expect(options.timeInterval(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].integer") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: 1024]
                expect(options.integer(at: .something)).to(equal(1024))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: true]
                expect(options.integer(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].url") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: URL(string: "https://example.com")!]
                expect(options.url(at: .something)).to(equal(URL(string: "https://example.com")!))
            }
            
            it("transforms strings") {
                let options: [Option: Any] = [.something: "https://example.com"]
                expect(options.url(at: .something)).to(equal(URL(string: "https://example.com")!))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: true]
                expect(options.url(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].data") {
            
            it("returns the value if of the right type") {
                let options: [Option: Any] = [.something: Data(repeating: 0xff, count: 10)]
                expect(options.data(at: .something)).to(equal(Data(repeating: 0xff, count: 10)))
            }
            
            it("returns nil if of the wrong type") {
                let options: [Option: Any] = [.something: true]
                expect(options.data(at: .something)).to(beNil())
            }
        }
        
        describe("[Option: Any].object") {
            
            it("returns the value if of the right type") {
                let object = NSObject()
                let options: [Option: Any] = [.something: object]
                expect(options.object(at: .something)).to(equal(object))
            }
            
            // Other things will get converted to NSObject so there's no point testing the negative.
            // Consumers will have to cast to other types anyway.
        }
        
        describe("[Object: Any].sanitizedValue") {
            it("returns the value if matching") {
                let options: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1024,
                    .url: "https://example.com",
                    .data: Data(repeating: 0xff, count: 10),
                    .object: NSObject(),
                ]
                
                expect(options.sanitizedValue(at: .string)).notTo(beNil())
                expect(options.sanitizedValue(at: .boolean)).notTo(beNil())
                expect(options.sanitizedValue(at: .timeInterval)).notTo(beNil())
                expect(options.sanitizedValue(at: .integer)).notTo(beNil())
                expect(options.sanitizedValue(at: .url)).notTo(beNil())
                expect(options.sanitizedValue(at: .data)).notTo(beNil())
                expect(options.sanitizedValue(at: .object)).notTo(beNil())
            }
            
            it("returns the nil if not matching") {
                let options: [Option: Any] = [
                    .string: false,
                    .boolean: "false",
                    .timeInterval: false,
                    .integer: false,
                    .url: false,
                    .data: false,
                ]
                
                expect(options.sanitizedValue(at: .string)).to(beNil())
                expect(options.sanitizedValue(at: .boolean)).to(beNil())
                expect(options.sanitizedValue(at: .timeInterval)).to(beNil())
                expect(options.sanitizedValue(at: .integer)).to(beNil())
                expect(options.sanitizedValue(at: .url)).to(beNil())
                expect(options.sanitizedValue(at: .data)).to(beNil())
            }
        }
        
        describe("[Object: Any].sanitizedCopy") {
            it("does not remove matching values") {
                let options: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1024,
                    .url: "https://example.com",
                    .data: Data(repeating: 0xff, count: 10),
                    .object: NSObject(),
                ]
                
                expect(options.sanitizedCopy().count).to(equal(options.count))
            }
            
            it("removes non-matching types") {
                let options: [Option: Any] = [
                    .string: false,
                    .boolean: "false",
                    .timeInterval: false,
                    .integer: false,
                    .url: false,
                    .data: false,
                ]
                
                expect(options.sanitizedCopy()).to(beEmpty())
            }
        }
        
        describe("[Object: Any].matches") {
            it("returns true if two dictionaries match") {
                let options1: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1024,
                ]

                let options2: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1024,
                ]

                expect(options1.matches(options2)).to(beTrue())
            }
            
            it("returns false if two dictionaries differ") {
                let options1: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1025,
                ]

                let options2: [Option: Any] = [
                    .string: "",
                    .boolean: true,
                    .timeInterval: 1.0,
                    .integer: 1024,
                ]

                expect(options1.matches(options2)).to(beFalse())
            }
        }
    }
}
