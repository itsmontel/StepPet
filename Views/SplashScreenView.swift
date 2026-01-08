//
//  SplashScreenView.swift
//  VirtuPet
//
//  Instagram-style splash screen with logo and app name
//

import SwiftUI

struct SplashScreenView: View {
    // App's sunset orange accent color
    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29) // #FF6B4A
    
    // Background color matching the app's warm cream
    private let backgroundColor = Color(red: 1.0, green: 0.973, blue: 0.96) // #FFF8F5
    
    var body: some View {
        ZStack {
            // Clean background
            backgroundColor
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Centered logo - using dedicated splash logo asset
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                
                Spacer()
                
                // Bottom branding (like Instagram's "from Meta")
                Text("VirtuPet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

