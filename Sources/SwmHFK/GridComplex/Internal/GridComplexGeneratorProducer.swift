//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore

internal final class GridComplexGeneratorProducer {
    typealias Generator = GridComplexGenerator
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
    
    func produce(filter: (Int, Int) -> Bool) -> GridComplexConstruction.GeneratorTable {
        let n = diagram.gridNumber
        let data = Array(0 ..< n).parallelMap { i -> [Generator] in
            self.produce(step: i, filter: filter)
        }
        
        var result: GridComplexConstruction.GeneratorTable = .empty
        for d in data {
            for x in d {
                result[[x.MaslovDegree, x.AlexanderDegree], default: []].append(x)
            }
        }
        return result
    }
    
    private func produce(step i: UInt8, filter: (Int, Int) -> Bool) -> [Generator] {
        let n = diagram.gridNumber
        
        var data: [Generator] = .empty
        data.reserveCapacity((n - 1).factorial)
        
        func append(_ x: Generator) {
            if filter(x.MaslovDegree, x.AlexanderDegree) {
                data.append(x)
            }
        }
        
        var seq = Array(0 ..< n).with{ $0.swapAt(i, n - 1) }
        var x = Generator(diagram: diagram, sequence: seq)
        var pts = x.points
        
        append(x)

        for t in trans {
            x = adjacentGenerator(
                to: x,
                transposing: t,
                sequence: &seq,
                points: &pts
            )
            
            append(x)
        }
        
        return data
    }
    
    private func adjacentGenerator(to x: Generator, transposing t: (UInt8, UInt8), sequence seq: inout [UInt8], points pts: inout [Point]) -> Generator {
        
        // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
        // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
        
        let (i, j) = t
        let r = GridDiagram.Rect(
            from: pts[i],
            to: pts[j],
            gridSize: diagram.gridSize
        )
        
        let nO = table[r].countIntersections(.O)
        let nX = table[r].countIntersections(.X)
        
        let c = (i + 1 ..< j).count { i in
            r.contains(pts[i], interior: true)
        }
        
        let m = x.MaslovDegree + 2 * (nO - c) - 1
        let a = x.AlexanderDegree + nO - nX
        
        seq.swapAt(i, j)
        
        pts[i] = Point(2 * i, 2 * seq[i])
        pts[j] = Point(2 * j, 2 * seq[j])
        
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
