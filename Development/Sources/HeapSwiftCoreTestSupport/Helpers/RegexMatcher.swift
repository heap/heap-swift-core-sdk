import Nimble
import Foundation

public func match(regex pattern: String) -> Predicate<String> {

    return Predicate { actualExpression in

        let msg = ExpectationMessage.expectedActualValueTo("match <\(pattern)>")
        if let actualValue = try actualExpression.evaluate() {
            
            let range = (actualValue as NSString).range(of: pattern, options: .regularExpression)
            
            return PredicateResult(
                bool: range.location != NSNotFound,
                message: msg
            )
        } else {
            return PredicateResult(
                status: .fail,
                message: msg
            )
        }
    }
}
