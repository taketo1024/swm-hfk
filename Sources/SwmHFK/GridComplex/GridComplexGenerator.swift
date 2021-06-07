//
//  GridComplexGenerator.swift
//  SwmHomology
//
//  Created by Taketo Sano on 2019/09/10.
//

import SwmCore
import Dispatch

public struct GridComplexGenerator: LinearCombinationGenerator {
    public typealias Code = Int
    public let code: Code
    public let length: UInt8
    public let MaslovDegree: Int
    public let AlexanderDegree: Int
    
    public init(sequence: [UInt8], MaslovDegree: Int, AlexanderDegree: Int) {
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
    
    // See: Knuth, Volume 2, Section 3.3.2, Algorithm P
    internal static func encode(_ _seq: [UInt8]) -> Int {
        var seq = _seq
        var r = UInt8(_seq.count)
        var code = 0
        
        while r > 0 {
            let m = (0 ..< r).first { m in
                r - seq[m] == 1
            }!
            code = code * Int(r) + Int(m)
            r -= 1
            seq.swapAt(r, m)
        }
        
        return code
    }
    
    internal static func decode(_ _code: Int, _ size: UInt8) -> [UInt8] {
        var (code, r) = (_code, 1)
        var seq = Array(0 ..< size)
        
        while r < Int(size) {
            let m = code % (r + 1)
            code = code / (r + 1)
            seq.swapAt(r, m)
            r += 1
        }
        
        return seq
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
