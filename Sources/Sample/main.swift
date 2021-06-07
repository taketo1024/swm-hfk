//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/06.
//

import SwmCore
import SwmHFK

let G = GridDiagram.load("8_1")!
Debug.measure("prepare generators") {
    let constr = GridComplexConstruction(diagram: G)
    print("#generators =", constr.numberOfGenerators)
}

//let C = GridComplex(type: .tilde, diagram: G)
//let B = C.bigraded
//let (r1, r2) = (C.generators.MaslovDegreeRange, C.generators.AlexanderDegreeRange)
//
//print(Format.table(rows: r2.reversed().filter{ $0 >= 0 }, cols: r1.reversed()) { (j, i) in
//    B[i, j].rank
//})
//Debug.measure("calculate homology") {
//    let H = B.homology(options: .onlyStructures)
//    for (j, i) in r2.reversed() * r1.reversed() where j >= 0 {
//        let r = H[i, j].rank
//        if !r.isZero {
//            print((i, j), ":", r)
//        }
//    }
//}
