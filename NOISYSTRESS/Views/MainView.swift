//
//  MainView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

struct MainView: View {
	@State private var viewModel = CheckersViewModel()

	var body: some View {
		@Bindable var bindableViewModel = viewModel

		NavigationStack {
			VStack(spacing: 16) {
				SettingsView(selectedDifficulty: $bindableViewModel.aiDifficulty)
				
				HStack {
					Circle()
						.foregroundStyle(viewModel.currentPlayer == .white ? Color.white : Color.black)
						.frame(width: 14, height: 14)
						.overlay(Circle().stroke(Color.gray, lineWidth: 1.5))
					
					Text(viewModel.currentPlayer == .white ? "À votre tour (Blancs)" : "L'IA réfléchit (Noirs)...")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.padding(.top, 4)

				Spacer()
				BoardView(viewModel: viewModel)
				Spacer()

				Button("Nouvelle partie", systemImage: "arrow.counterclockwise") {
					viewModel.setupBoard()
				}
				.buttonStyle(.borderedProminent)
				.padding(.bottom)
			}
			.navigationTitle("Dames")
			.toolbarTitleDisplayMode(.inline)
			.alert("Partie terminée", isPresented: $bindableViewModel.isGameOver) {
				Button("Rejouer") {
					viewModel.setupBoard()
				}
			} message: {
				if let winner = viewModel.winner {
					Text(winner == .white ? "Félicitations, vous avez gagné !" : "L'IA a gagné la partie !")
				}
			}
			.sensoryFeedback(.success, trigger: viewModel.winner != nil) { _, isWon in
				isWon
			}
			.sensoryFeedback(.selection, trigger: viewModel.selectedPosition)
			.sensoryFeedback(.impact(weight: .light), trigger: viewModel.aiDifficulty)
		}
	}
}

#Preview {
	MainView()
}
