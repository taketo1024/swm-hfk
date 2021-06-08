//
//  GridHomology.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore
import SwmHomology

// TODO
public struct GridHomology {
    
    public static func genus(of G: GridDiagram) -> Int {
        let C = GridComplex(type: .tilde, diagram: G, filter: { (_, j) in j >= 1})
        let r1 = C.MaslovDegreeRange
        let r2 = C.AlexanderDegreeRange

        for j in r2.reversed() where j >= 0 {
            let Cj = C.filter{ (_, j1) in j1 == j }
            let Hj = Cj.homology(options: .onlyStructures)
            
            for i in r1.reversed() {
                if !Hj[i].isZero {
                    return j
                }
            }
        }
        return 0
    }
}


