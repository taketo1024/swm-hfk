//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/08.
//

import SwmCore

extension GridDiagram {
    public struct Point: Equatable, Hashable, Comparable, CustomStringConvertible {
        public let x: UInt8
        public let y: UInt8
        
        public init(_ x: UInt8, _ y: UInt8) {
            self.x = x
            self.y = y
        }
        
        public static func < (p: Point, q: Point) -> Bool {
            p.x < q.x && p.y < q.y
        }
        
        public func shift(_ dx: Int8, _ dy: Int8) -> Point {
            Point(
                UInt8(Int8(x) + dx),
                UInt8(Int8(y) + dy)
            )
        }
        
        public var corners: [Point] {
            [shift(1, 1), shift(-1, 1), shift(-1, -1), shift(1, -1)]
        }
        
        public var description: String {
            "(\(x), \(y))"
        }
    }
}
