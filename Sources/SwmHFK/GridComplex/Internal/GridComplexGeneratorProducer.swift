//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore

internal final class GridComplexGeneratorProducer {
    typealias Generator = GridComplexGenerator
    typealias GeneratorTable = GridComplexConstruction.GeneratorTable
    typealias Point = GridDiagram.Point
    typealias Rect  = GridDiagram.Rect
    
    let diagram: GridDiagram
    let table: GridComplexConstruction.OXIntersectionTable
    let trans: [(UInt8, UInt8)]
    
    init(_ diagram: GridDiagram, _ intersectionTable: GridComplexConstruction.OXIntersectionTable) {
        self.diagram = diagram
        self.table = intersectionTable
        self.trans = Self.heapTranspositions(length: diagram.gridNumber - 1)
    }
    
    func produce(filter: (Int, Int) -> Bool) -> GeneratorTable {
        let n = diagram.gridNumber
        
        return Array(0 ..< n).parallelMap { i in
            self.produce(step: i, filter: filter)
        }.reduce(into: .empty) { (res, next) in
            res.merge(next, uniquingKeysWith: +)
        }
    }
    
    private func produce(step i: UInt8, filter: (Int, Int) -> Bool) -> GeneratorTable {
        let n = diagram.gridNumber
        
        var result: GeneratorTable = .empty
        func append(_ x: Generator) {
            if filter(x.MaslovDegree, x.AlexanderDegree) {
                let idx = MultiIndex(x.bidegree)
                result[idx, default: []].append(x)
            }
        }
        
        var seq = Array(0 ..< n).with{ $0.swapAt(i, n - 1) }
        var x = Generator(diagram: diagram, sequence: seq)
        var pts = x.points
        
        append(x)

        for (i, j) in trans {
            let r = GridDiagram.Rect(
                from: pts[i],
                to: pts[j],
                gridSize: diagram.gridSize
            )
            
            seq.swapAt(i, j)
            pts[i] = Point(2 * i, 2 * seq[i])
            pts[j] = Point(2 * j, 2 * seq[j])

            x = Self.generator(
                adjacentTo: x,
                connectedBy: r,
                intersections: table[r],
                sequence: seq,
                points: pts
            )
            
            append(x)
        }
        
        return result
    }
    
    internal static func generator(adjacentTo x: Generator, connectedBy rect: Rect, intersections: GridComplexConstruction.OXIntersectionTable.Info, sequence seq: [UInt8], points pts: [Point]) -> Generator {
        
        // See Book, p.68
        // (4.2)  M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
        // (4.4)  A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
        
        let nO = intersections.countIntersections(.O)
        let nX = intersections.countIntersections(.X)
        
        let (i, j) = (rect.origin.x/2, rect.destination.x/2)
        let c = (i + 1 ..< j).count { k in
            rect.contains(pts[k], interior: true)
        }
        
        let m = x.MaslovDegree + 2 * (nO - c) - 1
        let a = x.AlexanderDegree + nO - nX
        
        return Generator(
            sequence: seq,
            MaslovDegree: m,
            AlexanderDegree: a
        )
    }
    
    // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
    private static func heapTranspositions(length n: UInt8) -> [(UInt8, UInt8)] {
        var result: [(UInt8, UInt8)] = []
        result.reserveCapacity(n.factorial)
        
        func generate(_ k: UInt8) {
            if k <= 1 {
                return
            }
            
            generate(k - 1)
            
            for l in 0 ..< k - 1 {
                let (i, j) = (k % 2 == 0) ? (l, k - 1) : (0, k - 1)
                result.append( (i, j) )
                
                generate(k - 1)
            }
        }
        
        generate(n)
        
        return result
    }
}
