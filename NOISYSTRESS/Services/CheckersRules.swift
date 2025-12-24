//
//  CheckersRules.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import Foundation

struct CheckersRules {

    // MARK: - API

    /// Returns all valid moves for the current player, enforcing forced captures.
    static func getValidMoves(board: [[Piece?]], player: Player) -> [CheckersMove] {
        var simpleMoves: [CheckersMove] = []
        var captureMoves: [CheckersMove] = []

        for r in 0..<8 {
            for c in 0..<8 {
                if let piece = board[r][c], piece.player == player {
                    let pos = Position(row: r, column: c)
                    let moves = getMovesForPiece(board: board, piece: piece, at: pos)

                    for move in moves {
                        if isCapture(move) {
                            captureMoves.append(move)
                        } else {
                            simpleMoves.append(move)
                        }
                    }
                }
            }
        }

        // Rule: If capture is available, you must capture.
        // Note: This function currently returns single-step moves.
        // Handling full chains requires more complex recursion which we can handle in the AI or ViewModel.
        // For strict rules, we should filter here.

        if !captureMoves.isEmpty {
            return captureMoves
        }
        return simpleMoves
    }

    /// Checks if a specific piece can capture again from a given position.
    static func canCaptureAgain(board: [[Piece?]], piece: Piece, from position: Position) -> Bool {
        let moves = getMovesForPiece(board: board, piece: piece, at: position)
        return moves.contains { isCapture($0) }
    }

    /// Executes a single step move. Returns true if it was a capture.
    static func executeStep(board: inout [[Piece?]], move: CheckersMove) -> Bool {
        guard var piece = board[move.from.row][move.from.column] else { return false }

        var captured = false

        // Handle Capture
        if isCapture(move) {
            let midRow = (move.from.row + move.to.row) / 2
            let midCol = (move.from.column + move.to.column) / 2
            board[midRow][midCol] = nil
            captured = true
        }

        // Move Piece
        board[move.from.row][move.from.column] = nil

        // Promotion
        if (piece.player == .white && move.to.row == 0) || (piece.player == .black && move.to.row == 7) {
            piece.type = .king
        }

        piece.position = move.to
        board[move.to.row][move.to.column] = piece

        return captured
    }

    static func checkForWinner(board: [[Piece?]]) -> Player? {
        let whiteCount = board.joined().compactMap { $0 }.filter { $0.player == .white }.count
        let blackCount = board.joined().compactMap { $0 }.filter { $0.player == .black }.count

        if whiteCount == 0 { return .black }
        if blackCount == 0 { return .white }

        // Check for blocked moves could be added here (if a player has pieces but no moves, they lose).
        // For now, simple piece count is good enough for basic implementation.
        return nil
    }

    // MARK: - Helpers

    private static func getMovesForPiece(board: [[Piece?]], piece: Piece, at position: Position) -> [CheckersMove] {
        var moves: [CheckersMove] = []
        let directions = piece.type == .king ? [(-1, -1), (-1, 1), (1, -1), (1, 1)] : (piece.player == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])

        for (rowOffset, colOffset) in directions {
            // Simple Move
            let simplePos = Position(row: position.row + rowOffset, column: position.column + colOffset)
            if isValidPosition(simplePos) && board[simplePos.row][simplePos.column] == nil {
                moves.append(CheckersMove(from: position, to: simplePos))
            }

            // Capture Move
            let jumpPos = Position(row: position.row + (rowOffset * 2), column: position.column + (colOffset * 2))
            let midPos = Position(row: position.row + rowOffset, column: position.column + colOffset)

            if isValidPosition(jumpPos) && board[jumpPos.row][jumpPos.column] == nil {
                if let midPiece = board[midPos.row][midPos.column], midPiece.player != piece.player {
                    moves.append(CheckersMove(from: position, to: jumpPos))
                }
            }
        }
        return moves
    }

    static func isCapture(_ move: CheckersMove) -> Bool {
        return abs(move.to.row - move.from.row) == 2
    }

    private static func isValidPosition(_ position: Position) -> Bool {
        return position.row >= 0 && position.row < 8 && position.column >= 0 && position.column < 8
    }
}
