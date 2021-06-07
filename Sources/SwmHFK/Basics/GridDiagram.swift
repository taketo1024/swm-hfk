//
//  GridDiagram.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2019/07/01.
//

import Foundation
import SwmCore
import SwmHomology
import Algorithms

public struct GridDiagram {
    enum OX {
        case O, X
    }

    // Memo:  Os and Xs are placed on  odd points,
    //       generators are placed on even points.
    public let name: String
    public let Os: [Point]
    public let Xs: [Point]
    
    public static func load(_ name: String) -> GridDiagram? {
        #if os(macOS) || os(Linux)
        typealias GridCode = [String : [UInt8]]
        if
            let url = Bundle.module.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let code = try? JSONDecoder().decode(GridCode.self, from: data),
            let Os = code["O"],
            let Xs = code["X"]
        {
            return GridDiagram(name: name, Os: Os, Xs: Xs)
        }
        #endif
        return nil
    }
    
    public init(name: String? = nil, arcPresentation code: [UInt8]) {
        assert(code.count.isEven)
        
        let (Os, Xs) = code.chunks(ofCount: 2).enumerated().reduce(
            into: ([Point].empty, [Point].empty)
        ) { (res, element) in
            let (i, OX) = element
            let s = OX.startIndex
            let x_O = 2 * OX[s] - 1
            let x_X = 2 * OX[s + 1] - 1
            let y = 2 * UInt8(i) + 1 // indexed from 0
            res.0.append(Point(x_O, y))
            res.1.append(Point(x_X, y))
        }
        
        assert(Os.map{ p in p.x }.isUnique)
        assert(Os.map{ p in p.y }.isUnique)
        assert(Xs.map{ p in p.x }.isUnique)
        assert(Xs.map{ p in p.y }.isUnique)
        
        let n = UInt8(code.count) / 2
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        
        self.init(name: name, Os: Os.sorted(by: { p in p.x }), Xs: Xs.sorted(by: { p in p.x }))
    }
    
    public init(name: String? = nil, arcPresentation code: UInt8...) {
        self.init(name: name, arcPresentation: code)
    }
    
    public init(name: String? = nil, Os: [UInt8], Xs: [UInt8]) {
        func points(_ seq: [UInt8]) -> [Point] {
            seq.enumerated().map { (i, j) in
                let x = 2 * UInt8(i) + 1
                let y = 2 * UInt8(j) + 1
                return Point(x, y)
            }
        }
        self.init(name: name, Os: points(Os), Xs: points(Xs))
    }
    
    internal init(name: String? = nil, Os: [Point], Xs: [Point]) {
        self.name = name ?? "G"
        self.Os = Os
        self.Xs = Xs
    }
    
    public var gridNumber: Int {
        Os.count
    }
    
    public var gridSize: UInt8 {
        2 * UInt8(gridNumber)
    }
    
    public var rotate90: GridDiagram {
        let n = gridSize
        let t = { (p: Point) -> Point in
            Point(n - p.y, p.x)
        }
        return GridDiagram(
            name: name + "m",
            Os: Os.map(t).sorted(by: { p in p.x }),
            Xs: Xs.map(t).sorted(by: { p in p.x })
        )
    }
    
    public var diagramString: String {
        let OXs = Os.map{ p in (p, "O") } + Xs.map{ p in (p, "X") }
        let elems = OXs.map { (p, symbol) in
            ((Int(p.x) - 1)/2, (Int(p.y) - 1)/2, symbol)
        }
        return Format.table(elements: elems)
    }
    
    public func printDiagram() {
        print(diagramString)
    }
    
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

        public func intersects(_ points: [Point], interior: Bool = false) -> Bool {
            points.contains{ p in self.contains(p, interior: interior) }
        }
        
        public var description: String {
            "[point: \(origin), size: \(size)]"
        }
    }
}
