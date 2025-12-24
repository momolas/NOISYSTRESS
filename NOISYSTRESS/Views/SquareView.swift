//
//  SquareView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

struct SquareView: View {
	var piece: Piece?
	var position: Position
    var isSelected: Bool
    var isValidMove: Bool = false

	var body: some View {
		ZStack {
			// Alternance de couleurs pour le damier
			Rectangle()
                .foregroundStyle((position.row + position.column) % 2 == 0 ? .white : .black)
				.aspectRatio(1, contentMode: .fit)

            // Highlight selected square
            if isSelected {
                Rectangle()
                    .foregroundStyle(Color.blue.opacity(0.5))
            }

            // Highlight valid move
            if isValidMove {
                Circle()
                    .foregroundStyle(Color.green.opacity(0.5))
                    .padding(20)
            }

			if let piece = piece {
				Circle()
                    .foregroundStyle(piece.player == .white ? .white : .black) // Remplissage
					.overlay(
						Circle()
							.stroke(Color.white, lineWidth: 3) // Contour
					)
					.padding(10)
			}
		}
	}
}
