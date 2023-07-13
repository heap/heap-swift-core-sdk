import Foundation
import Nimble

func beCloseTo(
    _ expectedValue: TimeInterval,
    after referenceDate: Date,
    within delta: TimeInterval = 1
) -> Nimble.Predicate<Date> {
    return Predicate.define { actualExpression in
        return isCloseTo(try actualExpression.evaluate()?.timeIntervalSince(referenceDate), expectedValue: expectedValue, delta: delta)
    }
}

func isCloseTo<Value: FloatingPoint>(
    _ actualValue: Value?,
    expectedValue: Value,
    delta: Value
) -> PredicateResult {
    let errorMessage = "be close to <\(stringify(expectedValue))> (within \(stringify(delta)))"
    return PredicateResult(
        bool: actualValue != nil &&
            abs(actualValue! - expectedValue) < delta,
        message: .expectedCustomValueTo(errorMessage, actual: "<\(stringify(actualValue))>")
    )
}
