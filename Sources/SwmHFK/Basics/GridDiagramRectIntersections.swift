//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/06/07.
//

import SwmCore

extension GridDiagram {
    private var allRects: [Rect] {
        ((0 ..< gridNumber) * (0 ..< gridNumber)).flatMap { (x, y) -> [Rect] in
            ((0 ..< gridNumber) * (0 ..< gridNumber)).map { (w, h) -> Rect in
                Rect(
                    origin: Point(2 * x, 2 * y),
                    size: Point(2 * w, 2 * h),
                    gridSize: gridSize
                )
            }
        }
    }
    
    public var intersectionTable: OXIntersectionTable {
        OXIntersectionTable(self)
    }

    public struct OXIntersectionTable {
        private let table: [Rect: Info]
        
        fileprivate init(_ diagram: GridDiagram) {
            let rects = diagram.allRects
            self.table = Dictionary(keys: rects) { rect in
                Info(rect, diagram.Os, diagram.Xs)
            }
        }
        
        public subscript(_ r: Rect) -> Info {
            table[r]!
        }
        
        public struct Info {
            let length: Int
            let Ocode : Int
            let Ocount: Int
            let Xcode : Int
            let Xcount: Int
            
            fileprivate init(_ r: Rect, _ Os: [Point], _ Xs: [Point]) {
                self.length = Os.count
                (self.Ocode, self.Ocount) = Self.encodeIntersections(r, Os)
                (self.Xcode, self.Xcount) = Self.encodeIntersections(r, Xs)
            }
            
            private static func encodeIntersections(_ rect: Rect, _ points: [Point]) -> (code: Int, count: Int) { // binary flags
                points.enumerated().reduce(into: (0, 0)) { (res, e) in
                    let (i, p) = e
                    if rect.contains(p) {
                        res.0 |= (1 << i)
                        res.1 += 1
                    }
                }
            }
            
            func intersections(_ type: GridDiagram.OX) -> [Int] {
                let code = (type == .O) ? Ocode : Xcode
                return (0 ..< length).map { i in
                    (code >> i) & 1
                }
            }
            
            func countIntersections(_ type: GridDiagram.OX) -> Int {
                (type == .O) ? Ocount : Xcount
            }
            
            func intersects(_ type: GridDiagram.OX) -> Bool {
                countIntersections(type) > 0
            }
            
            func intersects(_ type: GridDiagram.OX, _ index: Int) -> Bool {
                let code = (type == .O) ? Ocode : Xcode
                return (code >> index) & 1 == 1
            }
        }
    }
}
