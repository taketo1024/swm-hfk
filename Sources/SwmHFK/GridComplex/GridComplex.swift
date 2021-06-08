//
//  GridComplex.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwmCore
import SwmHomology

public struct _U: PolynomialIndeterminate {
    public static let degree = -2
    public static var symbol = "U"
}

public typealias _Un = EnumeratedPolynomialIndeterminates<_U, anySize>

public enum GridComplexVariant {
    case tilde    // [Book] p.72,  Def 4.4.1
    case hat      // [Book] p.80,  Def 4.6.12.
    case minus    // [Book] p.75,  Def 4.6.1
    case filtered // [Book] p.252, Def 13.2.1
}

public struct GridComplex: ChainComplexType {
    public typealias R = 𝐅₂
    
    public typealias Variant = GridComplexVariant
    public typealias RawGenerator = GridComplexGenerator
    public typealias InflatedGenerator = TensorGenerator<
        MonomialAsGenerator<_Un>,
        RawGenerator
    >

    public typealias Index = Int
    public typealias BaseModule = LinearCombination<R, InflatedGenerator>
    public typealias Differential = ChainMap<Self, Self>
    
    public var type: Variant
    
    internal var construction: GridComplexConstruction
    private let cCache: Cache<Int, ModuleStructure<BaseModule>> = .empty
    private let dCache: Cache<RawGenerator, BaseModule> = .empty
    
    public init(type: Variant, diagram: GridDiagram) {
        self.init(type: type, diagram: diagram, filter: { (_, _) in true })
    }
    
    public init(type: Variant, diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        let constr = GridComplexConstruction(diagram: diagram, filter: filter)
        self.init(type: type, construction: constr)
    }
    
    internal init(type: Variant, construction: GridComplexConstruction) {
        self.type = type
        self.construction = construction
    }
    
    public var diagram: GridDiagram {
        construction.diagram
    }
    
    public var gridNumber: UInt8 {
        diagram.gridNumber
    }
    
    public var numberOfGenerators: Int {
        construction.numberOfGenerators
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        construction.MaslovDegreeRange
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        construction.AlexanderDegreeRange
    }
    
    public var numberOfIndeterminates: Int {
        let n = Int(gridNumber)
        switch type {
        case .tilde:    return 0
        case .hat:      return n - 1
        case .minus:    return n
        case .filtered: return n
        }
    }
    
    public subscript(i: Int) -> ModuleStructure<BaseModule> {
        cCache.getOrSet(key: i) {
            ModuleStructure(rawGenerators: generators(i))
        }
    }
    
    public func generators(_ i: Int) -> [InflatedGenerator] {
        generators(
            degree: i,
            bidegreeCond: { e in
                { (i0, _) in i0 == i + 2 * e }
            },
            monomialCond: { _ in
                { _ in true }
            }
        )
    }
    
    public func generators(_ i: Int, _ j: Int) -> [InflatedGenerator] {
        generators(
            degree: i,
            bidegreeCond: { e in
                { (i0, j0) in i0 == i + 2 * e && j0 == j + e }
            },
            monomialCond: { _ in
                { _ in true }
            }
        )
    }
    
    public func generators(_ i: Int, _ j: Int, _ k: Int) -> [InflatedGenerator] {
        generators(
            degree: i,
            bidegreeCond: { e in
                { (i0, j0) in i0 == i + 2 * e && j0 == j + e }
            },
            monomialCond: { e in
                { m in m.leadExponent[0] == k }
            }
        )
    }
    
    private func generators(degree i: Int, bidegreeCond: (Int) -> (Int, Int) -> Bool, monomialCond: (Int) -> (MultivariatePolynomial<R, _Un>) -> Bool) -> [InflatedGenerator] {
        let iMax = construction.MaslovDegreeRange.upperBound
        if i > iMax {
            return []
        }
        
        return (0 ... (iMax - i) / 2).flatMap { e -> [InflatedGenerator] in
            let p1 = bidegreeCond(e)
            let p2 = monomialCond(e)
            return construction
                .generators(p1)
                .flatMap { x -> [InflatedGenerator] in
                    let mons = MultivariatePolynomial<R, _Un>.monomials(
                        ofDegree: -2 * e,
                        usingIndeterminates: 0 ..< numberOfIndeterminates
                    ).filter(p2)
                    return mons.map { mon in
                        MonomialAsGenerator(exponent: mon.leadExponent) ⊗ x
                    }
                }
        }
    }

    public func rectCond(_ rect: GridDiagram.Rect) -> Bool {
        let n = gridNumber
        let r = construction.intersectionInfo(for: rect)
        
        switch type {
        case .tilde:
            return (!r.intersects(.X) && !r.intersects(.O))
        case .hat:
            return (!r.intersects(.X) && !r.intersects(.O, n - 1))
        case .minus:
            return !r.intersects(.X)
        case .filtered:
            return true
        }
    }
    
    public func differentiate(_ x: RawGenerator) -> BaseModule {
        dCache.getOrSet(key: x) {
            let ys = construction
                .adjacents(of: x, with: { r in rectCond(r) })
                .map { (y, rect) -> InflatedGenerator in
                    let r = construction.intersectionInfo(for: rect)
                    let e = r.intersections(.O)
                    let u = InflatedGenerator.Left(exponent: e)
                    return u ⊗ y
                }
            return BaseModule(
                elements: ys.map{ y in (y, R.identity) }
            )
        }
    }
    
    public func differentiate(_ t: InflatedGenerator) -> BaseModule {
        let (m1, x) = t.factors
        let dx = differentiate(x)
        
        if m1 == .unit {
            return dx
        } else {
            return dx.mapGenerators { t2 in
                let (m2, y) = t2.factors
                return (m1 * m2) ⊗ y
            }
        }
    }
    
    public var differential: Differential {
        Differential(degree: -1) { _ in
            ModuleEnd.linearlyExtend { t in
                differentiate(t)
            }
        }
    }
    
    public func sub(_ j: Int) -> ChainComplex1<BaseModule> {
        if type == .filtered {
            fatalError("type: filtered does not decompose into direct summands.")
        }
        return .init(
            grid: { i in
                ModuleStructure(rawGenerators: generators(i, j))
            },
            degree: -1,
            differential: { _ in
                ModuleEnd.linearlyExtend { t in
                    differentiate(t)
                }
            }
        )
    }
    
    public var distributionTable: String {
        let elements = construction.generators
            .mapValues { $0.count }
            .map { (index, c) in (index[0], index[1], c)}
        
        return Format.table(elements: elements)
    }
}
