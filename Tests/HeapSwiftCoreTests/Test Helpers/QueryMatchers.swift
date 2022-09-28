import Nimble
import Foundation
@testable import HeapSwiftCore

public func returnNoRows(in dataStore: SqliteDataStore) -> Predicate<String> {

    return Predicate { actualExpression in

        let msg = ExpectationMessage.expectedActualValueTo("have no rows")
        if let actualValue = try actualExpression.evaluate() {
            
            var rowCount = 0
            
            dataStore.performOnSqliteQueue(waitUntilFinished: true) { connection in
                try connection.perform(query: actualValue) { row in
                    rowCount += 1
                }
            }
            
            return PredicateResult(
                bool: rowCount == 0,
                message: msg.appended(message: "actual row count \(rowCount)")
            )
        } else {
            return PredicateResult(
                status: .fail,
                message: msg.appendedBeNilHint()
            )
        }
    }
}
