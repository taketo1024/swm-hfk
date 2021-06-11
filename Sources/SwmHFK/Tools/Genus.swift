//
//  Genus.swift
//  
//
//  Created by Taketo Sano on 2021/06/09.
//

import SwmCore

extension GridHomology {
    // compute genus of G from GH-tilde.
    public static func genus(of G: GridDiagram) -> Int {
        let H = GridHomology(type: .tilde, diagram: G, filter: { (_, j) in j >= 1 })
        let r1 = H.MaslovDegreeRange
        let r2 = H.AlexanderDegreeRange

        for (j, i) in (r2.reversed() * r1.reversed()) {
            if !H[i, j].isZero {
                return j
            }
        }
        return 0
    }
}
