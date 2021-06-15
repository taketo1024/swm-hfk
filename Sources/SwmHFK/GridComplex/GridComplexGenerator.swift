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
    public let gridNumber: UInt8
    public let MaslovDegree: Int
    public let AlexanderDegree: Int
    
    public init(diagram: GridDiagram, sequence: [UInt8]) {
        let pts = [GridDiagram.Point].evenPoints(from: sequence)
        let m = diagram.MaslovDegree(for: pts)
        let a = diagram.AlexanderDegree(for: pts)
        self.init(sequence: sequence, MaslovDegree: m, AlexanderDegree: a)
    }
    
    public init(sequence: [UInt8], MaslovDegree: Int, AlexanderDegree: Int) {
        assert(sequence.count <= 16)
        self.init(
            code: Self.encode(sequence),
            gridNumber: UInt8(sequence.count),
            MaslovDegree: MaslovDegree,
            AlexanderDegree: AlexanderDegree
        )
    }
    
    @inlinable
    internal init(code: Code, gridNumber: UInt8, MaslovDegree: Int, AlexanderDegree: Int) {
        self.code = code
        self.gridNumber = gridNumber
        self.MaslovDegree = MaslovDegree
        self.AlexanderDegree = AlexanderDegree
    }
    
    public var sequence: [UInt8] {
        Self.decode(code, gridNumber)
    }
    
    public var points: [GridDiagram.Point] {
        .evenPoints(from: sequence)
    }
    
    public var degree: Int {
        MaslovDegree
    }
    
    public var bidegree: (Int, Int) {
        (MaslovDegree, AlexanderDegree)
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
    internal static func encode(_ seq: [UInt8]) -> Int {
        let n = UInt8(seq.count)
        
        var tmp = seq
        var code = 0
        
        //       i       k                          i       k
        // (..., k, ..., *, k+1, ..., n-1) -> (..., *, ..., k, k+1, ..., n-1)
        
        for k in (0 ..< n).reversed() {
            let i = (0 ... k).first { i in
                k == tmp[i]
            }!
            code = code * Int(k + 1) + Int(i)
            tmp.swapAt(i, k)
        }
        
        return code
    }
    
    internal static func decode(_ code: Int, _ size: UInt8) -> [UInt8] {
        let n = Int(size)
        var tmp = code
        var seq = Array(0 ..< size)
        
        for k in 1 ..< n {
            let i = tmp % (k + 1)
            tmp = tmp / (k + 1)
            seq.swapAt(i, k)
        }
        
        return seq
    }

    public var description: String {
        "\(sequence)"
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

extension GridDiagram {
    private func I(_ x: [Point], _ y: [Point]) -> Int {
        (x * y).count{ (p, q) in p < q }
    }
    
    private func J(_ x: [Point], _ y: [Point]) -> Int {
        I(x, y) + I(y, x)
    }
    
    private func M(_ ref: [Point], _ x: [Point]) -> Int {
        ( J(x, x) - 2 * J(x, ref) + J(ref, ref) ) / 2 + 1
    }
    
    internal func MaslovDegree(for x: [Point]) -> Int {
        M(Os, x)
    }
    
    internal func AlexanderDegree(for x: [Point]) -> Int {
        ( M(Os, x) - M(Xs, x) - Int(gridNumber) + 1 ) / 2
    }
}
