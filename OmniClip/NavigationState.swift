import Foundation
import SwiftUI

// MARK: - App Pages

enum AppPage: Equatable {
    case clipboard
    case notes
    case settings
}

// MARK: - Navigation State

class NavigationState: ObservableObject {
    @Published var currentPage: AppPage = .clipboard
    
    func goBack() {
        currentPage = .clipboard
    }
    
    func openNotes() {
        currentPage = .notes
    }
    
    func openSettings() {
        currentPage = .settings
    }
}
