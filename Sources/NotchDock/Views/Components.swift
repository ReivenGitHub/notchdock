import SwiftUI

enum DockTheme {
    static let accent = Color(red: 0.78, green: 0.93, blue: 0.62)
    static let card = Color(red: 0.075, green: 0.08, blue: 0.085)
    static let muted = Color.white.opacity(0.48)
    static let border = Color.white.opacity(0.085)
}
struct DockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let shoulder: CGFloat = 10
        let radius = min(24, rect.height / 2)
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width - shoulder, y: shoulder), control: CGPoint(x: rect.width - shoulder, y: 0))
        path.addLine(to: CGPoint(x: rect.width - shoulder, y: rect.height - radius))
        path.addQuadCurve(to: CGPoint(x: rect.width - shoulder - radius, y: rect.height), control: CGPoint(x: rect.width - shoulder, y: rect.height))
        path.addLine(to: CGPoint(x: shoulder + radius, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: shoulder, y: rect.height - radius), control: CGPoint(x: shoulder, y: rect.height))
        path.addLine(to: CGPoint(x: shoulder, y: shoulder))
        path.addQuadCurve(to: .zero, control: CGPoint(x: shoulder, y: 0))
        path.closeSubpath()
        return path
    }
}
struct IconButton: View {
    let symbol: String
    let label: String
    var active = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 12, weight: .medium))
                .foregroundStyle(active ? DockTheme.accent : .white.opacity(0.65))
                .frame(width: 28, height: 28)
                .background(active ? DockTheme.accent.opacity(0.1) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).help(label).accessibilityLabel(label)
    }
}
struct AccentButton: View {
    let title: String
    var symbol: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.system(size: 11, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 9)
            .foregroundStyle(Color.black).background(DockTheme.accent, in: Capsule())
        }.buttonStyle(.plain)
    }
}
extension View {
    func dockCard() -> some View {
        self.background(DockTheme.card, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DockTheme.border))
    }
}
