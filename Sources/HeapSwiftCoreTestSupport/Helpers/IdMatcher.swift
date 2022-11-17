import Foundation
import Nimble

func beAValidId() -> Predicate<String> {
    .init { actualExpression in
        
        let msg = ExpectationMessage.expectedActualValueTo("be a 53-bit number")
        
        guard let actualValue = try actualExpression.evaluate() else {
            return .init(
                status: .fail,
                message: msg.appendedBeNilHint()
            )
        }
        
        guard let value = Int64(actualValue) else {
            return .init(
                status: .doesNotMatch,
                message: msg.appended(message: " (non-integer string detected)")
            )
        }
        
        let bitLength = 64 - value.leadingZeroBitCount

        guard bitLength <= 53 else {
            return .init(
                status: .doesNotMatch,
                message: msg.appended(message: " (encountered a \(bitLength)-bit number)")
            )
        }
        
        return .init(status: .matches, message: msg)
    }
}

func allBeUnique<T: Sequence>() -> Predicate<T> where T.Element: Hashable {
    .init { actualExpression in
        
        let msg = ExpectationMessage.expectedActualValueTo("all be unique")
        
        guard let actualValue = try actualExpression.evaluate() else {
            return .init(
                status: .fail,
                message: msg.appendedBeNilHint()
            )
        }
        
        var found: Set<T.Element> = []
        
        for element in actualValue {
            let (inserted, _) = found.insert(element)

            guard inserted else {
                return .init(
                    status: .fail,
                    message: msg.appended(message: " (\(element) appearing multiple times)")
                )
            }
        }

        return .init(status: .matches, message: msg)
    }
}

func allBeUniqueAndValidIds<T: Sequence>() -> Predicate<T> where T.Element == String {
    satisfyAllOf(allBeUnique(), allPass(beAValidId()))
}
