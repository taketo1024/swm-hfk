//
//  GridHomology.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore
import SwmHomology

public struct GridHomology: GradedModuleStructureType {
    public typealias BaseModule = GridComplex.BaseModule
    public typealias Index = MultiIndex<_2>
    public typealias Object = ModuleStructure<BaseModule>
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
    
    public var support: [MultiIndex<_2>] {
        let r1 = MaslovDegreeRange
        let r2 = AlexanderDegreeRange
        return (r2.reversed() * r1.reversed()).map { (j, i) in [i, j] }
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
    
    public func description(forObject obj: Object) -> String {
        obj.isZero ? "" : "\(obj.rank)"
    }
}
