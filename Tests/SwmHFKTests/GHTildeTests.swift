//
//  GridHomologyTests.swift
//  SwmKnotsTests
//
//  Created by Taketo Sano on 2019/07/01.
//

import XCTest
import SwmCore
import SwmHomology
@testable import SwmHFK

class GHTildeTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testChainComplex() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .tilde, diagram: G)
        let str = C.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 1])
    }
    
    // GH-tilde(○)
    func testUnknot() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.homology()
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 1])
    }
    
    // GH-tilde(∞), not a knot invariant!
    func testUnknot_twisted() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.homology()
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 2, -2: 1])
    }
    
    // GH-tilde(○), bigraded
    func testUnknot_bigraded() {
        let G = GridDiagram.load("0_1")!
        let H = GridHomology(type: .tilde, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 0]: 1, [-1, -1]: 1])
    }
    
    // GH-tilde(∞), bigraded
    func testUnknot_twisted_bigraded() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let H = GridHomology(type: .tilde, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 0]: 1, [-1, -1]: 2, [-2, -2]: 1])
    }
    
    // GH-tilde(3_1)
    func testTrefoil() {
        let G = GridDiagram.load("3_1")!
        let H = GridHomology(type: .tilde, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 1]: 1, [-1, 0]: 5, [-2, -1]: 11, [-3, -2]: 14, [-4, -3]: 11, [-5, -4]: 5, [-6, -5]: 1])
    }

    // GH-tilde(3_1)
    func testTrefoil_mirror() {
        let G = GridDiagram.load("3_1")!.rotate90
        let H = GridHomology(type: .tilde, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[2, 1]: 1, [1, 0]: 5, [0, -1]: 11, [-1, -2]: 14, [-2, -3]: 11, [-3, -4]: 5, [-4, -5]: 1])
    }
}
