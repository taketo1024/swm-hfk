//
//  GridComplexData.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2020/02/06.
//

import SwmCore
import Algorithms
import Dispatch

internal struct GridComplexConstruction {
    typealias Generator = GridComplexGenerator
    typealias GeneratorTable = [MultiIndex<_2> : [Generator]]
    typealias Point = GridDiagram.Point
    typealias Rect  = GridDiagram.Rect

    let diagram: GridDiagram
    
    let generators: GeneratorTable
    private let transpositions: [(UInt8, UInt8)]
    
    init(diagram: GridDiagram) {
        self.init(diagram: diagram, filter: { (_, _) in true })
    }
    
    init(diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        let p = GridComplexGeneratorProducer(diagram)
        let generators = p.produce(filter: filter)
        
        self.init(diagram: diagram, generators: generators)
    }
    
    private init(diagram: GridDiagram, generators: GeneratorTable) {
        self.diagram = diagram
        self.generators = generators
        
        let n = diagram.gridNumber
        self.transpositions = (0 ..< n).combinations(ofCount: 2).map{ t in
            (t[0], t[1])
        }
    }
    
    var gridNumber: UInt8 {
        diagram.gridNumber
    }
    
    var numberOfGenerators: Int {
        generators.sum{ (_, set) in set.count }
    }
    
    var MaslovDegreeRange: ClosedRange<Int> {
        generators.keys.map{ $0[0] }.closureRange ?? (0 ... 0)
    }
    
    var AlexanderDegreeRange: ClosedRange<Int> {
        generators.keys.map{ $0[1] }.closureRange ?? (0 ... 0)
    }
    
    func contains(bidegree: (Int, Int)) -> Bool {
        generators.contains(key: [bidegree.0, bidegree.1])
    }
    
    func numberOfGenerators(_ i: Int, _ j: Int) -> Int {
        generators[[i, j]]?.count ?? 0
    }
    
    func generators(_ i: Int, _ j: Int) -> [Generator] {
        generators[[i, j]] ?? []
    }
    
    func generators(_ filter: (Int, Int) -> Bool) -> [Generator] {
        let indices = generators.keys.filter{ idx in filter(idx[0], idx[1]) }.sorted()
        let count = indices.sum{ idx in generators[idx]!.count }
            
        return indices.reduce(into: []) { (res, idx) in
            if res.isEmpty {
                res.reserveCapacity(count)
            }
            res.append(contentsOf: generators[idx]!)
        }
    }
    
    func filter(_ predicate: (Int, Int) -> Bool) -> Self {
        .init(
            diagram: diagram,
            generators: generators.filter { (index, _) in
                predicate(index[0], index[1])
            }
        )
    }
    
    func rectangles(from x: Generator, to y: Generator) -> [Rect] {
        let (ps, qs) = (x.points, y.points)
        let diff = Set(ps).subtracting(qs)
        
        guard diff.count == 2 else {
            return []
        }
        
        let pq = diff.toArray()
        let (p, q) = (pq[0], pq[1])
        
        return [Rect(from: p, to: q, gridSize: diagram.gridSize),
                Rect(from: q, to: p, gridSize: diagram.gridSize)]
    }
    
    func emptyRectangles(from x: Generator, to y: Generator) -> [Rect] {
        // Note: Int(r) ∩ x = Int(r) ∩ y .
        rectangles(from: x, to: y).filter{ r in
            !r.intersects(x.points, interior: true)
        }
    }

    func adjacents(of x: Generator, with rectCond: (Rect) -> Bool) -> [(Generator, Rect)] {
        
        let gridSize = diagram.gridSize
        let pts = x.points
        var seq = x.sequence
        
        return transpositions.flatMap { (i, j) -> [(Generator, Rect)] in
            let p = Point(2 * i, 2 * seq[i])
            let q = Point(2 * j, 2 * seq[j])
            
            let r1 = Rect(from: p, to: q, gridSize: gridSize)
            let r2 = Rect(from: q, to: p, gridSize: gridSize)
            
            let rs = [r1, r2].filter { r in
                rectCond(r) && !r.intersects(pts, interior: true)
            }
            
            return rs.compactMap { r -> (Generator, Rect)? in
                let nO = r.countIntersections(diagram.Os)
                let nX = r.countIntersections(diagram.Xs)

                let code = code(&seq, transposing: (i, j))
                let m = x.MaslovDegree + 2 * nO - 1
                let a = x.AlexanderDegree + nO - nX

                if let y = find(code, m, a) {
                    return (y, r)
                } else {
                    return nil
                }
            }
        }
    }
    
    // MEMO:
    // We don't want to create arrays for each iteration,
    // so we reuse the mutable ones.
    
    private func code(_ seq: inout [UInt8], transposing t: (UInt8, UInt8)) -> Int {
        let (i, j) = t
        
        seq.swapAt(i, j)
        defer{ seq.swapAt(i, j)}
        
        return GridComplexGenerator.encode(seq)
    }
    
    private func find(_ code: GridComplexGenerator.Code, _ i: Int, _ j: Int) -> GridComplexGenerator? {
        generators[[i, j]]?.binarySearch(elementWithId: code, by: { $0.code })
    }
}
