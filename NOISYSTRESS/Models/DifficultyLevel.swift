//
//  DifficultyLevel.swift
//  NOISYSTRESS
//
//  Created by Mo on 19/11/2024.
//

import Foundation

enum DifficultyLevel: Int, Sendable, CaseIterable, Identifiable {
	case easy = 1
	case medium = 3
	case hard = 5
	
	var id: Int { rawValue }
	
	var title: String {
		switch self {
		case .easy: "Facile"
		case .medium: "Normal"
		case .hard: "Difficile"
		}
	}
}
