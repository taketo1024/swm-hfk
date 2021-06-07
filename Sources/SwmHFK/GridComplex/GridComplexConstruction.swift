//
//  GridComplexData.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2020/02/06.
//

import SwmCore
import Algorithms
import Dispatch

public typealias GeneratorSet = GridComplexConstruction

public struct GridComplexConstruction {
    public typealias Generator = GridComplexGenerator
    public typealias Point = GridDiagram.Point
    public typealias Rect  = GridDiagram.Rect

    public let diagram: GridDiagram
    
    internal let generators: [MultiIndex<_2> : Set<Generator>]
    internal let intersectionTable: OXIntersectionTable
    private let transpositions: [(UInt8, UInt8)]
    
    public init(diagram: GridDiagram) {
        self.init(diagram: diagram, filter: { _ in true })
    }
    
    public init(diagram: GridDiagram, filter: @escaping (Generator) -> Bool) {
        let intersectionTable = OXIntersectionTable(diagram)
        let generators = GridComplexGeneratorProducer(diagram, intersectionTable).produce(filter: filter)
        
        self.init(diagram: diagram, generators: generators, intersectionTable: intersectionTable)
    }
    
    private init(diagram: GridDiagram, generators: [MultiIndex<_2> : Set<Generator>], intersectionTable: OXIntersectionTable) {
        self.diagram = diagram
        self.generators = generators
        self.intersectionTable = intersectionTable
        
        let n = diagram.gridNumber
        self.transpositions = (0 ..< n).combinations(ofCount: 2).map{ t in
            (t[0], t[1])
        }
    }
    
    public var gridNumber: UInt8 {
        diagram.gridNumber
    }
    
    public var numberOfGenerators: Int {
        generators.sum{ (_, set) in set.count }
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        generators.keys.map{ $0[0] }.closureRange ?? (0 ... 0)
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        generators.keys.map{ $0[1] }.closureRange ?? (0 ... 0)
    }
    
    public func generator(forSequence seq: [UInt8]) -> Generator? {
        let x = diagram.generator(for: seq)
        return generators.contains(key: [x.MaslovDegree, x.AlexanderDegree]) ? x : nil
    }
    
    public func generators(ofMaslovDegree d: Int) -> Set<Generator> {
        generators.keys.filter{ $0[0] == d }.reduce(into: Set()) {
            $0.formUnion( generators[$1]! )
        }
    }
    
    public func filter(_ predicate: (Int, Int) -> Bool) -> Self {
        .init(
            diagram: diagram,
            generators: generators.filter{ (index, _) in predicate(index[0], index[1]) },
            intersectionTable: intersectionTable
        )
    }
    
    public func adjacents(of x: Generator, with rectCond: (GridDiagram.Rect) -> Bool) -> [(Generator, GridDiagram.Rect)] {
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
    
    internal func intersectionInfo(for r: Rect) -> OXIntersectionTable.Info {
        intersectionTable[r]
    }
    
    public var distributionTable: String {
        let elements = generators
            .mapValues { $0.count }
            .map { (index, c) in (index[0], index[1], c)}
        
        return Format.table(elements: elements)
    }
}
