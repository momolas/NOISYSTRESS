//
//  BoardView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

struct BoardView: View {
    let viewModel: CheckersViewModel

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0..<8, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0..<8, id: \.self) { col in
                        let position = Position(row: row, column: col)
                        let isSelected = viewModel.selectedPosition == position
                        let isValidMove = viewModel.validMoves.contains(position)
                        let isLastMove = viewModel.lastMove?.from == position || viewModel.lastMove?.to == position

                        Button {
                            viewModel.handleTap(at: position)
                        } label: {
                            SquareView(piece: viewModel.board[row][col], position: position, isSelected: isSelected, isValidMove: isValidMove, isLastMove: isLastMove)
                        }
                        .buttonStyle(.plain)
					}
				}
			}
		}
		.clipShape(.rect(cornerRadius: 12))
		.overlay(
			RoundedRectangle(cornerRadius: 12)
				.stroke(Color.primary.opacity(0.15), lineWidth: 2)
		)
		.shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
		.padding(.horizontal)
	}
}

#Preview {
	BoardView(viewModel: CheckersViewModel())
}
