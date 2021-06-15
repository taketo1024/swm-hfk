//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/08.
//

import SwmCore

extension GridDiagram {
    public struct Rect: Hashable, CustomStringConvertible {
        public let origin: Point // Left-Bottom point
        public let size: Point
        public let gridSize: UInt8
        
        @inlinable
        public init(origin: Point, size: Point, gridSize: UInt8) {
            self.origin = origin
            self.size  = size
            self.gridSize = gridSize
        }
        
        public init(from p: Point, to q: Point, gridSize: UInt8) {
            let l = gridSize
            let size = Point((l + q.x - p.x) % l, (l + q.y - p.y) % l)
            self.init(origin: p, size: size, gridSize: gridSize)
        }
        
        public var destination: Point {
            Point(origin.x + size.x % gridSize, origin.y + size.y % gridSize)
        }
        
        @usableFromInline
        internal func inRange(_ p: UInt8, _ a: UInt8, _ b: UInt8) -> Bool {
            (a <= p) ? (p <= b) : (p + gridSize <= b)
        }
        
        @usableFromInline
        internal func inRangeInterior(_ p: UInt8, _ a: UInt8, _ b: UInt8) -> Bool {
            (a < p) ? (p < b) : (p + gridSize < b)
        }
        
        @inlinable
        public func contains(_ p: Point, interior: Bool = false) -> Bool {
            interior
                ? inRangeInterior(p.x, origin.x, origin.x + size.x)
                && inRangeInterior(p.y, origin.y, origin.y + size.y)
                : inRange(p.x, origin.x, origin.x + size.x)
                && inRange(p.y, origin.y, origin.y + size.y)
        }

        @inlinable
        public func intersects(_ points: [Point], interior: Bool = false) -> Bool {
            points.contains{ p in self.contains(p, interior: interior) }
        }
        
        @inlinable
        public func countIntersections(_ points: [Point], interior: Bool = false) -> Int {
            points.count{ p in self.contains(p, interior: interior) }
        }
        
        public var description: String {
            "[point: \(origin), size: \(size)]"
        }
    }
}

internal extension GridDiagram {
    var allRects: [Rect] {
        let n = gridNumber
        return ((0 ..< n) * (0 ..< n)).flatMap { (x, y) -> [Rect] in
            ((0 ..< n) * (0 ..< n)).map { (w, h) -> Rect in
                Rect(
                    origin: Point(2 * x, 2 * y),
                    size: Point(2 * w, 2 * h),
                    gridSize: gridSize
                )
            }
        }
    }
}
