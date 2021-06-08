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

class GHHatTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testChainComplex() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .hat, diagram: G)
        let str = C.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 1])
    }
    
    // GH-hat(○)
    func testUnknot() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology()
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1])
    }
    
    // GH-hat(∞)
    func testUnknot_twisted() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology()
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1])
    }
    
    // GH-hat(○), bigraded
    func testUnknot_bigraded() {
        let G = GridDiagram.load("0_1")!
        let H = GridHomology(type: .hat, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 0]: 1])
    }
    
    // GH-hat(∞), bigraded
    func testUnknot_twisted_bigraded() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let H = GridHomology(type: .hat, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 0]: 1])
    }
    
    // GH-hat(3_1)
    func testTrefoil() {
        let G = GridDiagram.load("3_1")!
        let H = GridHomology(type: .hat, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[0, 1]: 1, [-1, 0]: 1, [-2, -1]: 1])
    }

    // GH-hat(3_1)
    func testTrefoil_mirror() {
        let G = GridDiagram.load("3_1")!.rotate90
        let H = GridHomology(type: .hat, diagram: G)
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[2, 1]: 1, [1, 0]: 1, [0, -1]: 1])
    }
    
    // GH-hat(4_1)
    func testFigureEight() {
        let G = GridDiagram.load("4_1")!
        let H = GridHomology(type: .hat, diagram: G, filter: { (_, j) in j >= -1 })
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[1, 1]: 1, [0, 0]: 3, [-1, -1]: 1])
    }

    // GH-hat(4_1)
    func testFigureEight_mirror() {
        let G = GridDiagram.load("4_1")!.rotate90
        let H = GridHomology(type: .hat, diagram: G, filter: { (_, j) in j >= -1 })
        let str = H.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [[1, 1]: 1, [0, 0]: 3, [-1, -1]: 1])
    }
}
