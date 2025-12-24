//
//  BoardView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

struct BoardView: View {
    @Bindable var viewModel: CheckersViewModel

	var body: some View {
		VStack(spacing: 0) {
			ForEach(0..<8, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0..<8, id: \.self) { col in
                        let position = Position(row: row, column: col)
                        let isSelected = viewModel.selectedPosition == position
                        let isValidMove = viewModel.validMoves.contains(position)

                        Button {
                            viewModel.handleTap(at: position)
                        } label: {
                            SquareView(piece: viewModel.board[row][col], position: position, isSelected: isSelected, isValidMove: isValidMove)
                        }
                        .buttonStyle(.plain)
					}
				}
			}
		}
		.border(Color.black, width: 2)
	}
}
