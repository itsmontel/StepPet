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
    
    // Products
    @Published var weeklyProduct: Package?
    @Published var monthlyProduct: Package?
    @Published var creditProducts: [Package] = []
    
    // Current offering
    @Published var currentOffering: Offering?
    
    // MARK: - Configuration
    private let apiKey = "test_oOrhfSvxbBmuIHPCXAesAOCkpqN"
    
    private override init() {
        super.init()
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
            self.isPremium = info.entitlements[EntitlementConstants.pro]?.isActive == true
            print("✅ Premium status: \(isPremium)")
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
        return customerInfo?.entitlements[EntitlementConstants.pro]?.isActive == true
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
                
                var creditsToAdd = 0
                if productId.contains("credits_3") { creditsToAdd = 3 }
                else if productId.contains("credits_5") { creditsToAdd = 5 }
                else if productId.contains("credits_10") { creditsToAdd = 10 }
                
                if creditsToAdd > 0 {
                    userSettings.playCredits += creditsToAdd
                    print("✅ Added \(creditsToAdd) credits")
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
        guard let weekly = weeklyProduct?.storeProduct.price as Decimal?,
              let monthly = monthlyProduct?.storeProduct.price as Decimal?,
              weekly > 0 else {
            return 40
        }
        
        let weeklyMonthCost = weekly * 4
        if weeklyMonthCost > 0 {
            let savings = (1 - (monthly / weeklyMonthCost)) * 100
            return max(0, Int(truncating: savings as NSNumber))
        }
        return 40
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
            self.isPremium = customerInfo.entitlements[EntitlementConstants.pro]?.isActive == true
            print("📱 Customer info updated. Premium: \(self.isPremium)")
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
