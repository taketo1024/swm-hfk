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
    public let gridNumber: Int
    
    internal let generators: [Int : Generator]
    internal let rects: Rects
    private let transpositions: [(Int, Int)]
    
    public init(for G: GridDiagram) {
        self.init(for: G, filter: { _ in true })
    }
    
    public init(for G: GridDiagram, filter: @escaping (Generator) -> Bool) {
        let rects = Rects(G)
        let generators = Self.produce(G, rects, filter)
        self.init(
            gridNumber: G.gridNumber,
            generators: Dictionary(generators.map { x in (x.code, x) }),
            rects: rects
        )
    }
    
    private init(gridNumber: Int, generators: [Int : Generator], rects: Rects) {
        self.gridNumber = gridNumber
        self.generators = generators
        self.rects = rects
        self.transpositions = (0 ..< gridNumber).choose(2).map{ t in (t[0], t[1]) }
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        generators.values.map{ $0.degree }.closureRange ?? (0 ... 0)
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        generators.values.map{ $0.AlexanderDegree }.closureRange ?? (0 ... 0)
    }
    
    public func generator(forSequence seq: [Int]) -> Generator? {
        let code = Generator.encode(seq)
        return generators[code]
    }
    
    public func adjacents(of x: Generator, with rectCond: (GridDiagram.Rect) -> Bool) -> [(Generator, GridDiagram.Rect)] {
        typealias Point = GridDiagram.Point
        typealias Rect  = GridDiagram.Rect
        
        let n = gridNumber
        let seq = x.sequence
        let pts = x.points
        
        return transpositions.flatMap { (i, j) -> [(Generator, GridDiagram.Rect)] in
            let p = Point(2 * i, 2 * seq[i])
            let q = Point(2 * j, 2 * seq[j])
            
            let rs = [
                Rect(from: p, to: q, gridSize: 2 * n),
                Rect(from: q, to: p, gridSize: 2 * n)
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
    
    public func filter(_ predicate: (Generator) -> Bool) -> Self {
        GeneratorSet(
            gridNumber: gridNumber,
            generators: generators.filter{ (_, x) in predicate(x) },
            rects: rects
        )
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
    
    internal struct Rects {
        typealias Point = GridDiagram.Point
        typealias Rect  = GridDiagram.Rect
        
        private let gridNumber: Int
        private let data: [Rect : Info]
        
        init(_ G: GridDiagram) {
            typealias Point = GridDiagram.Point
            
            let n = G.gridNumber
            let rects = ((0 ..< n) * (0 ..< n)).flatMap { (x, y) -> [Rect] in
                return ((0 ..< n) * (0 ..< n)).map { (w, h) -> Rect in
                    return Rect(
                        origin: Point(2 * x, 2 * y),
                        size: Point(2 * w, 2 * h),
                        gridSize: G.gridSize
                    )
                }
            }
            
            self.gridNumber = n
            self.data = Dictionary(keys: rects) { r in
                Info(G, r)
            }
        }
        
        subscript(_ r: Rect) -> Info {
            data[r]!
        }
        
        struct Info {
            let gridNumber: Int
            let Ocode : Int
            let Ocount: Int
            let Xcode : Int
            let Xcount: Int
            
            init(_ G: GridDiagram, _ r: Rect) {
                let (Os, Xs) = (G.Os, G.Xs)
                self.gridNumber = G.gridNumber
                (self.Ocode, self.Ocount) = Self.encodeIntersections(Os, r)
                (self.Xcode, self.Xcount) = Self.encodeIntersections(Xs, r)
            }
            
            private static func encodeIntersections(_ points: [Point], _ rect: Rect) -> (code: Int, count: Int) { // binary flags
                points.enumerated().reduce(into: (0, 0)) { (res, e) in
                    let (i, p) = e
                    if rect.contains(p) {
                        res.0 |= (1 << i)
                        res.1 += 1
                    }
                }
            }
            
            enum IntersectionType {
                case O, X
            }
            
            func intersections(_ type: IntersectionType) -> [Int] {
                let code = (type == .O) ? Ocode : Xcode
                return (0 ..< gridNumber).map { i in
                    (code >> i) & 1
                }
            }
            
            func countIntersections(_ type: IntersectionType) -> Int {
                (type == .O) ? Ocount : Xcount
            }
            
            func intersects(_ type: IntersectionType) -> Bool {
                countIntersections(type) > 0
            }
            
            func intersects(_ type: IntersectionType, _ index: Int) -> Bool {
                let code = (type == .O) ? Ocode : Xcode
                return (code >> index) & 1 == 1
            }
        }
    }
}

extension GridComplexConstruction {
    internal static func produce(_ G: GridDiagram, _ rects: Rects, _ filter: @escaping (Generator) -> Bool) -> Set<Generator> {
        Producer(G, rects, filter).produce()
    }
    
    private final class Producer {
        typealias Generator = GridComplexGenerator
        typealias Point = GridDiagram.Point
        typealias Rect  = GridDiagram.Rect

        let G: GridDiagram
        let rects: Rects
        let filter: (Generator) -> Bool
        let trans: [(Int, Int)]
        
        init(_ G: GridDiagram, _ rects: Rects, _ filter: @escaping (Generator) -> Bool) {
            self.G = G
            self.rects = rects
            self.filter = filter
            
            let n = G.gridNumber
            self.trans = Self.heapTranspositions(length: n - 1)
        }
        
        func produce() -> Set<Generator> {
            let n = G.gridNumber
            
            var data: Set<Generator> = []
            data.reserveCapacity(n.factorial)
            
            Array(0 ..< n).forEach { i in
                let data_i = self.produce(step: i)
                data.formUnion(data_i)
            }
            
            return data
        }
        
        private func produce(step i: Int) -> Set<Generator> {
            let n = G.gridNumber
            
            var data: Set<Generator> = []
            data.reserveCapacity((n - 1).factorial)
            
            func add(_ seq: [Int], _ M: Int, _ A: Int) {
                let x = Generator(
                    sequence: seq,
                    MaslovDegree: M,
                    AlexanderDegree: A
                )
                
                if filter(x) {
                    data.insert(x)
                }
            }
            
            var seq = Array(0 ..< n)
            seq.swapAt(i, n - 1)
            
            var pts = points(seq)
            var (m, a) = (M(pts), A(pts))

            add(seq, m, a)
            
            for (i, j) in trans {
                // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
                // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)

                let r = GridDiagram.Rect(from: pts[i], to: pts[j], gridSize: G.gridSize)
                let nO = rects[r].countIntersections(.O)
                let nX = rects[r].countIntersections(.X)
                
                let c = (i + 1 ..< j).count { i in
                    r.contains(pts[i], interior: true)
                }

                let dm = 2 * (nO - c) - 1
                let da = nO - nX

                seq.swapAt(i, j)

                pts[i] = Point(2 * i, 2 * seq[i])
                pts[j] = Point(2 * j, 2 * seq[j])
                
                m += dm
                a += da

                add(seq, m, a)
            }
            
            return data
        }
        
        private func points(_ seq: [Int]) -> [Point] {
            seq.enumerated().map { (i, j) in Point(2 * i, 2 * j) }
        }
        
        private func I(_ x: [Point], _ y: [Point]) -> Int {
            (x * y).count{ (p, q) in p < q }
        }
        
        private func J(_ x: [Point], _ y: [Point]) -> Int {
            I(x, y) + I(y, x)
        }
        
        private func M(_ ref: [Point], _ x: [Point]) -> Int {
            ( J(x, x) - 2 * J(x, ref) + J(ref, ref) ) / 2 + 1
        }
        
        private func M(_ x: [Point]) -> Int {
            M(G.Os, x)
        }
        
        private func A(_ x: [Point]) -> Int {
            ( M(G.Os, x) - M(G.Xs, x) - G.gridNumber + 1 ) / 2
        }
        
        // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
        private static func heapTranspositions(length n: Int) -> [(Int, Int)] {
            var result: [(Int, Int)] = []
            result.reserveCapacity(n.factorial)
            
            func generate(_ k: Int) {
                if k <= 1 {
                    return
                }
                
                generate(k - 1)
                
                for l in 0 ..< k - 1 {
                    let (i, j) = (k % 2 == 0) ? (l, k - 1) : (0, k - 1)
                    result.append( (i, j) )
                    
                    generate(k - 1)
                }
            }
            
            generate(n)
            
            return result
        }
    }
}
