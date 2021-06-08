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
    private let intersectionTable: OXIntersectionTable
    private let transpositions: [(UInt8, UInt8)]
    
    init(diagram: GridDiagram) {
        self.init(diagram: diagram, filter: { (_, _) in true })
    }
    
    init(diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        let intersectionTable = OXIntersectionTable(diagram)
        let generators = GridComplexGeneratorProducer(diagram, intersectionTable).produce(filter: filter)
        
        self.init(diagram: diagram, generators: generators, intersectionTable: intersectionTable)
    }
    
    private init(diagram: GridDiagram, generators: GeneratorTable, intersectionTable: OXIntersectionTable) {
        self.diagram = diagram
        self.generators = generators
        self.intersectionTable = intersectionTable
        
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
            },
            intersectionTable: intersectionTable
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

    func adjacents(of x: Generator, with rectCond: (GridDiagram.Rect) -> Bool) -> [(Generator, GridDiagram.Rect)] {
        
        let gridSize = diagram.gridSize
        var seq = x.sequence
        var pts = x.points
        
        return transpositions.flatMap { (i, j) -> [(Generator, GridDiagram.Rect)] in
            let p = Point(2 * i, 2 * seq[i])
            let q = Point(2 * j, 2 * seq[j])
            
            let r1 = Rect(from: p, to: q, gridSize: gridSize)
            let r2 = Rect(from: q, to: p, gridSize: gridSize)
            
            let rs = [r1, r2].filter { r in
                rectCond(r) && !r.intersects(pts, interior: true)
            }
            if rs.isEmpty {
                return []
            }
            
            // MEMO:
            // We don't want to create arrays for each iteration,
            // so we reuse the mutable ones.
            
            func swap() {
                seq.swapAt(i, j)
                pts[i] = Point(2 * i, 2 * seq[i])
                pts[j] = Point(2 * j, 2 * seq[j])
            }
            
            swap()
            defer { swap() } // revert for next iteration
            
            let y = GridComplexGeneratorProducer.generator(
                adjacentTo: x,
                connectedBy: r1,
                intersections: intersectionInfo(for: r1),
                sequence: seq,
                points: pts
            )
            
            if contains(bidegree: y.bidegree) {
                return rs.map { r in (y, r) }
            } else {
                return []
            }
        }
    }
    
    func intersectionInfo(for r: Rect) -> OXIntersectionTable.Info {
        intersectionTable[r]
    }
}
