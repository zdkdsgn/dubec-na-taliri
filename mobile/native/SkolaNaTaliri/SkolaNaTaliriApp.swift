import SwiftUI

@main
struct SkolaNaTaliriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView().environmentObject(state)
                    .environment(\.dynamicTypeSize, state.bigText ? .xLarge : .large)
                if showSplash {
                    SplashView().transition(.opacity).zIndex(1)
                }
            }
            .preferredColorScheme(state.theme.scheme)
            .task {
                try? await Task.sleep(nanoseconds: reduce ? 200_000_000 : 2_200_000_000)
                withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
            }
        }
    }
}
