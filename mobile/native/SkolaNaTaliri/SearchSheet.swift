import SwiftUI

/// Hledání v jídelníčku: kdy bylo (nebo bude) dané jídlo.
struct SearchSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let onPick: (String) -> Void

    var body: some View {
        NavigationStack {
            let found = state.search(query)
            List {
                if query.trimmingCharacters(in: .whitespaces).count < 2 {
                    Text("Napište aspoň dvě písmena, třeba „guláš“ nebo „ryba“.").foregroundStyle(T.ink2)
                        .listRowBackground(Color.clear)
                } else if found.isEmpty {
                    Text("Nic jsme v jídelníčku nenašli.").foregroundStyle(T.ink2).listRowBackground(Color.clear)
                } else {
                    ForEach(found, id: \.date) { item in
                        Button { dismiss(); onPick(item.date) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.meal.n).font(.system(size: 16, weight: .semibold)).foregroundStyle(T.ink)
                                Text("\(Cal.dowName(item.date)) \(Cal.short(item.date)) · \(Course.of(item.meal.c).label)")
                                    .font(.system(size: 13)).foregroundStyle(T.ink2)
                            }
                        }.listRowBackground(T.card)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(T.bg)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Hledat jídlo")
            .navigationTitle("Hledání")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } } }
        }
        .presentationDragIndicator(.visible)
    }
}
