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
				ForEach(DifficultyLevel.allCases) { level in
					Text(level.title).tag(level)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal)
		}
	}
}

#Preview {
	@Previewable @State var difficulty: DifficultyLevel = .medium
	SettingsView(selectedDifficulty: $difficulty)
}
