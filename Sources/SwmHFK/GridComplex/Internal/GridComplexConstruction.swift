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
    
    @available(*, deprecated)
    func generator(forSequence seq: [UInt8]) -> Generator? {
        let x = Generator(diagram: diagram, sequence: seq)
        return generators.contains(key: [x.MaslovDegree, x.AlexanderDegree]) ? x : nil
    }
    
    func generators(ofMaslovDegree d: Int) -> [Generator] {
        generators.filter{ (idx, _) in idx[0] == d }.reduce(
            into: []
        ) {
            $0.append(contentsOf: $1.value )
        }
    }
    
    func filter(_ predicate: (Int, Int) -> Bool) -> Self {
        .init(
            diagram: diagram,
            generators: generators.filter{ (index, _) in predicate(index[0], index[1]) },
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
        let seq = x.sequence
        let pts = x.points
        
        return transpositions.flatMap { (i, j) -> [(Generator, GridDiagram.Rect)] in
            let p = Point(2 * i, 2 * seq[i])
            let q = Point(2 * j, 2 * seq[j])
            
            let rs = [
                Rect(from: p, to: q, gridSize: gridSize),
                Rect(from: q, to: p, gridSize: gridSize)
            ].filter { r in
                rectCond(r) && !r.intersects(pts, interior: true)
            }
            
            if rs.isEmpty {
                return []
            }
            
            let ySeq = seq.with{ $0.swapAt(i, j) }
            guard let y = generator(forSequence: ySeq) else {
                return []
            }
            
            return rs.map { r in (y, r) }
        }
    }
    
    func intersectionInfo(for r: Rect) -> OXIntersectionTable.Info {
        intersectionTable[r]
    }
}
