//
//  Pet.swift
//  StepPet
//

import Foundation
import SwiftUI

// MARK: - Pet Type
enum PetType: String, CaseIterable, Codable {
    case dog = "Dog"
    case cat = "Cat"
    case bunny = "Bunny"
    case hamster = "Hamster"
    case horse = "Horse"
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐱"
        case .bunny: return "🐰"
        case .hamster: return "🐹"
        case .horse: return "🐴"
        }
    }
    
    var personality: String {
        switch self {
        case .dog: return "Loyal, eager, classic choice"
        case .cat: return "Sassy, judges you for being lazy"
        case .bunny: return "Soft, gentle, hops when happy"
        case .hamster: return "Small, energetic, runs on wheel"
        case .horse: return "Majestic, strong, adventure-ready"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .cat: return false // Cat is free (main pet)
        case .dog, .bunny, .hamster, .horse: return true
        }
    }
    
    // Get the image name for a specific mood state
    func imageName(for state: PetMoodState) -> String {
        let petName = rawValue.lowercased()
        let stateName = state.rawValue.lowercased()
        return "\(petName)\(stateName)"
    }
    
    // Get the GIF animation name for a specific mood state
    func gifName(for state: PetMoodState, isDarkMode: Bool) -> String {
        let petName = rawValue.capitalized
        let stateName = state.displayName.replacingOccurrences(of: " ", with: "")
        let prefix = isDarkMode ? "Dark" : ""
        return "\(prefix)\(petName)\(stateName)Animation"
    }
    
    // Get the MP4 video name for a specific mood state
    func videoName(for state: PetMoodState, isDarkMode: Bool) -> String {
        let petName = rawValue.capitalized
        let stateName = state.displayName.replacingOccurrences(of: " ", with: "")
        let prefix = isDarkMode ? "Dark" : ""
        return "\(prefix)\(petName)\(stateName)Animation"
    }
}

// MARK: - Pet Mood State
enum PetMoodState: String, CaseIterable, Codable {
    case sick = "sick"
    case sad = "sad"
    case content = "content"
    case happy = "happy"
    case fullHealth = "fullhealth"
    
    var displayName: String {
        switch self {
        case .sick: return "Sick"
        case .sad: return "Sad"
        case .content: return "Content"
        case .happy: return "Happy"
        case .fullHealth: return "FullHealth"
        }
    }
    
    var healthRange: ClosedRange<Int> {
        switch self {
        case .sick: return 0...20
        case .sad: return 21...40
        case .content: return 41...60
        case .happy: return 61...80
        case .fullHealth: return 81...100
        }
    }
    
    var emoji: String {
        switch self {
        case .sick: return "🤒"
        case .sad: return "😢"
        case .content: return "😊"
        case .happy: return "😄"
        case .fullHealth: return "🌟"
        }
    }
    
    var color: Color {
        switch self {
        case .sick: return .red
        case .sad: return .orange
        case .content: return .yellow
        case .happy: return Color(hex: "8BC34A")
        case .fullHealth: return .green
        }
    }
    
    var description: String {
        switch self {
        case .sick: return "Your pet is feeling unwell. Get moving!"
        case .sad: return "Your pet is a bit down. Some steps would help!"
        case .content: return "Your pet is doing okay. Keep it up!"
        case .happy: return "Your pet is happy! Almost there!"
        case .fullHealth: return "Your pet is thriving! Amazing work!"
        }
    }
    
    static func from(health: Int) -> PetMoodState {
        let clampedHealth = max(0, min(100, health))
        
        switch clampedHealth {
        case 0...20: return .sick
        case 21...40: return .sad
        case 41...60: return .content
        case 61...80: return .happy
        default: return .fullHealth
        }
    }
}

// MARK: - Pet Model
struct Pet: Codable, Identifiable {
    var id = UUID()
    var type: PetType
    var name: String
    var health: Int = 100
    
    var moodState: PetMoodState {
        PetMoodState.from(health: health)
    }
    
    init(type: PetType = .cat, name: String = "Whiskers") {
        self.type = type
        self.name = name
    }
    
    mutating func updateHealth(currentSteps: Int, goalSteps: Int) {
        guard goalSteps > 0 else {
            health = 0
            return
        }
        health = min(100, Int((Double(currentSteps) / Double(goalSteps)) * 100))
    }
}

