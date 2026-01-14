//
//  PurchaseManager.swift
//  VirtuPet
//
//  RevenueCat integration for handling purchases
//

import Foundation
import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Notification Names
extension Notification.Name {
    static let userBecamePremium = Notification.Name("userBecamePremium")
}

// MARK: - Entitlement Identifier
struct EntitlementConstants {
    static let pro = "Virtupet: Steps Pro"
}

// MARK: - Purchase Manager
class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    
    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var customerInfo: CustomerInfo?
    
    // Trial eligibility - tracks if user has ever had a subscription
    @Published var hasEverSubscribed: Bool = false
    
    // Products
    @Published var weeklyProduct: Package?
    @Published var monthlyProduct: Package?
    @Published var creditProducts: [Package] = []
    
    // Current offering
    @Published var currentOffering: Offering?
    
    // MARK: - Configuration
    // RevenueCat Public API Key - Safe to include in app code
    // This key is tied to your app's bundle ID and can only be used with your app
    private let apiKey = "appl_YAuRPbpLoAMsmXMYXoQdRcXbZNi"
    
    // Billing grace period setting
    // When true, users in grace period (payment failed but still have access) are treated as premium
    // When false, only active subscriptions are treated as premium
    // Note: Grace period support requires RevenueCat SDK 4.0+
    var enableBillingGracePeriod: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Trial Eligibility
    /// Returns true if user is eligible for free trial (never subscribed before)
    var isEligibleForTrial: Bool {
        return !hasEverSubscribed && !isPremium
    }
    
    /// Button text for premium upgrade based on trial eligibility
    var upgradeButtonText: String {
        return isEligibleForTrial ? "Try Premium for Free" : "Upgrade to Premium"
    }
    
    // MARK: - Setup
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        
        Task { @MainActor in
            await self.refreshCustomerInfo()
            await self.fetchOfferings()
        }
    }
    
    // MARK: - Refresh Customer Info
    @MainActor
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            let entitlement = info.entitlements[EntitlementConstants.pro]
            
            // Check if subscription is active
            if let entitlement = entitlement {
                self.isPremium = entitlement.isActive
            } else {
                self.isPremium = false
            }
            
            // Check if user has ever had a subscription (for trial eligibility)
            // This checks all purchased product IDs - if they've ever purchased a subscription, they're not eligible for trial
            let subscriptionProducts = info.allPurchasedProductIdentifiers.filter { 
                $0.contains("weekly") || $0.contains("monthly") || $0.contains("annual")
            }
            self.hasEverSubscribed = !subscriptionProducts.isEmpty
            
            // Also check if there's any entitlement history (even if expired)
            if let entitlement = info.entitlements[EntitlementConstants.pro] {
                // If there's an original purchase date, they've subscribed before
                if entitlement.originalPurchaseDate != nil {
                    self.hasEverSubscribed = true
                }
            }
            
            print("✅ Premium status: \(isPremium), Has ever subscribed: \(hasEverSubscribed), Trial eligible: \(isEligibleForTrial)")
        } catch {
            print("❌ Error fetching customer info: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Offerings
    @MainActor
    func fetchOfferings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            if let current = offerings.current {
                self.currentOffering = current
                self.weeklyProduct = current.weekly ?? current.package(identifier: "weekly")
                self.monthlyProduct = current.monthly ?? current.package(identifier: "monthly")
                self.creditProducts = current.availablePackages.filter { package in
                    package.storeProduct.productIdentifier.contains("credits")
                }
                print("✅ Loaded \(current.availablePackages.count) packages")
            } else {
                print("⚠️ No current offering available")
            }
            
            isLoading = false
        } catch {
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error fetching offerings: \(error)")
        }
    }
    
    // MARK: - Check Premium Status
    var hasPremiumAccess: Bool {
        guard let entitlement = customerInfo?.entitlements[EntitlementConstants.pro] else {
            return false
        }
        
        return entitlement.isActive
    }
    
    // MARK: - Purchase Package
    @MainActor
    func purchase(package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let wasPremiumBefore = isPremium
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            self.customerInfo = result.customerInfo
            let isNowPremium = result.customerInfo.entitlements[EntitlementConstants.pro]?.isActive == true
            self.isPremium = isNowPremium
            isLoading = false
            
            // Post notification if user just became premium for the first time
            if isNowPremium && !wasPremiumBefore && !result.userCancelled {
                NotificationCenter.default.post(name: .userBecamePremium, object: nil)
                print("🎉 User upgraded to premium! Achievement notification posted.")
            }
            
            return !result.userCancelled
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            print("❌ Purchase error: \(error)")
            return false
        }
    }
    
    // MARK: - Purchase Credits
    @MainActor
    func purchaseCredits(package: Package, userSettings: UserSettings) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            if !result.userCancelled {
                let productId = package.storeProduct.productIdentifier
                
                // Extract credit amount from product ID (e.g., "virtupet_credits_25" -> 25)
                var creditsToAdd = 0
                if let range = productId.range(of: "credits_") {
                    let numberString = String(productId[range.upperBound...])
                    creditsToAdd = Int(numberString) ?? 0
                }
                
                // Fallback for legacy product IDs
                if creditsToAdd == 0 {
                    if productId.contains("credits_5") { creditsToAdd = 5 }
                    else if productId.contains("credits_10") { creditsToAdd = 10 }
                    else if productId.contains("credits_25") { creditsToAdd = 25 }
                }
                
                if creditsToAdd > 0 {
                    userSettings.playCredits += creditsToAdd
                    print("✅ Added \(creditsToAdd) credits. Total: \(userSettings.playCredits)")
                }
                
                isLoading = false
                return true
            }
            
            isLoading = false
            return false
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            print("❌ Purchase error: \(error)")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
            self.isPremium = info.entitlements[EntitlementConstants.pro]?.isActive == true
            isLoading = false
            print("✅ Restore completed. Premium: \(isPremium)")
            return isPremium
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            isLoading = false
            print("❌ Restore failed: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Properties
    var weeklyPriceString: String {
        weeklyProduct?.localizedPriceString ?? "$3.99"
    }
    
    var monthlyPriceString: String {
        monthlyProduct?.localizedPriceString ?? "$9.99"
    }
    
    var monthlySavingsPercentage: Int {
        guard let weeklyPrice = weeklyProduct?.storeProduct.price as? NSDecimalNumber,
              let monthlyPrice = monthlyProduct?.storeProduct.price as? NSDecimalNumber else {
            // Default: $3.99/week * 4 = $15.96/month vs $9.99/month = ~37% savings
            return 37
        }
        
        let weekly = weeklyPrice.doubleValue
        let monthly = monthlyPrice.doubleValue
        
        guard weekly > 0 else { return 37 }
        
        // Calculate: 4 weeks worth vs monthly price
        let weeklyMonthCost = weekly * 4.0
        
        if weeklyMonthCost > monthly {
            let savings = ((weeklyMonthCost - monthly) / weeklyMonthCost) * 100.0
            return max(0, Int(savings.rounded()))
        }
        return 37
    }
    
    // MARK: - Subscription Info
    var activeSubscription: String? {
        guard let entitlement = customerInfo?.entitlements[EntitlementConstants.pro],
              entitlement.isActive else {
            return nil
        }
        return entitlement.productIdentifier
    }
    
    var expirationDate: Date? {
        return customerInfo?.entitlements[EntitlementConstants.pro]?.expirationDate
    }
    
    var willRenew: Bool {
        return customerInfo?.entitlements[EntitlementConstants.pro]?.willRenew ?? false
    }
}

// MARK: - RevenueCat Delegate
extension PurchaseManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            self.customerInfo = customerInfo
            let entitlement = customerInfo.entitlements[EntitlementConstants.pro]
            
            // Update premium status
            if let entitlement = entitlement {
                self.isPremium = entitlement.isActive
                
                // Track if user has ever subscribed
                if entitlement.originalPurchaseDate != nil {
                    self.hasEverSubscribed = true
                }
            } else {
                self.isPremium = false
            }
            
            // Also check all purchased products for subscription history
            let subscriptionProducts = customerInfo.allPurchasedProductIdentifiers.filter { 
                $0.contains("weekly") || $0.contains("monthly") || $0.contains("annual")
            }
            if !subscriptionProducts.isEmpty {
                self.hasEverSubscribed = true
            }
            
            print("📱 Customer info updated. Premium: \(self.isPremium), Has ever subscribed: \(self.hasEverSubscribed)")
        }
    }
}

// MARK: - Simple Paywall Wrapper
struct SimplePaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        PaywallView(displayCloseButton: true)
    }
}

// MARK: - Subscription Management View
struct SubscriptionManagementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Current Plan") {
                    if purchaseManager.isPremium {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("VirtuPet Pro")
                                    .font(.headline)
                            }
                            
                            if let productId = purchaseManager.activeSubscription {
                                Text(productId.contains("weekly") ? "Weekly Plan" : "Monthly Plan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let expirationDate = purchaseManager.expirationDate {
                                let formatter = DateFormatter()
                                let _ = formatter.dateStyle = .medium
                                Text(purchaseManager.willRenew ? "Renews: \(formatter.string(from: expirationDate))" : "Expires: \(formatter.string(from: expirationDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.gray)
                            Text("Free Plan")
                                .font(.headline)
                        }
                    }
                }
                
                Section("Actions") {
                    if !purchaseManager.isPremium {
                        NavigationLink {
                            PaywallView(displayCloseButton: false)
                        } label: {
                            Label("Upgrade to Pro", systemImage: "crown")
                        }
                    }
                    
                    Button {
                        Task {
                            await purchaseManager.restorePurchases()
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    
                    if purchaseManager.isPremium {
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            Label("Manage Subscription", systemImage: "gear")
                        }
                    }
                }
                
                Section("Help") {
                    Link(destination: URL(string: "mailto:support@virtupet.app")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    Link(destination: URL(string: "https://virtupet.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://virtupet.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Premium Feature Gate
struct PremiumFeatureGate<Content: View, LockedContent: View>: View {
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    
    let content: Content
    let lockedContent: LockedContent
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder lockedContent: () -> LockedContent
    ) {
        self.content = content()
        self.lockedContent = lockedContent()
    }
    
    var body: some View {
        if purchaseManager.isPremium {
            content
        } else {
            lockedContent
                .onTapGesture {
                    showPaywall = true
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(displayCloseButton: true)
                }
        }
    }
}

// MARK: - Premium Button
struct PremiumButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        Button {
            if purchaseManager.isPremium {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            Label(title, systemImage: icon)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(displayCloseButton: true)
        }
    }
}
