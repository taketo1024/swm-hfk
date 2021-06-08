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

class GHFilteredTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testChainComplex() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let str = C.structure().mapValues{ $0.rank }
        XCTAssertEqual(str, [0: 1, -1: 1])
    }
    
    // GH-filtered(○) = F[U]
    func testUnknot() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
    
    // GH-filtered(∞) = F[U]
    func testUnknot_twisted() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
    
    // GH-filtered(3_1)
    func testTrefoil() {
        let G = GridDiagram.load("3_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
    
    // GH-filtered(4_1)
    func testFigureEight() {
        let G = GridDiagram.load("4_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
        XCTAssertEqual(H[-3].rank, 0)
        XCTAssertEqual(H[-4].rank, 1)
    }
}
