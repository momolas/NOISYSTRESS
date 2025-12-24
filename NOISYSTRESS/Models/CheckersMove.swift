//
//  CheckersMove.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import Foundation
import GameplayKit

class CheckersMove: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let from: Position
    let to: Position
    // For multi-step moves (optional usage for now, but good for future)
    let intermediates: [Position]

    init(from: Position, to: Position, intermediates: [Position] = []) {
        self.from = from
        self.to = to
        self.intermediates = intermediates
    }

    override var description: String {
        return "Move(\(from.row),\(from.column) -> \(to.row),\(to.column))"
    }
}
