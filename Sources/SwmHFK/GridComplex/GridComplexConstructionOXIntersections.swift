//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore

extension GridComplexConstruction {
    internal struct OXIntersectionTable {
        enum OX {
            case O, X
        }

        let table: [Rect: Info]
        
        init(_ G: GridDiagram) {
            let rects = Rect.allRects(forGridSize: G.gridSize)
            self.table = Dictionary(keys: rects) { r in
                Info(G, r)
            }
        }
        
        subscript(_ r: Rect) -> Info {
            table[r]!
        }
        
        struct Info {
            let length: UInt8
            let Ocode : Int
            let Ocount: Int
            let Xcode : Int
            let Xcount: Int
            
            init(_ G: GridDiagram, _ r: Rect) {
                self.length = G.gridNumber
                (self.Ocode, self.Ocount) = Self.encodeIntersections(r, G.Os)
                (self.Xcode, self.Xcount) = Self.encodeIntersections(r, G.Xs)
            }
            
            static func encodeIntersections(_ rect: Rect, _ points: [Point]) -> (code: Int, count: Int) { // binary flags
                points.enumerated().reduce(into: (0, 0)) { (res, e) in
                    let (i, p) = e
                    if rect.contains(p) {
                        res.0 |= (1 << i)
                        res.1 += 1
                    }
                }
            }
            
            func intersections(_ type: OX) -> [Int] {
                let code = (type == .O) ? Ocode : Xcode
                return (0 ..< length).map { i in
                    (code >> i) & 1
                }
            }
            
            func countIntersections(_ type: OX) -> Int {
                (type == .O) ? Ocount : Xcount
            }
            
            func intersects(_ type: OX) -> Bool {
                countIntersections(type) > 0
            }
            
            func intersects(_ type: OX, _ index: UInt8) -> Bool {
                let code = (type == .O) ? Ocode : Xcode
                return (code >> index) & 1 == 1
            }
        }
    }
}
