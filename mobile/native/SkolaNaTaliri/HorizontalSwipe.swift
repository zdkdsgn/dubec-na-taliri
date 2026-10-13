import SwiftUI
import UIKit

/// Vodorovný swipe připojený přímo na nadřazený UIScrollView. Spustí se jen při
/// převážně vodorovném tažení, takže svislé scrollování zůstává netknuté a
/// klepnutí na kartu se po swipu zruší samo (systémové chování pan gesta).
struct HorizontalSwipe: UIViewRepresentable {
    /// +1 = tažení doleva (další den), -1 = doprava (předchozí)
    let onSwipe: (Int) -> Void

    /// SwiftUI tlačítko pod prstem po swipu nezruší klepnutí samo – karty se proto
    /// po vodorovném tažení krátce ignorují (viz `tapAllowed`).
    private static var suppressUntil = Date.distantPast
    static var tapAllowed: Bool { Date() > suppressUntil }

    func makeCoordinator() -> Coordinator { Coordinator(onSwipe: onSwipe) }

    func makeUIView(context: Context) -> Host {
        let v = Host()
        v.isUserInteractionEnabled = false
        v.coordinator = context.coordinator
        return v
    }

    func updateUIView(_ uiView: Host, context: Context) {
        context.coordinator.onSwipe = onSwipe
    }

    static func dismantleUIView(_ uiView: Host, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Host: UIView {
        weak var coordinator: Coordinator?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var v: UIView? = superview
            while let s = v, !(s is UIScrollView) { v = s.superview }
            if let scroll = v as? UIScrollView { coordinator?.attach(to: scroll) }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSwipe: (Int) -> Void
        private weak var scroll: UIScrollView?
        private var pan: UIPanGestureRecognizer?

        init(onSwipe: @escaping (Int) -> Void) { self.onSwipe = onSwipe }

        func attach(to scroll: UIScrollView) {
            guard self.scroll !== scroll else { return }
            detach()
            let p = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
            p.delegate = self
            scroll.addGestureRecognizer(p)
            self.scroll = scroll
            self.pan = p
        }

        func detach() {
            if let pan, let scroll { scroll.removeGestureRecognizer(pan) }
            pan = nil; scroll = nil
        }

        @objc private func handle(_ g: UIPanGestureRecognizer) {
            if g.state == .began || g.state == .changed { HorizontalSwipe.suppressUntil = Date().addingTimeInterval(0.4) }
            guard g.state == .ended, let view = g.view else { return }
            HorizontalSwipe.suppressUntil = Date().addingTimeInterval(0.4)
            let t = g.translation(in: view), v = g.velocity(in: view)
            guard abs(t.x) > abs(t.y) * 1.5, abs(t.x) > 60 || abs(v.x) > 700 else { return }
            onSwipe(t.x < 0 ? 1 : -1)
        }

        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let pan = g as? UIPanGestureRecognizer, let view = pan.view else { return false }
            let v = pan.velocity(in: view)
            return abs(v.x) > abs(v.y) * 1.5
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
