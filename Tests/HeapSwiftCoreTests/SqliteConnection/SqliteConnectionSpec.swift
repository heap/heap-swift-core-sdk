import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class SqliteConnectionSpec: HeapSpec {

    override func spec() {
        
        var url: URL! = nil
        var connection: SqliteConnection!
        
        beforeEach {
            url = FileManager.default.temporaryDirectory.appendingPathComponent("heap-db-\(UUID().uuidString)")
            connection = SqliteConnection(at: url)
        }
        
        func recreateConnection() {
            connection.close()
            connection = SqliteConnection(at: url)
        }
        
        afterEach {
            connection.close()
            try? FileManager.default.removeItem(at: url)
        }
        
        describe("SqliteConnection.connect") {
            
            it("does not throw when the file is not there") {
                try connection.connect()
            }
            
            it("does not throw when the file is there") {
                try connection.connect()
                try connection.perform(query: """
Create Table TestTable (
  Id Int Primary Key Not Null,
  Name Text
);
""")

                expect(FileManager.default.fileExists(atPath: url.path)).to(beTrue(), description: "PRECONDITION: File was not created")
                
                recreateConnection()
                try connection.connect()
            }
        }
        
        describe("SqliteConnection.perform") {
            
            beforeEach {
                try? connection.connect()
                
                try? connection.perform(query: """
Create Table TestTable (
  Id Integer Primary Key AutoIncrement Not Null,
  Name Text,
  Number Integer,
  TrueFalse Integer,
  Data Blob
);
""")

            }
            
            it("can edit and query tables") {
                
                // Fun fact! Sqlite only executes the first statement in a query.
                try connection.perform(query: "Insert Into TestTable (Name) Values ('My Value 1');")
                try connection.perform(query: "Insert Into TestTable (Name) Values ('My Value 2');")
                
                var count = 0
                try connection.perform(query: """
Select Id, Name
From TestTable
Order By Id Asc;
""", rowCallback: { row in
                    count += 1
                })
                
                expect(count).to(equal(2), description: "Two rows should have been inserted.")
            }
            
            it("can pass in parameters") {
                try connection.perform(query: """
Insert Into TestTable
(Name, Number, TrueFalse, Data)
Values (?, ?, ?, ?);
""", parameters: [ "hello", 99, true, Data(repeating: 20, count: 50) ])
            }
            
            it("can read columns") {
                
                for i in 0..<10 {
                    try connection.perform(query: """
    Insert Into TestTable
    (Name, Number, TrueFalse, Data)
    Values (?, ?, ?, ?);
    """, parameters: [ "hello \(i)", i, i % 2 == 0, Data(repeating: UInt8(i), count: 50) ])
                }
                
                try connection.perform(query: """
Select Name, Number, TrueFalse, Data
From TestTable
Order By Id Asc;
""", rowCallback: { row in
                    
                    let i = row.int(at: 1)
                    expect(row.string(at: 0)).to(equal("hello \(i)"))
                    expect(row.bool(at: 2)).to(equal(i % 2 == 0))
                    expect(row.data(at: 3)).to(equal(Data(repeating: UInt8(i), count: 50)))
                })
            }
        }
    }
}
