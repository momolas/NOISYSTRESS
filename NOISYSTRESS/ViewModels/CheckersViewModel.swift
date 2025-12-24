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
    var validMoves: [Position] = []

	init() {
		setupBoard()
	}

    func handleTap(at position: Position) {
        if let selected = selectedPosition {
            if selected == position {
                // Deselect if tapping the same piece
                deselectPiece()
            } else if let piece = board[position.row][position.column], piece.player == currentPlayer {
                // Change selection to another piece of the same player
                selectPiece(at: position)
            } else if board[position.row][position.column] == nil {
                // Attempt to move to an empty square
                if validMoves.contains(position) {
                    movePiece(from: selected, to: position)
                    deselectPiece()
                    togglePlayer()
                }
            }
        } else {
            // Select a piece if it belongs to the current player
            if let piece = board[position.row][position.column], piece.player == currentPlayer {
                selectPiece(at: position)
            }
        }
    }

    private func selectPiece(at position: Position) {
        selectedPosition = position
        calculateValidMoves(for: position)
    }

    private func deselectPiece() {
        selectedPosition = nil
        validMoves = []
    }

    private func calculateValidMoves(for position: Position) {
        validMoves = []
        guard let piece = board[position.row][position.column] else { return }

        let directions = piece.type == .king ? [(-1, -1), (-1, 1), (1, -1), (1, 1)] : (piece.player == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])

        for (rowOffset, colOffset) in directions {
            // Check simple move
            let simpleMove = Position(row: position.row + rowOffset, column: position.column + colOffset)
            if isValidPosition(simpleMove) && board[simpleMove.row][simpleMove.column] == nil {
                validMoves.append(simpleMove)
            }

            // Check capture move
            let jumpMove = Position(row: position.row + (rowOffset * 2), column: position.column + (colOffset * 2))
            let midPos = Position(row: position.row + rowOffset, column: position.column + colOffset)

            if isValidPosition(jumpMove) && board[jumpMove.row][jumpMove.column] == nil {
                if let midPiece = board[midPos.row][midPos.column], midPiece.player != piece.player {
                    validMoves.append(jumpMove)
                }
            }
        }
    }

    private func isValidPosition(_ position: Position) -> Bool {
        return position.row >= 0 && position.row < 8 && position.column >= 0 && position.column < 8
    }

    private func movePiece(from start: Position, to end: Position) {
        guard var piece = board[start.row][start.column] else { return }

        // Handle Capture
        let rowDiff = end.row - start.row
        if abs(rowDiff) == 2 {
            let capturedRow = start.row + (rowDiff / 2)
            let capturedCol = start.column + (end.column - start.column) / 2
            board[capturedRow][capturedCol] = nil
        }

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
