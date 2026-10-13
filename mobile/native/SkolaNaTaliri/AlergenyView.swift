import SwiftUI

struct AlergenyView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.schoolTitle).font(.system(size: 12, weight: .bold)).tracking(1).textCase(.uppercase).foregroundStyle(T.ink3)
                    Text("Alergeny").font(.system(size: 28, weight: .bold)).tracking(-0.8)
                    Text("Zapněte ty, které hlídáte – jídla s nimi se v jídelníčku zvýrazní.")
                        .font(.system(size: 15)).foregroundStyle(T.ink2)
                }
                .padding(.top, 14)

                ForEach(Array(Allergen.all.enumerated()), id: \.element.id) { i, a in
                    let on = state.allergenFilter.contains(a.id)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { state.toggleAllergen(a.id) }
                    } label: {
                        HStack(spacing: 14) {
                            Text("\(a.id)").font(.system(size: 15, weight: .bold)).monospacedDigit()
                                .foregroundStyle(on ? T.onAccent : T.accent)
                                .frame(width: 34, height: 34)
                                .background(on ? T.accent : T.accentSoft, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(T.ink)
                                Text(a.detail).font(.system(size: 13)).foregroundStyle(T.ink2).multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(on)).labelsHidden().allowsHitTesting(false).tint(T.accent)
                        }
                        .padding(14).frame(maxWidth: .infinity)
                        .card(fill: on ? T.accentSoft : T.card, stroke: on ? T.accent.opacity(0.3) : T.cardBorder)
                    }
                    .buttonStyle(PressableStyle())
                    .staggerIn(i)
                }

                if !state.allergenFilter.isEmpty {
                    Button {
                        withAnimation { state.allergenFilter.removeAll() }
                    } label: {
                        Text("Zrušit všechny filtry").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.accent)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
