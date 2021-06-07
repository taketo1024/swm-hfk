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
    public var construction: GridComplexConstruction
    
    private let cCache: Cache<Int, ModuleStructure<BaseModule>> = .empty
    private let dCache: Cache<RawGenerator, BaseModule> = .empty
    
    internal init(type: Variant, construction: GridComplexConstruction) {
        self.type = type
        self.construction = construction
    }
    
    public init(type: Variant, diagram G: GridDiagram) {
        self.init(type: type, construction: GridComplexConstruction(diagram: G))
    }
    
    public var diagram: GridDiagram {
        construction.diagram
    }
    
    public var gridNumber: Int {
        diagram.gridNumber
    }
    
    public var numberOfIndeterminates: Int {
        let n = gridNumber
        switch type {
        case .tilde:    return 0
        case .hat:      return n - 1
        case .minus:    return n
        case .filtered: return n
        }
    }
    
    public subscript(i: Int) -> ModuleStructure<BaseModule> {
        typealias P = MultivariatePolynomial<R, _Un>
        
        let iMax = construction.MaslovDegreeRange.upperBound
        guard i <= iMax else {
            return .zeroModule
        }
        
        return cCache.getOrSet(key: i) {
            let gens = (0 ... (iMax - i) / 2).flatMap { k in
                construction
                    .generators(ofMaslovDegree: i + 2 * k)
                    .flatMap { x -> [InflatedGenerator] in
                        let mons = P.monomials(
                            ofDegree: -2 * k,
                            usingIndeterminates: 0 ..< numberOfIndeterminates
                        )
                        return mons.map { mon in
                            .init(exponent: mon.leadExponent) ⊗ x
                        }
                    }
            }
            return ModuleStructure(rawGenerators: gens)
        }
    }
    
    public func rectCond(_ r: GridDiagram.Rect) -> Bool {
        let n = gridNumber
        let rects = construction.rects
        
        switch type {
        case .tilde:
            return (!rects[r].intersects(.X) && !rects[r].intersects(.O))
        case .hat:
            return (!rects[r].intersects(.X) && !rects[r].intersects(.O, n - 1))
        case .minus:
            return !rects[r].intersects(.X)
        case .filtered:
            return true
        }
    }
    
    public func differentiate(_ x: RawGenerator) -> BaseModule {
        dCache.getOrSet(key: x) {
            let ys = construction
                .adjacents(of: x, with: { r in rectCond(r) })
                .map { (y, r) -> InflatedGenerator in
                    let u = InflatedGenerator.Left(
                        exponent: construction.rects[r].intersections(.O)
                    )
                    return u ⊗ y
                }
            return BaseModule(
                elements: ys.map{ y in (y, R.identity) }
            )
        }
    }
    
    public var differential: Differential {
        Differential(degree: -1) { _ in
            ModuleEnd.linearlyExtend { t1 in
                let (m1, x) = t1.factors
                let dx = self.differentiate(x)
                
                if m1 == .unit {
                    return dx
                } else {
                    return dx.mapGenerators { t2 in
                        let (m2, y) = t2.factors
                        return (m1 * m2) ⊗ y
                    }
                }
            }
        }
    }
}

extension TensorGenerator where A == MonomialAsGenerator<_Un>, B == GridComplex.RawGenerator {
    public var algebraicDegree: Int {
        return -left.exponent[0]
    }
    
    public var AlexanderDegree: Int {
        return _Un.degreeOfMonomial(withExponent: left.exponent) / 2 + right.AlexanderDegree
    }
}
