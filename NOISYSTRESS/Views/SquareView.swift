//
//  SquareView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

struct SquareView: View {
	let piece: Piece?
	let position: Position
	let isSelected: Bool
	let isValidMove: Bool
	let isLastMove: Bool

	init(
		piece: Piece?,
		position: Position,
		isSelected: Bool,
		isValidMove: Bool = false,
		isLastMove: Bool = false
	) {
		self.piece = piece
		self.position = position
		self.isSelected = isSelected
		self.isValidMove = isValidMove
		self.isLastMove = isLastMove
	}

	private var isDarkSquare: Bool {
		(position.row + position.column) % 2 != 0
	}

	var body: some View {
		ZStack {
			// Alternance de couleurs pour le damier
			Rectangle()
				.foregroundStyle(isDarkSquare ? Color(white: 0.28) : Color(white: 0.88))
				.aspectRatio(1, contentMode: .fit)

			// Highlight last move
			if isLastMove {
				Rectangle()
					.foregroundStyle(Color.yellow.opacity(0.35))
			}

			// Highlight selected square
			if isSelected {
				Rectangle()
					.foregroundStyle(Color.blue.opacity(0.45))
			}

			// Highlight valid move
			if isValidMove {
				Circle()
					.foregroundStyle(Color.green.opacity(0.6))
					.padding(22)
			}

			if let piece = piece {
				ZStack {
					Circle()
						.foregroundStyle(piece.player == .white ? Color.white : Color(white: 0.12))
						.overlay(
							Circle()
								.stroke(piece.player == .white ? Color.gray.opacity(0.5) : Color.white.opacity(0.8), lineWidth: 2.5)
						)
						.shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

					if piece.type == .king {
						Image(systemName: "crown.fill")
							.font(.system(size: 16, weight: .bold))
							.foregroundStyle(piece.player == .white ? Color.orange : Color.yellow)
					}
				}
				.padding(8)
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilityText)
	}

	private var accessibilityText: String {
		var text = "Ligne \(position.row + 1), colonne \(position.column + 1)"
		if let piece = piece {
			let pieceKind = piece.type == .king ? "Dame" : "Pion"
			let color = piece.player == .white ? "blanc" : "noir"
			text += " : \(pieceKind) \(color)"
		} else {
			text += " : Vide"
		}
		if isSelected {
			text += ", sélectionnée"
		}
		if isValidMove {
			text += ", coup valide"
		}
		return text
	}
}

#Preview("Dame Blanche") {
	SquareView(
		piece: Piece(player: .white, type: .king, position: Position(row: 0, column: 1)),
		position: Position(row: 0, column: 1),
		isSelected: true
	)
	.frame(width: 80, height: 80)
}
