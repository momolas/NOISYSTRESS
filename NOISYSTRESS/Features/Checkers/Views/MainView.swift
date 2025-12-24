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
		NavigationStack {
			VStack {
				SettingsView(selectedDifficulty: $viewModel.aiDifficulty)
				Spacer()
				BoardView(viewModel: viewModel)
				Spacer()
                Button("Restart Game") {
                    viewModel.setupBoard()
                }
                .buttonStyle(.borderedProminent)
                .padding()
			}
            .navigationTitle("Checkers")
		}
	}
}
