import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var tab = 0
    @State private var showSchools = false

    var body: some View {
        TabView(selection: $tab) {
            Tab("Den", systemImage: "calendar", value: 0) {
                page { DenView(showSchools: $showSchools, tab: $tab) }
            }
            Tab("Týden", systemImage: "list.bullet", value: 1) {
                page { TydenView() }
            }
            Tab("Alergeny", systemImage: "leaf", value: 2) {
                page { AlergenyView() }
            }
            Tab("Info", systemImage: "info.circle", value: 3) {
                page { InfoView(showSchools: $showSchools) }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(T.accent)
        .sheet(isPresented: $showSchools) { SchoolPickerView().environmentObject(state) }
        .task { await state.start() }
        .onReceive(NotificationCenter.default.publisher(for: .openSchoolFromPush)) { n in
            guard let id = n.object as? String else { return }
            tab = 0
            Task { await state.openFromPush(id) }
        }
    }

    private func page<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ZStack { AmbientBackground(); content() }
    }
}
