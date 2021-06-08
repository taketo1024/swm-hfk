//
//  GridHomology.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore
import SwmHomology

public struct GridHomology: GradedModuleStructureType {
    public typealias Index = MultiIndex<_2>
    public typealias BaseModule = GridComplex.BaseModule
    public typealias Variant = GridComplex.Variant

    public let chainComplex: GridComplex
    private let homologyCache: Cache<Int, GradedModuleStructure<Int, BaseModule>> = .empty
    
    public init(type: Variant, diagram: GridDiagram) {
        self.init(type: type, diagram: diagram, filter: { (_, _) in true })
    }
    
    public init(type: Variant, diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        self.chainComplex = GridComplex(type: type, diagram: diagram, filter: filter)
    }
    
    public subscript(idx: Index) -> Object {
        let (i, j) = idx.tuple
        let Hj = homologyCache.getOrSet(key: j) {
            let Cj = chainComplex.sub(j)
            return Cj.homology(options: .onlyStructures)
        }
        return Hj[i]
    }
    
    public func shifted(_ shift: Index) -> Self {
        fatalError("not implemented")
    }
    
    public var diagram: GridDiagram {
        chainComplex.diagram
    }
    
    public var gridNumber: UInt8 {
        diagram.gridNumber
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        chainComplex.MaslovDegreeRange
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        chainComplex.AlexanderDegreeRange
    }
    
    public func structure() -> [Index : Object] {
        let r1 = MaslovDegreeRange
        let r2 = AlexanderDegreeRange
        return Dictionary(
            (r2.reversed() * r1.reversed()).map { (j, i) in
                (MultiIndex(i, j), self[i, j])
            }
        )
    }
    
    public func printTable() {
        let str = structure()
        let table = Format.table(elements: str.map{ (idx, V) in (idx[0], idx[1], V.rank != 0 ? "\(V.rank)" : "" )})
        print(table)
    }
    
    public static func genus(of G: GridDiagram) -> Int {
        let H = GridHomology(type: .tilde, diagram: G, filter: { (_, j) in j >= 1 })
        let r1 = H.MaslovDegreeRange
        let r2 = H.AlexanderDegreeRange

        for (j, i) in (r2.reversed() * r1.reversed()) {
            if !H[i, j].isZero {
                return j
            }
        }
        return 0
    }
}


