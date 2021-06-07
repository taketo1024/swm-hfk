//
//  GridComplexGenerator.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2019/09/10.
//

import SwmCore
import Dispatch

public struct GridComplexGenerator: LinearCombinationGenerator {
    public typealias Code = UInt64
    public let code: Code
    public let length: UInt8
    public let MaslovDegree: Int
    public let AlexanderDegree: Int
    
    public init(sequence: [UInt8], MaslovDegree: Int, AlexanderDegree: Int) {
        assert(sequence.count <= 16)
        self.code = Self.code(for: sequence)
        self.length = UInt8(sequence.count)
        self.MaslovDegree = MaslovDegree
        self.AlexanderDegree = AlexanderDegree
    }
    
    public static func code(for sequence: [UInt8]) -> Code {
        encode(sequence)
    }
    
    public var sequence: [UInt8] {
        Self.decode(code, length)
    }
    
    public var points: [GridDiagram.Point] {
        sequence.enumerated().map { (i, j) in
            .init(2 * UInt8(i), 2 * j)
        }
    }
    
    public var degree: Int {
        MaslovDegree
    }
    
    public func isAdjacent(to y: Self) -> Bool {
        Set(sequence).subtracting(y.sequence).count == 2
    }
    
    @inlinable
    public static func == (x: Self, y: Self) -> Bool {
        x.code == y.code
    }
    
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    public static func < (x: Self, y: Self) -> Bool {
        x.code < y.code
    }
    
    internal static func encode(_ seq: [UInt8]) -> Code {
        seq.reduce(into: UInt64(0)) {
            $0 <<= 4
            $0 |= UInt64($1)
        }
    }
    
    internal static func decode(_ code: Code, _ size: UInt8) -> [UInt8] {
        (0 ..< size).reduce(into: ([UInt8].empty, code)) { (res, _) in
            res.0.append(UInt8(res.1 & 0xF))
            res.1 >>= 4
        }.0.reversed()
    }
    
    public var description: String {
        "\(sequence)"
    }
}

extension GridDiagram {
    public func rectangles(from x: GridComplexGenerator, to y: GridComplexGenerator) -> [Rect] {
        let (ps, qs) = (x.points, y.points)
        let diff = Set(ps).subtracting(qs)
        
        guard diff.count == 2 else {
            return []
        }
        
        let pq = diff.toArray()
        let (p, q) = (pq[0], pq[1])
        
        return [Rect(from: p, to: q, gridSize: gridSize),
                Rect(from: q, to: p, gridSize: gridSize)]
    }
    
    public func emptyRectangles(from x: GridComplexGenerator, to y: GridComplexGenerator) -> [Rect] {
        // Note: Int(r) ∩ x = Int(r) ∩ y .
        rectangles(from: x, to: y).filter{ r in
            !r.intersects(x.points, interior: true)
        }
    }
}
