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
    private let transpositions: [(UInt8, UInt8)] // cached for performance
    
    public init(type: Variant, diagram: GridDiagram) {
        self.init(type: type, diagram: diagram, filter: { (_, _) in true })
    }
    
    public init(type: Variant, diagram: GridDiagram, filter: (Int, Int) -> Bool) {
        self.type = type
        self.construction = GridComplexConstruction(diagram: diagram, filter: filter)
        self.transpositions = (0 ..< construction.gridNumber).combinations(ofCount: 2).map{ t in (t[0], t[1]) }
    }
    
    public var support: [Int] {
        MaslovDegreeRange.reversed()
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
        ModuleStructure(rawGenerators: generators(i))
    }
    
    public func generators(_ i: Int) -> [InflatedGenerator] {
        let iMax = MaslovDegreeRange.upperBound
        if i > iMax {
            return []
        }
        
        let jMax = AlexanderDegreeRange.upperBound
        let jMin = AlexanderDegreeRange.lowerBound - (iMax - i) / 2
        
        return (jMin ... jMax).flatMap { j in
            generators(i, j)
        }
    }
    
    public func generators(_ i: Int, _ j: Int) -> [InflatedGenerator] {
        let n = numberOfIndeterminates
        if n == 0 {
            return construction.generators(i, j).map{ x -> InflatedGenerator in
                .unit ⊗ x
            }
        }
        
        let iMax = construction.MaslovDegreeRange.upperBound
        if i > iMax {
            return []
        }
        
        //              * x ... (i0, j0)
        //              |
        //              | e
        //        2e    |
        //  * ----------
        //  U^e ⊗ x ... (i, j)
        
        return (0 ... (iMax - i) / 2).flatMap { e -> [InflatedGenerator] in
            let i0 = i + 2 * e
            let j0 = j + e
            return construction
                .generators(i0, j0)
                .flatMap { x -> [InflatedGenerator] in
                    MultivariatePolynomial<R, _Un>.monomials(
                        ofDegree: -2 * e,
                        usingIndeterminates: 0 ..< n
                    ).map { mon in
                        let U = MonomialAsGenerator<_Un>(exponent: mon.leadExponent)
                        return U ⊗ x
                    }
                }
        }
    }

    private func connectingRects(from x: RawGenerator) -> [GridDiagram.Rect] {
        typealias Rect = GridDiagram.Rect
        typealias Point = GridDiagram.Point
        
        let gridSize = diagram.gridSize
        let pts = x.points
        
        return transpositions.flatMap { (i, j) -> [Rect] in
            let (p, q) = (pts[i], pts[j])
            let r1 = Rect(from: p, to: q, gridSize: gridSize)
            let r2 = Rect(from: q, to: p, gridSize: gridSize)
            
            return [r1, r2].filter { r in
                !r.intersects(pts, interior: true) && isAdmissible(rect: r)
            }
        }
    }
    
    private func isAdmissible(rect: GridDiagram.Rect) -> Bool {
        let n = diagram.gridNumber
        let Os = diagram.Os
        let Xs = diagram.Xs
        
        switch type {
        case .tilde:
            return (!rect.intersects(Os) && !rect.intersects(Xs))
        case .hat:
            return (!rect.intersects(Xs) && !rect.contains(Os[n - 1]))
        case .minus:
            return !rect.intersects(Xs)
        case .filtered:
            return true
        }
    }
    
    public func differentiate(_ x: RawGenerator) -> BaseModule {
        let n = numberOfIndeterminates
        let Os = diagram.Os
        
        var seq = x.sequence // to avoid array creations
        
        let ys = connectingRects(from: x)
            .map { rect -> InflatedGenerator in
                let y = construction.generator(from: x, by: rect, sequence: &seq)!
                let e = (0 ..< n).map { rect.contains(Os[$0]) ? 1 : 0 }
                let u = InflatedGenerator.Left(exponent: e)
                return u ⊗ y
            }
        return BaseModule(
            elements: ys.map{ y in (y, R.identity) }
        )
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

    public func description(forObject obj: ModuleStructure<BaseModule>) -> String {
        obj.isZero ? "" : "\(obj.rank)"
    }

    public func distributionTable(inflated: Bool = false) -> String {
        let elements: [(Int, Int, Int)]
        if inflated {
            elements = (MaslovDegreeRange * AlexanderDegreeRange).compactMap { (i, j) in
                let c = generators(i, j).count
                return (c > 0) ? (i, j, c) : nil
            }
        } else {
            elements = construction.generators
                .mapValues { $0.count }
                .map { (index, c) in (index[0], index[1], c)}
        }
        return Format.table(elements: elements)
    }
    
    public func printDistributionTable(inflated: Bool = false) {
        print(distributionTable(inflated: inflated))
    }
}
