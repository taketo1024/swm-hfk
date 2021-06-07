//
//  GridComplexData.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2020/02/06.
//

import SwmCore
import Dispatch

public typealias GeneratorSet = GridComplexConstruction

public struct GridComplexConstruction: Sequence {
    public typealias Generator = GridComplexGenerator
    public typealias Point = GridDiagram.Point
    public typealias Rect  = GridDiagram.Rect

    public let diagram: GridDiagram
    internal let generators: [Generator.Code : Generator]
    
    private let intersectionTable: GridDiagram.OXIntersectionTable
    private let transpositions: [(UInt8, UInt8)]
    
    public init(diagram: GridDiagram) {
        self.init(diagram: diagram, filter: { _ in true })
    }
    
    public init(diagram: GridDiagram, filter: @escaping (Generator) -> Bool) {
        let intersectionTable = diagram.intersectionTable
        let generators = GridComplexGeneratorProducer(diagram, intersectionTable, filter).produce()
        self.init(
            diagram: diagram,
            generators: generators,
            intersectionTable: intersectionTable
        )
    }
    
    private init(diagram: GridDiagram, generators: [Generator.Code : Generator], intersectionTable: GridDiagram.OXIntersectionTable) {
        self.diagram = diagram
        self.generators = generators
        self.intersectionTable = intersectionTable
        
        let n = UInt8(diagram.gridNumber)
        self.transpositions = (0 ..< n).choose(2).map{ t in (t[0], t[1]) }
    }
    
    public var gridNumber: Int {
        diagram.gridNumber
    }
    
    public var numberOfGenerators: Int {
        generators.count
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        generators.values.map{ $0.degree }.closureRange ?? (0 ... 0)
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        generators.values.map{ $0.AlexanderDegree }.closureRange ?? (0 ... 0)
    }
    
    public func generator(forSequence seq: [UInt8]) -> Generator? {
        let code = Generator.code(for: seq)
        return generators[code]
    }
    
    public func generators(ofMaslovDegree d: Int) -> [Generator] {
        filter { $0.MaslovDegree == d }
    }
    
    // FIXME: this is time consuming
    public func filter(_ predicate: (Generator) -> Bool) -> Self {
        GeneratorSet(
            diagram: diagram,
            generators: generators.filter{ (_, x) in predicate(x) },
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
    
    public func intersectionInfo(for r: Rect) -> GridDiagram.OXIntersectionTable.Info {
        intersectionTable[r]
    }
    
    public func makeIterator() -> AnySequence<Generator>.Iterator {
        AnySequence(generators.values).makeIterator()
    }
    
    public var distributionTable: String {
        let elements = self
            .group { x in x.degree }
            .mapValues { list in
                list.group{ x in x.AlexanderDegree }
                    .map{ (j, list) in (j, list.count) }
            }
            .sorted { (i, _) in i }
            .flatMap { (i, list) in list.map{ (j, c) in (i, j, c) }}
        
        return Format.table(elements: elements)
    }
}
