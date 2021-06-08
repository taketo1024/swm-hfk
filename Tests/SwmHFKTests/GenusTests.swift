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

class GenusTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testKnotGenus0_1() {
        let G = GridDiagram.load("0_1")!
        let g = GridHomology.genus(of: G)
        XCTAssertEqual(g, 0)
    }
    
    func testKnotGenus3_1() {
        let G = GridDiagram.load("3_1")!
        let g = GridHomology.genus(of: G)
        XCTAssertEqual(g, 1)
    }

    func testKnotGenus4_1() {
        let G = GridDiagram.load("4_1")!
        let g = GridHomology.genus(of: G)
        XCTAssertEqual(g, 1)
    }

    func testKnotGenus5_1() {
        let G = GridDiagram.load("5_1")!
        let g = GridHomology.genus(of: G)
        XCTAssertEqual(g, 2)
    }

    func testKnotGenus5_2() {
        let G = GridDiagram.load("5_2")!
        let g = GridHomology.genus(of: G)
        XCTAssertEqual(g, 1)
    }
}
