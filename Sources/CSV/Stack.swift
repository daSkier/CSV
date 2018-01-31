import Bits
import Foundation

internal struct Stack: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Byte
    
    var store: Data
    
    init(arrayLiteral elements: Byte...) {
        self.store = Data(elements)
    }
    
    mutating func push(_ byte: Byte) {
        self.store.append(byte)
    }
    
    mutating func release() -> String {
        defer { store.removeAll() }
        return String(data: store, encoding: .utf8) ?? ""
    }
}

func ==(lhs: Stack, rhs: [Byte]) -> Bool {
    return lhs.store == Data(rhs)
}
