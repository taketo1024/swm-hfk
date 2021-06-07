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
    let table: GridDiagram.OXIntersectionTable
    let filter: (Generator) -> Bool
    let trans: [(UInt8, UInt8)]
    
    init(_ G: GridDiagram, _ intersectionTable: GridDiagram.OXIntersectionTable, _ filter: @escaping (Generator) -> Bool) {
        self.G = G
        self.table = intersectionTable
        self.filter = filter
        
        let n = UInt8(G.gridNumber)
        self.trans = Self.heapTranspositions(length: n - 1)
    }
    
    func produce() -> [Generator.Code : Generator] {
        let n = UInt8(G.gridNumber)
        
        let data = Array(0 ..< n).parallelFlatMap { i in
            self.produce(step: i)
        }
        
        return Dictionary(data)
    }
    
    private func produce(step i: UInt8) -> [(Generator.Code, Generator)] {
        let n = UInt8(G.gridNumber)
        
        var data: [(Generator.Code, Generator)] = .empty
        data.reserveCapacity((n - 1).factorial)
        
        func add(_ seq: [UInt8], _ M: Int, _ A: Int) {
            let x = Generator(
                sequence: seq,
                MaslovDegree: M,
                AlexanderDegree: A
            )
            
            if filter(x) {
                data.append( (x.code, x) )
            }
        }
        
        var seq = Array(0 ..< n)
        seq.swapAt(i, n - 1)
        
        var pts = points(seq)
        var (m, a) = (M(pts), A(pts))
        
        add(seq, m, a)
        
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
            
            add(seq, m, a)
        }
        
        return data
    }
    
    private func points(_ seq: [UInt8]) -> [Point] {
        seq.enumerated().map { (i, j) in Point(2 * UInt8(i), 2 * j) }
    }
    
    private func I(_ x: [Point], _ y: [Point]) -> Int {
        (x * y).count{ (p, q) in p < q }
    }
    
    private func J(_ x: [Point], _ y: [Point]) -> Int {
        I(x, y) + I(y, x)
    }
    
    private func M(_ ref: [Point], _ x: [Point]) -> Int {
        ( J(x, x) - 2 * J(x, ref) + J(ref, ref) ) / 2 + 1
    }
    
    private func M(_ x: [Point]) -> Int {
        M(G.Os, x)
    }
    
    private func A(_ x: [Point]) -> Int {
        ( M(G.Os, x) - M(G.Xs, x) - Int(G.gridNumber) + 1 ) / 2
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
