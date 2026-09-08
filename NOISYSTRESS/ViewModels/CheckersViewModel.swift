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
final class CheckersViewModel {
    var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    var currentPlayer: Player = .white
    var aiDifficulty: DifficultyLevel = .medium {
        didSet {
            ai.updateDifficulty(to: aiDifficulty)
        }
    }
    var winner: Player? = nil
    
    var isGameOver: Bool {
        get { winner != nil }
        set { if !newValue { winner = nil } }
    }

    // Interaction state
    var selectedPosition: Position? = nil
    var validMoves: [Position] = []
    var lastMove: (from: Position, to: Position)? = nil

    // Multi-capture state
    private var mustCaptureWithPosition: Position? = nil

    private let ai = CheckersAI()
    private var aiTask: Task<Void, Never>?

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
        guard board[position.row][position.column] != nil else { return }

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
        winner = CheckersRules.checkForWinner(board: board, currentPlayer: currentPlayer)

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
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            // Simulate thinking time
            try? await Task.sleep(for: .seconds(0.5))

            guard !Task.isCancelled, let self, self.winner == nil, self.currentPlayer == .black else { return }

            guard let move = self.ai.bestMove(for: self.board, currentPlayer: self.currentPlayer) else {
                self.finishTurn()
                return
            }

            guard !Task.isCancelled, self.winner == nil, self.currentPlayer == .black else { return }
            self.performAIMoveSequence(move)
        }
    }

    private func performAIMoveSequence(_ move: CheckersMove) {
        // Execute the move
        let wasCapture = CheckersRules.executeStep(board: &board, move: move)
        lastMove = (move.from, move.to)

        if wasCapture {
            // Greedy follow-up: If AI made a capture, check if it can capture again.
            var currentPos = move.to
            while let piece = board[currentPos.row][currentPos.column],
                  CheckersRules.canCaptureAgain(board: board, piece: piece, from: currentPos) {

                // Find the capture move
                let nextMoves = CheckersRules.getValidMoves(board: board, player: currentPlayer)
                    .filter { $0.from == currentPos && CheckersRules.isCapture($0) }

                if let nextMove = nextMoves.first {
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
    }

    func setupBoard() {
        aiTask?.cancel()
        aiTask = nil

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
