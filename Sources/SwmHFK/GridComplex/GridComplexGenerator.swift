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
    
    public subscript(_ i: UInt8) -> UInt8 {
        Self.decode(code, gridNumber, at: i)
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
    
    internal static func encode(_ seq: [UInt8]) -> Code {
        seq.reduce(into: UInt64(0)) {
            $0 <<= 4
            $0 |= UInt64($1)
        }
    }
    
    internal static func decode(_ code: Code, _ gridNumber: UInt8) -> [UInt8] {
        (0 ..< gridNumber).reduce(into: ([UInt8].empty, code)) { (res, _) in
            res.0.append(UInt8(res.1 & 0xF))
            res.1 >>= 4
        }.0.reversed()
    }

    internal static func decode(_ code: Code, _ gridNumber: UInt8, at index: UInt8) -> UInt8 {
        UInt8(
            (code >> (4 * (gridNumber - index - 1))) & 0xF
        )
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
