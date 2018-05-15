//
//  LinkTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class LinkTests: XCTestCase {
    
    typealias A = JonesPolynomial
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(e.components.count, 0)
        XCTAssertEqual(e.crossingNumber, 0)
        XCTAssertEqual(e.unnormalizedJonesPolynomial, A(1))
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(O.components.count, 1)
        XCTAssertEqual(O.crossingNumber, 0)
        XCTAssertEqual(O.JonesPolynomial, A(1))
    }

    func testHopfLink() {
        let L = Link.HopfLink
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkReversed() {
        let L = Link.HopfLink.reversed
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkMirrored() {
        let L = Link.HopfLink.mirrored
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, 2)
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [5: 1, 1: 1]) )
    }
    
    func testTrefoil() {
        let K = Link.trefoil
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilReversed() {
        let K = Link.trefoil.reversed
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilMirrored() {
        let K = Link.trefoil.mirrored
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, 3)
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [8: -1, 6: 1, 2: 1]))
    }
    
    func testPlanarCode() {
        let K = Link.trefoil
        print(K.planarCode)
        
        let Kr = K.reversed
        print(Kr.planarCode)
        
        let Km = K.mirrored
        print(Km.planarCode)
    }
    
    func testCoding() {
        let K = Link.trefoil
        let d = try! JSONEncoder().encode(K)
        let K2 = try! JSONDecoder().decode(Link.self, from: d)
        XCTAssertEqual(K, K2)
    }
    
    func testCodingReversed() {
        let K = Link.trefoil.reversed
        let d = try! JSONEncoder().encode(K)
        let K2 = try! JSONDecoder().decode(Link.self, from: d)
        
        XCTAssertEqual(K.crossingNumber, K2.crossingNumber)
        XCTAssertEqual(K.writhe, K2.writhe)
        XCTAssertEqual(K.JonesPolynomial, K2.JonesPolynomial)
    }
    
    func testCodingMirrored() {
        let K = Link.trefoil.mirrored
        let d = try! JSONEncoder().encode(K)
        let K2 = try! JSONDecoder().decode(Link.self, from: d)
        
        XCTAssertEqual(K.crossingNumber, K2.crossingNumber)
        XCTAssertEqual(K.writhe, K2.writhe)
        XCTAssertEqual(K.JonesPolynomial, K2.JonesPolynomial)
    }
}
