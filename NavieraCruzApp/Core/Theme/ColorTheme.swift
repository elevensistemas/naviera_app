import SwiftUI

struct ColorTheme {
    static let primary = Color(UIColor(named: "PrimaryColor") ?? UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1.0))
    static let secondary = Color(UIColor(named: "SecondaryColor") ?? UIColor.secondarySystemBackground)
    static let accent = Color(UIColor(named: "AccentColor") ?? UIColor(red: 0/255, green: 229/255, blue: 255/255, alpha: 1.0))
    
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = Color.blue
}

extension ColorTheme {
    // Hardcoded fallback colors based on Naviera Cruz identity (Blues/Dark)
    static var fallbackPrimary = Color(hex: "#0A2540")
    static var fallbackAccent = Color(hex: "#00E5FF")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
