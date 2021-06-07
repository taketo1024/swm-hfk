//
//  UInt8.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import Foundation

internal extension UInt8 {
    var factorial: Int {
        (1 ... self).reduce(1) { $0 * Int($1) }
    }
}

internal extension Array {
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

internal extension Array where Element == UInt8 {
    func toGridDiagramPoints() -> [GridDiagram.Point] {
        .init(enumerated().map { (i, j) in
            GridDiagram.Point(2 * UInt8(i), 2 * j)
        })
    }
}
