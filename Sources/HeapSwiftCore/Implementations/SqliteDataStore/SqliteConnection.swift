import SQLite3
import Foundation

struct SqliteError: Error, Equatable, Hashable {
    let code: Int32
}

fileprivate extension Int32 {
    
    /// Throws an error if a value is not a successful Sqlite return code.
    func assertSuccess() throws {
        switch self {
        case SQLITE_OK, SQLITE_ROW, SQLITE_DONE:
            return
        default:
            throw SqliteError(code: self)
        }
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
    
    func connect() throws {
        guard ppDb == nil else { return }
        try sqlite3_open(databaseUrl.path, &ppDb).assertSuccess()
    }
    
    /// Creates
    /// - Parameters:
    ///   - query: A SQL query.
    ///   - parameters: A list of indexed parameters to apply, of known convertable types.
    ///   - rowCallback: A callback to execute after each row is read (if any).  This is used for extracting row data.
    /// - Throws: A `SqliteError` if an error is encountered on any step of the process.
    func perform(query: String, parameters: [Sqlite3Parameter] = [], rowCallback: (_ row: Row) throws -> Void = { _ in }) throws {
        guard let ppDb = ppDb else {
            throw SqliteError(code: SQLITE_ERROR)
        }
        
        let statement = try Statement(query: query, db: ppDb)
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
        private var pointer: OpaquePointer?
        
        fileprivate init(pointer: OpaquePointer?) {
            self.pointer = pointer
        }
        
        fileprivate convenience init(query: String, db: OpaquePointer) throws {
            var pointer: OpaquePointer?
            try sqlite3_prepare_v2(db, query, -1, &pointer, nil).assertSuccess()
            self.init(pointer: pointer)
        }
        
        /// Binds parameters to the query.
        func bindIndexedParameters(_ parameters: [Sqlite3Parameter]) throws {
            for (parameter, index) in zip(parameters, 1...) {
                try parameter.bind(at: index, statementPointer: pointer)
            }
        }
        
        /// Performs a step of the query.
        /// - Returns: True if the execution returned a row.
        private func step() throws -> Bool {
            guard let pointer = pointer else {
                throw SqliteError(code: SQLITE_ERROR)
            }
            
            let result = sqlite3_step(pointer)
            try result.assertSuccess()
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
    func bind(at index: Int, statementPointer: OpaquePointer?) throws
}

extension Int: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        try sqlite3_bind_int64(statementPointer, Int32(index), Int64(self)).assertSuccess()
    }
}

extension Bool: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        try (self ? 1 : 0).bind(at: index, statementPointer: statementPointer)
    }
}

extension String: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        try sqlite3_bind_text(statementPointer, Int32(index), self, -1, SQLITE_TRANSIENT).assertSuccess()
    }
}

extension Data: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        try self.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            try sqlite3_bind_blob(statementPointer, Int32(index), pointer.baseAddress, Int32(self.count), SQLITE_TRANSIENT).assertSuccess()
        }
    }
}

/// This rounds to the nearest second, which is close enough for us.
extension Date: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        try Int(timeIntervalSinceReferenceDate).bind(at: index, statementPointer: statementPointer)
    }
}

extension Optional: Sqlite3Parameter where Wrapped: Sqlite3Parameter {
    func bind(at index: Int, statementPointer: OpaquePointer?) throws {
        if let value = self {
            try value.bind(at: index, statementPointer: statementPointer)
        } else {
            try sqlite3_bind_null(statementPointer, Int32(index)).assertSuccess()
        }
    }
}
