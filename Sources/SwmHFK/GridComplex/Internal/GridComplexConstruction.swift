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

    let diagram: GridDiagram
    let generators: GeneratorTable
    
    init(diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        self.diagram = diagram
        
        let p = GridComplexGeneratorProducer(diagram)
        self.generators = p.produce(filter: filter)
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
    
    func generator(from x: Generator, by rect: GridDiagram.Rect, sequence: inout [UInt8]) -> Generator? {
        let (i, j) = (rect.origin.x/2 % gridNumber, rect.destination.x/2 % gridNumber)
        let code = encode(&sequence, transposing: (i, j))

        let nO = rect.countIntersections(diagram.Os)
        let nX = rect.countIntersections(diagram.Xs)
        
        let m = x.MaslovDegree + 2 * nO - 1
        let a = x.AlexanderDegree + nO - nX

        return find(code, m, a)
    }
    
    // MEMO:
    // We don't want to create arrays for each iteration,
    // so we reuse the mutable ones.
    
    private func encode(_ seq: inout [UInt8], transposing t: (UInt8, UInt8)) -> Int {
        let (i, j) = t
        
        seq.swapAt(i, j)
        defer{ seq.swapAt(i, j)}
        
        return GridComplexGenerator.encode(seq)
    }
    
    private func find(_ code: GridComplexGenerator.Code, _ i: Int, _ j: Int) -> GridComplexGenerator? {
        generators[[i, j]]?.binarySearch(elementWithId: code, by: { $0.code })
    }
}
