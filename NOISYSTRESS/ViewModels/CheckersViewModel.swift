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
    var winner: Player? = nil

    // Interaction state
    var selectedPosition: Position? = nil
    var validMoves: [Position] = []
    var lastMove: (from: Position, to: Position)? = nil

    // Multi-capture state
    private var mustCaptureWithPosition: Position? = nil

    private let ai = CheckersAI()

    init() {
        setupBoard()
    }

    func handleTap(at position: Position) {
        // Prevent player from moving if it's AI's turn or game over
        guard currentPlayer == .white, winner == nil else { return }

        // If in multi-capture sequence, can only select the active piece
        if let requiredPos = mustCaptureWithPosition {
            if position == requiredPos {
                selectPiece(at: position)
            }
            return
        }

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
                    performMove(from: selected, to: position)
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

        // Get all legal moves for the player (global context)
        let allMoves = CheckersRules.getValidMoves(board: board, player: currentPlayer)

        // Filter moves for this specific piece
        let pieceMoves = allMoves.filter { $0.from == position }

        // Populate valid targets
        validMoves = pieceMoves.map { $0.to }

        // Visual aid: if this piece has no moves but others do (forced capture elsewhere), validMoves is empty.
        // The Rules engine ensures that if ANY capture is available, `allMoves` ONLY contains captures.
        // So if this piece can't capture but another can, this piece is effectively locked.
    }

    private func performMove(from start: Position, to end: Position) {
        let move = CheckersMove(from: start, to: end)
        let wasCapture = CheckersRules.executeStep(board: &board, move: move)

        lastMove = (start, end)
        deselectPiece()

        if wasCapture {
             // Check if the moved piece can capture again
            if let piece = board[end.row][end.column], CheckersRules.canCaptureAgain(board: board, piece: piece, from: end) {
                // Continue turn
                mustCaptureWithPosition = end
                selectPiece(at: end) // Auto-select for convenience
                return
            }
        }

        finishTurn()
    }

    private func finishTurn() {
        mustCaptureWithPosition = nil
        winner = CheckersRules.checkForWinner(board: board)

        if winner == nil {
            togglePlayer()
        }
    }

    private func togglePlayer() {
        currentPlayer = (currentPlayer == .white) ? .black : .white

        if currentPlayer == .black {
            makeAIMove()
        }
    }

    private func makeAIMove() {
        Task.detached(priority: .userInitiated) { [weak self, board = self.board, currentPlayer = self.currentPlayer, ai = self.ai] in
            // Simulate thinking time
            try? await Task.sleep(for: .seconds(0.5))

            // CheckersRules is used inside AI, but here we just need the move
            guard let move = ai.bestMove(for: board, currentPlayer: currentPlayer) else {
                await MainActor.run {
                    self?.finishTurn() // No moves? pass turn or lose. (Rules engine should handle no moves = loss ideally)
                }
                return
            }

            await MainActor.run {
                self?.performAIMoveSequence(move)
            }
        }
    }

    private func performAIMoveSequence(_ move: CheckersMove) {
        // AI returns a "best move". Ideally if it's a multi-jump, CheckersAI should return the full sequence.
        // Currently CheckersAI returns single steps OR assumes GameplayKit handles state.
        // If we want AI to do multi-jumps, we need to loop here.

        var currentMove = move
        var keepGoing = true

        // Execute the first move
        let wasCapture = CheckersRules.executeStep(board: &board, move: currentMove)
        lastMove = (currentMove.from, currentMove.to)

        if wasCapture {
             // Greedy follow-up: If AI made a capture, check if it can capture again.
             // Ideally AI should have planned this. For now, we force a greedy follow-up
             // using the same logic as human (pick any valid capture).
             // Since AI returned a single step, we have to find the next step ourselves.

            var currentPos = currentMove.to
            while let piece = board[currentPos.row][currentPos.column],
                  CheckersRules.canCaptureAgain(board: board, piece: piece, from: currentPos) {

                // Find the capture move
                let nextMoves = CheckersRules.getValidMoves(board: board, player: currentPlayer)
                    .filter { $0.from == currentPos && CheckersRules.isCapture($0) }

                if let nextMove = nextMoves.first {
                    // Small delay for visual effect
                    // Note: blocking main thread is bad, but we are in a async context? No, we are on MainActor.
                    // Ideally we should use a Task/Timer.
                    // For simplicity, we just execute immediately.

                    _ = CheckersRules.executeStep(board: &board, move: nextMove)
                    lastMove = (nextMove.from, nextMove.to)
                    currentPos = nextMove.to
                } else {
                    break
                }
            }
        }

        finishTurn()
    }

    func setDifficulty(_ difficulty: DifficultyLevel) {
        aiDifficulty = difficulty
        ai.updateDifficulty(to: difficulty)
    }

    func setupBoard() {
        // Clear board
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        selectedPosition = nil
        currentPlayer = .white
        winner = nil
        mustCaptureWithPosition = nil
        lastMove = nil

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
