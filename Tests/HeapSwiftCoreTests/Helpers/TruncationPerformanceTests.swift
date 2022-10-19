import XCTest
@testable import HeapSwiftCore

/// Tests to measure the performance of String.truncated(toUtf16Count:).
final class TruncationPerformanceTests: XCTestCase {
    
    func testShortString() throws {
        
        let sourceString = String(repeating: "あ", count: 1023)
        
        self.measure {
            for _ in 1...50 {
                _ = sourceString.truncated()
            }
        }
    }

    func testSimpleString() throws {
        
        let sourceString = String(repeating: "あ", count: 2000)
        
        self.measure {
            for _ in 1...50 {
                _ = sourceString.truncated()
            }
        }
    }

    func testComposedEmoji() throws {
        
        let sourceString = String(repeating: "👨‍👨‍👧‍👧", count: 2000)
        
        self.measure {
            for _ in 1...50 {
                _ = sourceString.truncated()
            }
        }
    }
    
    func testDiacritcs() throws {
        
        let sourceString = String(repeating: "A̶̧̨̨̡̡̼̯̯͖̖͔̗̞̣̯̲̰̞̹͎̝̱̪̬̹̰͔̹̫̙̤̞̯͓̖̣͉̻̣̙͉̰̦͔͚̔̍̍̃͌͆̎̊̈̇̽̿̕͜͠͝ͅ", count: 2000)
        
        self.measure {
            for _ in 1...50 {
                _ = sourceString.truncated()
            }
        }
    }
}
