//
//  ContentView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

enum Player: String {
	case white = "White"
	case black = "Black"
}

enum PieceType {
	case normal
	case king
}

enum DifficultyLevel: Int {
	case easy = 1
	case medium = 3
	case hard = 5
}

struct Piece {
	let player: Player
	var type: PieceType
	var position: Position
}

struct Position: Hashable {
	let row: Int
	let column: Int
}

class CheckersViewModel: ObservableObject {
	@Published var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
	@Published var currentPlayer: Player = .white
	@Published var aiDifficulty: DifficultyLevel = .medium
//	var ai: CheckersAI
	
	init() {
		setupBoard()
//		ai = CheckersAI(difficulty: aiDifficulty)
	}
	
	func setDifficulty(_ difficulty: DifficultyLevel) {
		aiDifficulty = difficulty
//		ai.updateDifficulty(to: difficulty)
	}
	
	func setupBoard() {
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

struct MainView: View {
	@StateObject private var viewModel = CheckersViewModel()
	
	var body: some View {
		NavigationView {
			VStack {
				SettingsView(selectedDifficulty: $viewModel.aiDifficulty)
				Spacer()
				BoardView(viewModel: viewModel)
				Spacer()
				// Ajoute un bouton pour commencer la partie
			}
		}
	}
}

struct BoardView: View {
	@ObservedObject var viewModel: CheckersViewModel
	
	var body: some View {
		VStack(spacing: 0) {
			ForEach(0..<8, id: \.self) { row in
				HStack(spacing: 0) {
					ForEach(0..<8, id: \.self) { col in
						SquareView(piece: viewModel.board[row][col], position: Position(row: row, column: col))
							.onTapGesture {
								// Gérer les interactions (mouvement, sélection).
							}
					}
				}
			}
		}
		.border(Color.black, width: 2)
	}
}

struct SquareView: View {
	var piece: Piece?
	var position: Position
	
	var body: some View {
		ZStack {
			// Alternance de couleurs pour le damier
			Rectangle()
				.foregroundColor((position.row + position.column) % 2 == 0 ? .white : .black)
				.aspectRatio(1, contentMode: .fit)
			
			if let piece = piece {
				Circle()
					.foregroundColor(piece.player == .white ? .white : .black) // Remplissage
					.overlay(
						Circle()
							.stroke(Color.white, lineWidth: 3) // Contour
					)
					.padding(10)
			}
		}
	}
}

struct SettingsView: View {
	@Binding var selectedDifficulty: DifficultyLevel
	
	var body: some View {
		VStack {
			Text("Niveau")
				.font(.headline)
			
			Picker("Niveau", selection: $selectedDifficulty) {
				Text("Facile").tag(DifficultyLevel.easy)
				Text("Normal").tag(DifficultyLevel.medium)
				Text("Difficile").tag(DifficultyLevel.hard)
			}
			.pickerStyle(SegmentedPickerStyle())
			.padding()
		}
	}
}

//import GameplayKit
//
//class CheckersAI {
//	let strategist: GKMinmaxStrategist
//	var difficulty: DifficultyLevel
//	
//	init(difficulty: DifficultyLevel) {
//		self.difficulty = difficulty
//		self.strategist = GKMinmaxStrategist()
//		configureStrategist()
//	}
//	
//	private func configureStrategist() {
//		strategist.maxLookAheadDepth = difficulty.rawValue
//		strategist.randomSource = GKARC4RandomSource()
//	}
//	
//	func updateDifficulty(to newDifficulty: DifficultyLevel) {
//		self.difficulty = newDifficulty
//		configureStrategist()
//	}
//	
//	func bestMove(for board: [[Piece?]], currentPlayer: Player) -> CheckersMove? {
//		let gameModel = CheckersGameModel(board: board, currentPlayer: currentPlayer)
//		strategist.gameModel = gameModel
//		
//		// Utilisation de GameplayKit pour récupérer les mouvements possibles
//		if let moves = strategist.gameModel?.gameModelUpdates(for: gameModel.currentPlayer) as? [CheckersMove] {
//			// Sélectionner le meilleur mouvement basé sur le score (ou autre critère)
//			return moves.max { $0.score < $1.score }
//		}
//		return nil  // Aucun mouvement valide trouvé
//	}
//}
//
//class CheckersMove: GKGameModelUpdate {
//	var score: Int = 0
//	var from: Position
//	var to: Position
//	
//	init(from: Position, to: Position) {
//		self.from = from
//		self.to = to
//	}
//}
//
//class CheckersGameModel: GKGameModel {
//	var board: [[Piece?]]
//	var currentPlayer: Player
//	
//	init(board: [[Piece?]], currentPlayer: Player) {
//		self.board = board
//		self.currentPlayer = currentPlayer
//	}
//	
//	// Retourne les mises à jour possibles du modèle pour un joueur donné
//	override func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
//		var moves: [CheckersMove] = []
//		
//		// Exemple : générer les mouvements possibles pour chaque pièce
//		for row in 0..<8 {
//			for col in 0..<8 {
//				if let piece = board[row][col], piece.player == player {
//					let possibleMoves = getPossibleMoves(from: Position(row: row, column: col))
//					for move in possibleMoves {
//						let checkersMove = CheckersMove(from: Position(row: row, column: col), to: move)
//						moves.append(checkersMove)
//					}
//				}
//			}
//		}
//		return moves
//	}
//	
//	// Applique un mouvement au modèle de jeu
//	override func apply(_ gameModelUpdate: GKGameModelUpdate) {
//		guard let move = gameModelUpdate as? CheckersMove else { return }
//		
//		// Appliquer le mouvement (mettre à jour la position de la pièce)
//		board[move.from.row][move.from.column] = nil
//		board[move.to.row][move.to.column] = Piece(player: currentPlayer, type: .normal, position: move.to)
//	}
//	
//	// Retourne le joueur actuel (utile pour GameplayKit)
//	override var players: [GKGameModelPlayer]? {
//		return [currentPlayer]
//	}
//	
//	// Vérifie l'égalité entre deux modèles de jeu
//	override func isEqual(to model: GKGameModel) -> Bool {
//		guard let other = model as? CheckersGameModel else { return false }
//		return self.board == other.board && self.currentPlayer == other.currentPlayer
//	}
//	
//	// Récupère les mouvements possibles à partir d'une position donnée
//	func getPossibleMoves(from position: Position) -> [Position] {
//		var possibleMoves: [Position] = []
//		
//		// Exemple de mouvement de base : déplacement en diagonale
//		let directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
//		for direction in directions {
//			let newRow = position.row + direction.0
//			let newCol = position.column + direction.1
//			if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
//				possibleMoves.append(Position(row: newRow, column: newCol))
//			}
//		}
//		
//		return possibleMoves
//	}
//}

#Preview {
	MainView()
}
