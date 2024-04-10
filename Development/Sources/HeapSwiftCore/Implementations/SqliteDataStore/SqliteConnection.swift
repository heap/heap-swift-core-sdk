import SQLite3
import Foundation

struct SqliteError: Error, Equatable, Hashable, CustomStringConvertible {
    let code: Int32
    let message: String
    let file: String
    let line: UInt
    
    var description: String {
        "Sqlite command at \(file):\(line) failed with error \(code) and the following message: \(message)"
    }
}

fileprivate extension Int32 {
    
    /// Throws an error if a value is not a successful Sqlite return code.
    func assertSuccess(message: @autoclosure () -> String, file: String, line: UInt) throws {
        switch self {
        case SQLITE_OK, SQLITE_ROW, SQLITE_DONE:
            return
        default:
            throw SqliteError(code: self, message: message(), file: file, line: line)
        }
    }
    
    func assertSuccess(message: @autoclosure () -> String, in statement: SqliteConnection.Statement) throws {
        try assertSuccess(message: "\(message()) in \(statement.query)", file: statement.file, line: statement.line)
    }
}

/// A lightweight wrapper around Sqlite that bridges common types.
final class SqliteConnection {
    
    let databaseUrl: URL
    
    /// A pointer to the database connection.
    private var ppDb: OpaquePointer?
    
    init(at url: URL) {
        databaseUrl = url
    }
    
    func connect(file: String = #fileID, line: UInt = #line) throws {
        guard ppDb == nil else { return }
        try sqlite3_open(databaseUrl.path, &ppDb).assertSuccess(message: "Failed to open database", file: file, line: line)
    }
    
    /// Creates
    /// - Parameters:
    ///   - query: A SQL query.
    ///   - parameters: A list of indexed parameters to apply, of known convertable types.
    ///   - rowCallback: A callback to execute after each row is read (if any).  This is used for extracting row data.
    /// - Throws: A `SqliteError` if an error is encountered on any step of the process.
    func perform(query: String, parameters: [Sqlite3Parameter] = [], file: String = #fileID, line: UInt = #line, rowCallback: (_ row: Row) throws -> Void = { _ in }) throws {
        guard let ppDb = ppDb else {
            throw SqliteError(code: SQLITE_ERROR, message: "Database pointer is nil", file: file, line: line)
        }
        
        let statement = try Statement(query: query, db: ppDb, file: file, line: line)
        try statement.bindIndexedParameters(parameters)
        defer { statement.finalize() }
        try statement.stepUntilDone(rowCallback)
    }
    
    /// Closes the database connection.
    func close() {
        sqlite3_close(ppDb) // Accepts nil per https://www.sqlite.org/c3ref/close.html
        ppDb = nil
    }
    
    deinit {
        close()
    }
    
    /// A wrapper around a prepared query.
    final class Statement {
        private(set) var pointer: OpaquePointer?
        let query: String
        let file: String
        let line: UInt
        
        fileprivate init(pointer: OpaquePointer?, query: String, file: String = #fileID, line: UInt = #line) {
            self.pointer = pointer
            self.query = query
            self.file = file
            self.line = line
        }
        
        fileprivate convenience init(query: String, db: OpaquePointer, file: String = #fileID, line: UInt = #line) throws {
            var pointer: OpaquePointer?
            try sqlite3_prepare_v2(db, query, -1, &pointer, nil).assertSuccess(message: "Failed to prepare query: \(query)", file: file, line: line)
            self.init(pointer: pointer, query: query)
        }
        
        /// Binds parameters to the query.
        func bindIndexedParameters(_ parameters: [Sqlite3Parameter]) throws {
            for (parameter, index) in zip(parameters, 1...) {
                try parameter.bind(at: index, statement: self)
            }
        }
        
        /// Performs a step of the query.
        /// - Returns: True if the execution returned a row.
        private func step() throws -> Bool {
            guard let pointer = pointer else {
                throw SqliteError(code: SQLITE_ERROR, message: "Statement pointer is nil for query: \(query)", file: file, line: line)
            }
            
            let result = sqlite3_step(pointer)
            try result.assertSuccess(message: "Step failed for query: \(query)", file: file, line: line)
            if result == SQLITE_DONE {
                finalize()
            }
            
            
            return result == SQLITE_ROW
        }
        
        /// Repeatedly steps through the query, returning `rowCallback` for each row until the
        /// query has completed.
        ///
        /// After executing this method, the object should be discarded.
        func stepUntilDone(_ rowCallback: (_ row: Row) throws -> Void) throws {
            while try step() {
                try rowCallback(Row(pointer: pointer))
            }
        }
        
        /// Finalizes the query pointer.
        ///
        /// After executing this method, the object should be discarded.
        func finalize() {
            sqlite3_finalize(pointer) // Accepts nil per https://www.sqlite.org/c3ref/finalize.html
            pointer = nil
        }
        
        deinit {
            finalize()
        }
    }

    /// A representation of the current row in the table.
    ///
    /// This object is identical for each row in a query and just limits methods that can be called
    /// while viewing a row.
    struct Row {
        
        private var pointer: OpaquePointer?
        
        fileprivate init(pointer: OpaquePointer?) {
            self.pointer = pointer
        }
        
        func int(at column: Int) -> Int {
            Int(sqlite3_column_int64(pointer, Int32(column)))
        }
        
        func bool(at column: Int) -> Bool {
            int(at: column) != 0
        }
        
        func string(at column: Int) -> String? {
            guard let cString = sqlite3_column_text(pointer, Int32(column)) else { return nil }
            return String(cString: cString)
        }
        
        func data(at column: Int) -> Data? {
            guard let baseAddress = sqlite3_column_blob(pointer, Int32(column)) else {
                return nil
            }
            
            let count = Int(sqlite3_column_bytes(pointer, Int32(column)))
            return Data(bytes: baseAddress, count: count)
        }
        
        func date(at column: Int) -> Date? {
            return Date(timeIntervalSinceReferenceDate: TimeInterval(int(at: column)))
        }
    }
}

// Solution from Sqlite.swift
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A protocol for binding Swift data types to Sqlite parameters.
protocol Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws
}

extension Int: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        try sqlite3_bind_int64(statement.pointer, Int32(index), Int64(self)).assertSuccess(message: "Failed to bind integer \"\(self)\" at index \(index)", in: statement)
    }
}

extension Bool: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        try (self ? 1 : 0).bind(at: index, statement: statement)
    }
}

extension String: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        try sqlite3_bind_text(statement.pointer, Int32(index), self, -1, SQLITE_TRANSIENT).assertSuccess(message: "Failed to bind text \"\(self)\" at index \(index)", in: statement)
    }
}

extension Data: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        try self.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            try sqlite3_bind_blob(statement.pointer, Int32(index), pointer.baseAddress, Int32(self.count), SQLITE_TRANSIENT).assertSuccess(message: "Failed to bind data of length \(count) at index \(index)", in: statement)
        }
    }
}

/// This rounds to the nearest second, which is close enough for us.
extension Date: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        try Int(timeIntervalSinceReferenceDate).bind(at: index, statement: statement)
    }
}

extension Optional: Sqlite3Parameter where Wrapped: Sqlite3Parameter {
    func bind(at index: Int, statement: SqliteConnection.Statement) throws {
        if let value = self {
            try value.bind(at: index, statement: statement)
        } else {
            try sqlite3_bind_null(statement.pointer, Int32(index)).assertSuccess(message: "Failed to bind null at index \(index)", in: statement)
        }
    }
}
