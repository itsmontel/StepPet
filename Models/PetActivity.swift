//
//  PetActivity.swift
//  VirtuPet
//

import SwiftUI

// MARK: - Pet Activity Type
enum PetActivity: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case playBall = "Play Ball"
    case watchTV = "Watch TV"
    
    var id: String { rawValue }
    
    func displayName(for petType: PetType) -> String {
        switch self {
        case .feed: return "Feed \(petType.displayName)"
        case .playBall: return "Play Ball"
        case .watchTV: return "Watch TV"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "fork.knife"
        case .playBall: return "tennisball.fill"
        case .watchTV: return "tv.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return Color.orange
        case .playBall: return Color.green
        case .watchTV: return Color.purple
        }
    }
    
    var description: String {
        switch self {
        case .feed: return "A tasty meal to boost energy"
        case .playBall: return "Fun exercise time together"
        case .watchTV: return "Relaxing entertainment"
        }
    }
    
    func gifName(for petType: PetType) -> String {
        switch self {
        case .feed: return "Feed\(petType.rawValue)"
        case .playBall: return "\(petType.rawValue)PlayBall"
        case .watchTV: return "\(petType.rawValue)TV"
        }
    }
}

// MARK: - Credit Package
struct CreditPackage: Identifiable {
    let id = UUID()
    let credits: Int
    let price: String
    let productId: String
    let savings: String?
    let isPopular: Bool
    
    static let packages: [CreditPackage] = [
        CreditPackage(credits: 5, price: "$1.99", productId: "virtupet_credits_5", savings: nil, isPopular: false),
        CreditPackage(credits: 10, price: "$2.99", productId: "virtupet_credits_10", savings: "Most Popular", isPopular: true),
        CreditPackage(credits: 25, price: "$4.99", productId: "virtupet_credits_25", savings: "50% off", isPopular: false)
    ]
}



