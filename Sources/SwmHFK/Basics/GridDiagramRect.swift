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
        
        public func contains(_ p: Point, interior: Bool = false) -> Bool {
            func inRange(_ p: UInt8, _ a: UInt8, _ b: UInt8) -> Bool {
                if interior {
                    return (a < p && p < b)
                        || (a < p + gridSize && p + gridSize < b)
                } else {
                    return (a <= p && p <= b)
                        || (a <= p + gridSize && p + gridSize <= b)
                }
            }
            
            return inRange(p.x, origin.x, origin.x + size.x)
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
        
        internal static func allRects(forGridSize gridSize: UInt8) -> [Self] {
            let n = gridSize / 2
            return ((0 ..< n) * (0 ..< n)).flatMap { (x, y) -> [Self] in
                ((0 ..< n) * (0 ..< n)).map { (w, h) -> Self in
                    Rect(
                        origin: Point(2 * x, 2 * y),
                        size: Point(2 * w, 2 * h),
                        gridSize: gridSize
                    )
                }
            }
        }
    }
}
