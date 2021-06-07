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
    
    let G: GridDiagram
    let table: GridComplexConstruction.OXIntersectionTable
    let trans: [(UInt8, UInt8)]
    
    init(_ G: GridDiagram, _ intersectionTable: GridComplexConstruction.OXIntersectionTable) {
        self.G = G
        self.table = intersectionTable
        self.trans = Self.heapTranspositions(length: G.gridNumber - 1)
    }
    
    func produce(filter: (Int, Int) -> Bool) -> GridComplexConstruction.GeneratorTable {
        let n = G.gridNumber
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
        let n = G.gridNumber
        
        var data: [Generator] = .empty
        data.reserveCapacity((n - 1).factorial)
        
        func append(_ seq: [UInt8], _ M: Int, _ A: Int) {
            if filter(M, A) {
                let x = Generator(
                    sequence: seq,
                    MaslovDegree: M,
                    AlexanderDegree: A
                )
                data.append(x)
            }
        }
        
        var seq = Array(0 ..< n)
        seq.swapAt(i, n - 1)
        
        var pts = seq.toGridDiagramPoints()
        var m = G.MaslovDegree(for: pts)
        var a = G.AlexanderDegree(for: pts)
        
        append(seq, m, a)
        
        for (i, j) in trans {
            // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
            // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
            
            let r = GridDiagram.Rect(from: pts[i], to: pts[j], gridSize: G.gridSize)
            let nO = table[r].countIntersections(.O)
            let nX = table[r].countIntersections(.X)
            
            let c = (i + 1 ..< j).count { i in
                r.contains(pts[i], interior: true)
            }
            
            let dm = 2 * (nO - c) - 1
            let da = nO - nX
            
            seq.swapAt(i, j)
            
            pts[i] = Point(2 * i, 2 * seq[i])
            pts[j] = Point(2 * j, 2 * seq[j])
            
            m += dm
            a += da
            
            append(seq, m, a)
        }
        
        return data
    }
    
    private func points(_ seq: [UInt8]) -> [Point] {
        seq.enumerated().map { (i, j) in Point(2 * UInt8(i), 2 * j) }
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
