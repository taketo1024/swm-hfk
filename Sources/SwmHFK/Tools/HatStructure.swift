//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/09.
//

import SwmCore

extension GridHomology {
    
    // compute GH-hat structure from GH-tilde, using:
    //  1) GH-tilde = GH-hat ⊗ W^{⊗(n - 1)}, W = F ⊕ F[-1, -1]   (4.19)
    //  2) GH-hat[i, j] = GH-hat[i - 2j, -j]                     (Prop 7.1.1)
    
    public static func hatStructure(of G: GridDiagram) -> [MultiIndex<_2>: Int] {
        let n = Int(G.gridNumber)
        let H = GridHomology(type: .tilde, diagram: G, filter: { (_, j) in j >= 0 })
        var result = H.structure().mapValues{ $0.rank }
        
        let targets = result.keys
            .filter{ d in d[1] > 0 }
            .sorted{ d in d[1] }
            .reversed()
        
        // 1) subtract ranks inflated by W.
        for d in targets {
            let j = d[1]
            let r = result[d]!
            
            for k in 1 ... j {
                let b = binomial(n - 1, k)
                result[d - [k, k]]! -= b * r
            }
        }
        assert(result.values.allSatisfy{ $0 > 0 })
        
        result = result.exclude{ (_, r) in r == 0 }
        
        // 2) copy ranks into j < 0.
        for d in result.keys where d[1] > 0 {
            let (i, j) = d.tuple
            let md = MultiIndex<_2>(i - 2 * j, -j)
            result[md] = result[d]!
        }
        
        return result
    }
    
    static func binomial(_ n: Int, _ k: Int) -> Int {
      var result = 1
      for i in 0 ..< k {
        result *= (n - i)
        result /= (i + 1)
      }
      return result
    }
}
