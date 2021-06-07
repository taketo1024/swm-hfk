//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import XCTest
import Algorithms
import SwmCore
import SwmHomology
@testable import SwmHFK

class GeneratorTests: XCTestCase {
    typealias Generator = GridComplexGenerator
    func testEncodeDecode() {
        let n = 5
        for _p in (0 ..< n).permutations() {
            let p = _p.map{ UInt8($0) }
            let enc = Generator.encode(p)
            let dec = Generator.decode(enc, UInt8(n))
            XCTAssertEqual(p, dec)
        }
    }

    func testDecodeEncode() {
        let n = UInt8(5)
        for _s in 0 ..< n.factorial {
            let s = UInt64(_s)
            let seq = Generator.decode(s, UInt8(n))
            let enc = Generator.encode(seq)
            XCTAssertEqual(enc, s)
        }
    }
}
