import SwiftUI

@main
struct MurmoraApp: App {
    @State private var showLaunch = true

    @StateObject private var store = MurmoraStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if showLaunch {
                    MurmoraLaunchScreen()
                        .preferredColorScheme(.dark)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                withAnimation(.easeInOut(duration: 0.35)) { showLaunch = false }
                            }
                        }
                } else if !store.onboardingSeen {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.35)) { store.markOnboardingSeen() }
                    }
                    .environmentObject(store)
                    .preferredColorScheme(.dark)
                } else {
                    RootView()
                        .environmentObject(store)
                        .preferredColorScheme(.dark)
                }
            }
        }
    }
}
