//
//  CheckersAI.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import Foundation
import GameplayKit

// MARK: - Checkers Player
class CheckersPlayer: NSObject, GKGameModelPlayer {
    var playerId: Int
    let player: Player

    init(player: Player) {
        self.player = player
        self.playerId = (player == .white) ? 0 : 1
        super.init()
    }
}

// MARK: - Checkers Game Model
class CheckersGameModel: NSObject, GKGameModel {
    var board: [[Piece?]]
    var currentPlayer: Player
    var players: [GKGameModelPlayer]?
    var activePlayer: GKGameModelPlayer? {
        return players?.first(where: { ($0 as? CheckersPlayer)?.player == currentPlayer })
    }

    init(board: [[Piece?]], currentPlayer: Player) {
        self.board = board
        self.currentPlayer = currentPlayer
        self.players = [CheckersPlayer(player: .white), CheckersPlayer(player: .black)]
    }

    // MARK: - GKGameModel Protocol

    func setGameModel(_ gameModel: GKGameModel) {
        if let model = gameModel as? CheckersGameModel {
            self.board = model.board
            self.currentPlayer = model.currentPlayer
        }
    }

    func isWin(for player: GKGameModelPlayer) -> Bool {
        guard let p = player as? CheckersPlayer else { return false }
        return CheckersRules.checkForWinner(board: board) == p.player
    }

    func isLoss(for player: GKGameModelPlayer) -> Bool {
        guard let p = player as? CheckersPlayer else { return false }
        let winner = CheckersRules.checkForWinner(board: board)
        return winner != nil && winner != p.player
    }

    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard let p = player as? CheckersPlayer else { return nil }

        // Use CheckersRules to get valid moves
        // Note: This returns valid *first steps*. GameplayKit will evaluate the resulting board.
        // If a move is a multi-jump, the resulting board state should reflect the FULL turn.
        // However, standard GKMinmax works step-by-step if the player doesn't change.
        // For simplicity with this integration, we expose single steps.
        // The ViewModel "Greedy Follow-up" handles the visual chain.
        // Ideally, we would simulate the full chain here.

        let moves = CheckersRules.getValidMoves(board: board, player: p.player)
        return moves.isEmpty ? nil : moves
    }

    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let move = gameModelUpdate as? CheckersMove else { return }

        // Execute the move step
        let wasCapture = CheckersRules.executeStep(board: &board, move: move)

        // Handle Multi-Jump Logic for AI Simulation
        // If capture, and can capture again, we must execute those too (Greedy approach for simulation)
        if wasCapture {
            var currentPos = move.to
            while let piece = board[currentPos.row][currentPos.column],
                  CheckersRules.canCaptureAgain(board: board, piece: piece, from: currentPos) {

                let nextMoves = CheckersRules.getValidMoves(board: board, player: currentPlayer)
                    .filter { $0.from == currentPos && CheckersRules.isCapture($0) }

                if let nextMove = nextMoves.first {
                    _ = CheckersRules.executeStep(board: &board, move: nextMove)
                    currentPos = nextMove.to
                } else {
                    break
                }
            }
        }

        // Switch turn
        currentPlayer = (currentPlayer == .white) ? .black : .white
    }

    func score(for player: GKGameModelPlayer) -> Int {
        guard let p = player as? CheckersPlayer else { return 0 }

        var score = 0
        for r in 0..<8 {
            for c in 0..<8 {
                if let piece = board[r][c] {
                    let value = (piece.type == .king) ? 5 : 1
                    if piece.player == p.player {
                        score += value
                    } else {
                        score -= value
                    }
                }
            }
        }
        return score
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CheckersGameModel(board: self.board, currentPlayer: self.currentPlayer)
        return copy
    }
}

// MARK: - Checkers AI
class CheckersAI {
    let strategist: GKMinmaxStrategist
    var difficulty: DifficultyLevel

    init(difficulty: DifficultyLevel = .medium) {
        self.difficulty = difficulty
        self.strategist = GKMinmaxStrategist()
        self.strategist.randomSource = GKARC4RandomSource()
        updateDifficulty(to: difficulty)
    }

    func updateDifficulty(to newDifficulty: DifficultyLevel) {
        self.difficulty = newDifficulty
        self.strategist.maxLookAheadDepth = difficulty.rawValue
    }

    func bestMove(for board: [[Piece?]], currentPlayer: Player) -> CheckersMove? {
        let model = CheckersGameModel(board: board, currentPlayer: currentPlayer)
        strategist.gameModel = model

        if let move = strategist.bestMove(for: model.activePlayer!) as? CheckersMove {
            return move
        }
        return nil
    }
}
