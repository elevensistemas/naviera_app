import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

struct Typography {
    static func title1() -> Font { .system(size: 28, weight: .bold, design: .default) }
    static func title2() -> Font { .system(size: 22, weight: .semibold, design: .default) }
    static func headline() -> Font { .system(size: 18, weight: .semibold, design: .default) }
    static func body() -> Font { .system(size: 16, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 13, weight: .medium, design: .default) }
}
