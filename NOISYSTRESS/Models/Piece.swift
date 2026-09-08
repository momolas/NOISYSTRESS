//
//  Piece.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import Foundation

struct Piece: Sendable, Equatable {
	let player: Player
	var type: PieceType
	var position: Position
}
