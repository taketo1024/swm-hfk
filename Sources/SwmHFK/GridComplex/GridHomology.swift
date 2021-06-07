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
        let construction = GridComplexConstruction(
            diagram: G,
            filter: { (_, j) in  j >= 0 }
        )
        let (r1, r2) = (construction.MaslovDegreeRange, construction.AlexanderDegreeRange)

        for j in r2.reversed() where j >= 0 {
            let restr = construction.filter{ (_, a) in a == j }
            let Cj = GridComplex(type: .tilde, construction: restr)
            let Hj = Cj.homology(options: .onlyStructures)
            
            for i in r1.reversed() {
                if !Hj[i].isZero {
                    return j
                }
            }
        }
        fatalError("impossible")
    }
}


