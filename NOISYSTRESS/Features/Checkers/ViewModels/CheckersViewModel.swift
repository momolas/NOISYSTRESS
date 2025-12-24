//
//  CheckersViewModel.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI
import Observation

@MainActor
@Observable
class CheckersViewModel {
	var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
	var currentPlayer: Player = .white
	var aiDifficulty: DifficultyLevel = .medium

    // Will be used for move logic later
    var selectedPosition: Position? = nil

	init() {
		setupBoard()
	}

    func handleTap(at position: Position) {
        if let selected = selectedPosition {
            if selected == position {
                // Deselect if tapping the same piece
                selectedPosition = nil
            } else if let piece = board[position.row][position.column], piece.player == currentPlayer {
                // Change selection to another piece of the same player
                selectedPosition = position
            } else if board[position.row][position.column] == nil {
                // Attempt to move to an empty square
                if isValidMove(from: selected, to: position) {
                    movePiece(from: selected, to: position)
                    selectedPosition = nil
                    togglePlayer()
                }
            }
        } else {
            // Select a piece if it belongs to the current player
            if let piece = board[position.row][position.column], piece.player == currentPlayer {
                selectedPosition = position
            }
        }
    }

    private func isValidMove(from start: Position, to end: Position) -> Bool {
        // Basic validation: check bounds (implicit by array access but good to be safe if public)
        guard end.row >= 0 && end.row < 8 && end.column >= 0 && end.column < 8 else { return false }

        let rowDiff = end.row - start.row
        let colDiff = end.column - start.column

        // Must be diagonal by 1 column (for simple move)
        // TODO: Implement capture logic (jump over opponent)
        guard abs(colDiff) == 1 else { return false }

        guard let piece = board[start.row][start.column] else { return false }

        if piece.type == .king {
            // Kings can move up or down 1 step
            return abs(rowDiff) == 1
        } else {
            // Normal pieces move forward only
            if piece.player == .white {
                return rowDiff == -1 // White moves up (decreasing indices)
            } else {
                return rowDiff == 1 // Black moves down (increasing indices)
            }
        }
    }

    private func movePiece(from start: Position, to end: Position) {
        guard var piece = board[start.row][start.column] else { return }

        // Remove from old position
        board[start.row][start.column] = nil

        // Check for King promotion
        if (piece.player == .white && end.row == 0) || (piece.player == .black && end.row == 7) {
            piece.type = .king
        }

        // Update position in piece struct
        piece.position = end

        // Place at new position
        board[end.row][end.column] = piece
    }

    private func togglePlayer() {
        currentPlayer = (currentPlayer == .white) ? .black : .white
    }

	func setDifficulty(_ difficulty: DifficultyLevel) {
		aiDifficulty = difficulty
	}

	func setupBoard() {
		// Clear board
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        selectedPosition = nil
        currentPlayer = .white

		// Initialisation des pièces : les blanches en bas et les noires en haut.
		for row in 5..<8 {
			for col in 0..<8 where (row + col) % 2 == 1 {
				board[row][col] = Piece(player: .white, type: .normal, position: Position(row: row, column: col))
			}
		}

		for row in 0..<3 {
			for col in 0..<8 where (row + col) % 2 == 1 {
				board[row][col] = Piece(player: .black, type: .normal, position: Position(row: row, column: col))
			}
		}
	}
}
