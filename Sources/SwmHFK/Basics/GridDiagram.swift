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
        self.init(
            name: name,
            Os: .oddPoints(from: Os),
            Xs: .oddPoints(from: Xs)
        )
    }
    
    internal init(name: String? = nil, Os: [Point], Xs: [Point]) {
        self.name = name ?? "G"
        self.Os = Os
        self.Xs = Xs
    }
    
    public var gridNumber: UInt8 {
        UInt8(Os.count)
    }
    
    public var gridSize: UInt8 {
        2 * gridNumber
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
}
