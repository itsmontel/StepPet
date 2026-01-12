//
//  CommitmentPromptView.swift
//  VirtuPet
//
//  Emotional commitment prompt shown after first-time tutorial
//

import SwiftUI

struct CommitmentPromptView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var showCheckmark = false
    @State private var pulseAnimation = false
    @State private var ringScale: CGFloat = 1.0
    @State private var hasCompleted = false
    
    private var userName: String {
        userSettings.userName.isEmpty ? "Friend" : userSettings.userName
    }
    
    private var petName: String {
        userSettings.pet.name.isEmpty ? "Buddy" : userSettings.pet.name
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header spacer
                Spacer()
                    .frame(height: 60)
                
                // Title
                VStack(spacing: 8) {
                    Text("I, \(userName), will use")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("VirtuPet to")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                
                // Subtitle commitment text
                Text("take better care of \(petName), stay active,\nand build healthy habits together.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Tap and hold circle with pet icon
                ZStack {
                    // Outer pulsing rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(themeManager.accentColor.opacity(0.15), lineWidth: 2)
                            .frame(width: 180 + CGFloat(i * 30), height: 180 + CGFloat(i * 30))
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.5)
                            .animation(
                                .easeInOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }
                    
                    // Progress ring background
                    Circle()
                        .stroke(
                            themeManager.accentColor.opacity(0.2),
                            lineWidth: 8
                        )
                        .frame(width: 160, height: 160)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            LinearGradient(
                                colors: themeManager.accentColorTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: holdProgress)
                    
                    // Main circle button
                    ZStack {
                        // Gradient fill
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: themeManager.accentColorTheme.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        // Inner shine
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        // Fingerprint pattern (subtle)
                        if !showCheckmark {
                            Image(systemName: "touchid")
                                .font(.system(size: 50, weight: .thin))
                                .foregroundColor(.white.opacity(0.3))
                                .offset(y: -10)
                        }
                        
                        // Pet icon or checkmark
                        if showCheckmark {
                            Image(systemName: "checkmark")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        }
                    }
                    .scaleEffect(isHolding ? 0.95 : (ringScale))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHolding)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !hasCompleted {
                                    startHolding()
                                }
                            }
                            .onEnded { _ in
                                if !hasCompleted {
                                    stopHolding()
                                }
                            }
                    )
                }
                .padding(.vertical, 40)
                
                // Instruction text
                if !hasCompleted {
                    VStack(spacing: 4) {
                        Text("Tap and hold on the")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(themeManager.accentColor)
                            
                            Text("paw to commit.")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                    }
                    .transition(.opacity)
                } else {
                    Text("You're all set! Let's go! 🎉")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.successColor)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Skip button (subtle)
                if !hasCompleted {
                    Button(action: {
                        HapticFeedback.light.trigger()
                        dismissView()
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.6))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation {
                pulseAnimation = true
            }
            
            // Subtle breathing animation for the button
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                ringScale = 1.03
            }
        }
    }
    
    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        HapticFeedback.light.trigger()
        
        // Animate progress over 1.5 seconds
        let totalDuration: Double = 1.5
        let steps = 100
        let stepDuration = totalDuration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                if isHolding && !hasCompleted {
                    withAnimation(.linear(duration: stepDuration)) {
                        holdProgress = CGFloat(i) / CGFloat(steps)
                    }
                    
                    // Trigger haptic at intervals
                    if i % 25 == 0 && i > 0 {
                        HapticFeedback.light.trigger()
                    }
                    
                    // Complete when full
                    if i == steps {
                        completeCommitment()
                    }
                }
            }
        }
    }
    
    private func stopHolding() {
        guard !hasCompleted else { return }
        isHolding = false
        
        // Reset progress if not completed
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            holdProgress = 0
        }
    }
    
    private func completeCommitment() {
        hasCompleted = true
        isHolding = false
        HapticFeedback.success.trigger()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
        }
        
        // Dismiss after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismissView()
        }
    }
    
    private func dismissView() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
        onComplete()
    }
}

// MARK: - Preview
#Preview {
    CommitmentPromptView(isPresented: .constant(true), onComplete: {})
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
