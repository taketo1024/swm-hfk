//
//  UInt8.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import Foundation

public extension UInt8 {
    @inlinable
    var isEven: Bool {
        self % 2 == 0
    }
    
    var factorial: Int {
        (1 ... self).reduce(1) { $0 * Int($1) }
    }
}

public extension Array {
    @inlinable
    subscript (i: UInt8) -> Element {
        get { self[Int(i)] }
        set { self[Int(i)] = newValue }
    }
    
    @inlinable
    mutating func swapAt(_ i: UInt8, _ j: UInt8) {
        swapAt(Int(i), Int(j))
    }
}
