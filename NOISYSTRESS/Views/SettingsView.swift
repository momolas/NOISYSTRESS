//
//  SettingsView.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import SwiftUI

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
			.pickerStyle(.segmented)
			.padding()
		}
	}
}
