import SwiftUI

@main
struct SkolaNaTaliriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()
    @StateObject private var orders = OrdersService()
    @Environment(\.scenePhase) private var phase
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView().environmentObject(state).environmentObject(orders)
                    .environment(\.dynamicTypeSize, state.bigText ? .xLarge : .large)
                if showSplash {
                    SplashView().transition(.opacity).zIndex(1)
                }
            }
            .preferredColorScheme(state.theme.scheme)
            .task(id: state.active.id) { await orders.refresh(schoolId: state.active.id) }
            .onChange(of: phase) { _, p in
                if p == .active { Task { await orders.refresh(schoolId: state.active.id) } }
            }
            .task {
                try? await Task.sleep(nanoseconds: reduce ? 200_000_000 : 2_200_000_000)
                withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
            }
        }
    }
}
