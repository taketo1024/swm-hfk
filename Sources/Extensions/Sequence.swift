//
//  Sequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal extension Sequence {
    func forAll(_ f: (Iterator.Element) -> Bool) -> Bool {
        for e in self {
            if !f(e) {
                return false
            }
        }
        return true
    }
    
    func exists(_ f: (Iterator.Element) -> Bool) -> Bool {
        for e in self {
            if f(e) {
                return true
            }
        }
        return false
    }
}
