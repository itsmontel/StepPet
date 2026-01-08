//
//  WidgetIntroPopup.swift
//  VirtuPet
//
//  Popup to introduce users to home screen widgets after 15 minutes of app usage
//

import SwiftUI

struct WidgetIntroPopup: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    @State private var animateContent = false
    @State private var animateImage = false
    @State private var animateSteps = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Popup card
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(themeManager.secondaryTextColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Celebration emoji
                        Text("🎉")
                            .font(.system(size: 50))
                            .scaleEffect(animateContent ? 1.0 : 0.5)
                        
                        // Title
                        Text("We have widgets!")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Subtitle
                        Text("Track your pet's health right from your home screen!")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Widget preview image
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.accentColor.opacity(0.08))
                            
                            if let uiImage = UIImage(named: "Widgetonboarding") ?? 
                               UIImage(contentsOfFile: Bundle.main.path(forResource: "Widgetonboarding", ofType: "PNG") ?? "") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                // Fallback placeholder
                                VStack(spacing: 12) {
                                    Image(systemName: "apps.iphone")
                                        .font(.system(size: 40))
                                        .foregroundColor(themeManager.accentColor)
                                    Text("Widget Preview")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                        .scaleEffect(animateImage ? 1.0 : 0.9)
                        .opacity(animateImage ? 1.0 : 0.0)
                        
                        // How to steps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to add:")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.accentColor)
                            
                            PopupStepRow(
                                stepNumber: 1,
                                text: "Tap & Hold on your Home Screen",
                                accentColor: themeManager.accentColor,
                                textColor: themeManager.primaryTextColor
                            )
                            
                            PopupStepRow(
                                stepNumber: 2,
                                text: "Tap \"+\" and search \"VirtuPet\"",
                                accentColor: themeManager.accentColor,
                                textColor: themeManager.primaryTextColor
                            )
                            
                            PopupStepRow(
                                stepNumber: 3,
                                text: "Choose size & tap \"Add Widget\"",
                                accentColor: themeManager.accentColor,
                                textColor: themeManager.primaryTextColor
                            )
                        }
                        .padding(.horizontal, 20)
                        .opacity(animateSteps ? 1.0 : 0.0)
                        
                        Spacer(minLength: 10)
                    }
                    .padding(.top, 8)
                }
                
                // Got it button
                Button(action: { dismiss() }) {
                    Text("Got it!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(26)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(animateButton ? 1.0 : 0.0)
            }
            .frame(maxWidth: 340)
            .frame(maxHeight: 580)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .scaleEffect(animateContent ? 1.0 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateImage = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                animateSteps = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                animateButton = true
            }
        }
    }
    
    private func dismiss() {
        HapticFeedback.light.trigger()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Popup Step Row
private struct PopupStepRow: View {
    let stepNumber: Int
    let text: String
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Step number
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
            
            // Step text
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(textColor)
        }
    }
}

#Preview {
    WidgetIntroPopup(isPresented: .constant(true))
        .environmentObject(ThemeManager())
}

