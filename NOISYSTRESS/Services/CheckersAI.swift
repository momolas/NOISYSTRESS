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

// MARK: - Checkers Move
class CheckersMove: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let from: Position
    let to: Position

    init(from: Position, to: Position) {
        self.from = from
        self.to = to
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
        let opponentColor: Player = (p.player == .white) ? .black : .white
        let opponentPiecesCount = board.joined().compactMap { $0 }.filter { $0.player == opponentColor }.count
        return opponentPiecesCount == 0
    }

    func isLoss(for player: GKGameModelPlayer) -> Bool {
        guard let p = player as? CheckersPlayer else { return false }
        let myPiecesCount = board.joined().compactMap { $0 }.filter { $0.player == p.player }.count
        return myPiecesCount == 0
    }

    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard let p = player as? CheckersPlayer else { return nil }
        var moves: [CheckersMove] = []

        // Find all pieces for the player
        for r in 0..<8 {
            for c in 0..<8 {
                if let piece = board[r][c], piece.player == p.player {
                    let from = Position(row: r, column: c)
                    let validMoves = getValidMoves(for: piece, at: from)
                    moves.append(contentsOf: validMoves)
                }
            }
        }

        // Checkers rule: Forced capture?
        // If there are any capture moves, filter only those.
        let captureMoves = moves.filter { isCapture(from: $0.from, to: $0.to) }
        if !captureMoves.isEmpty {
            return captureMoves
        }

        return moves.isEmpty ? nil : moves
    }

    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let move = gameModelUpdate as? CheckersMove else { return }

        executeMove(from: move.from, to: move.to)

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

    // MARK: - Helpers

    private func getValidMoves(for piece: Piece, at position: Position) -> [CheckersMove] {
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

    private func isValidPosition(_ position: Position) -> Bool {
        return position.row >= 0 && position.row < 8 && position.column >= 0 && position.column < 8
    }

    private func isCapture(from: Position, to: Position) -> Bool {
        return abs(to.row - from.row) == 2
    }

    private func executeMove(from: Position, to: Position) {
        guard var piece = board[from.row][from.column] else { return }

        // Handle Capture
        if isCapture(from: from, to: to) {
            let midRow = (from.row + to.row) / 2
            let midCol = (from.column + to.column) / 2
            board[midRow][midCol] = nil
        }

        board[from.row][from.column] = nil

        // Promotion
        if (piece.player == .white && to.row == 0) || (piece.player == .black && to.row == 7) {
            piece.type = .king
        }

        piece.position = to
        board[to.row][to.column] = piece
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
