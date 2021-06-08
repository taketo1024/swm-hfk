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

class GHMinusTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testChainComplex() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let str = C.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 1])
    }
    
    // GH-minus(○) = F[U]
    func testUnknot() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
    
    // GH-minus(∞) = F[U]
    func testUnknot_twisted() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
    
    // GH-minus(○), bigraded
    func testUnknot_bigraded() {
        let G = GridDiagram.load("0_1")!
        let H = GridHomology(type: .minus, diagram: G)
        XCTAssertEqual(H[0, 0].rank, 1)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
        XCTAssertEqual(H[-6, -3].rank, 1)
    }
    
    // GH-minus(∞), bigraded
    func testUnknot_twisted_bigraded() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let H = GridHomology(type: .minus, diagram: G)
        XCTAssertEqual(H[0, 0].rank, 1)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
        XCTAssertEqual(H[-6, -3].rank, 1)
    }
    
    // GH-minus(3_1)
    func testTrefoil() {
        let G = GridDiagram.load("3_1")!
        let H = GridHomology(type: .minus, diagram: G)
        XCTAssertEqual(H[0, 1].rank, 1)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
        XCTAssertEqual(H[-6, -3].rank, 1)
    }

    // GH-minus(3_1)
    func testTrefoil_mirror() {
        let G = GridDiagram.load("3_1")!.rotate90
        let H = GridHomology(type: .minus, diagram: G)
        XCTAssertEqual(H[2, 1].rank, 1)
        XCTAssertEqual(H[1, 0].rank, 1)
        XCTAssertEqual(H[0, 0].rank, 1)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
    }
    
    // GH-minus(4_1)
    func testFigureEight() {
        let G = GridDiagram.load("4_1")!
        let H = GridHomology(type: .minus, diagram: G, filter: { (_, j) in j >= -2 })
        XCTAssertEqual(H[1, 1].rank, 1)
        XCTAssertEqual(H[0, 0].rank, 2)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
    }

    // GH-minus(4_1)
    func testFigureEight_mirror() {
        let G = GridDiagram.load("4_1")!.rotate90
        let H = GridHomology(type: .minus, diagram: G, filter: { (_, j) in j >= -2 })
        XCTAssertEqual(H[1, 1].rank, 1)
        XCTAssertEqual(H[0, 0].rank, 2)
        XCTAssertEqual(H[-2, -1].rank, 1)
        XCTAssertEqual(H[-4, -2].rank, 1)
    }
}
