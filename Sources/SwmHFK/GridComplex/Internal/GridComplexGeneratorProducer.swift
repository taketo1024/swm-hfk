//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore

public final class GridComplexGeneratorProducer {
    typealias Generator = GridComplexGenerator
    typealias GeneratorTable = GridComplexConstruction.GeneratorTable
    typealias Point = GridDiagram.Point
    typealias Rect  = GridDiagram.Rect
    
    let diagram: GridDiagram
    let trans: [(UInt8, UInt8)]
    
    init(_ diagram: GridDiagram) {
        self.diagram = diagram
        self.trans = Self.heapTranspositions(length: diagram.gridNumber - 1)
    }
    
    func produce(filter: (Int, Int) -> Bool) -> GeneratorTable {
        let n = diagram.gridNumber
        
        let data = Array(0 ..< n).parallelMap { i in
            self.produce(step: i, filter: filter)
        }
        
        // analyze size before merge.
        
        let count = data.reduce(
            into: [MultiIndex<_2>: Int].empty
        ) { (res, d) in
            for (idx, list) in d {
                res[idx, default: 0] += list.count
            }
        }
        
        let result = data.reduce(into: GeneratorTable.empty) { (res, next) in
            if res.isEmpty {
                for (idx, c) in count {
                    res[idx] = []
                    res[idx]!.reserveCapacity(c)
                }
            }
            for (idx, list) in next {
                res[idx]! += list
            }
        }
        
        return result.mapValues{ $0.sorted{ $0.code} }
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

            x = generator(
                adjacentTo: x,
                connectedBy: r,
                sequence: seq,
                points: pts
            )
            
            append(x)
        }
        
        return result
    }
    
    private func generator(adjacentTo x: Generator, connectedBy rect: Rect, sequence seq: [UInt8], points pts: [Point]) -> Generator {
        
        // See Book, p.68
        // (4.2)  M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
        // (4.4)  A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
        
        let nO = rect.countIntersections(diagram.Os)
        let nX = rect.countIntersections(diagram.Xs)
        let c =  rect.countIntersections(pts, interior: true)
        
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
            
            for i in 0 ..< k - 1 {
                let t = k.isEven ? (i, k - 1) : (0, k - 1)
                result.append(t)
                
                generate(k - 1)
            }
        }
        
        generate(n)
        
        return result
    }
}
