import SwiftUI

class AppSettings: ObservableObject {
    @Published var copyOnClick: Bool {
        didSet {
            UserDefaults.standard.set(copyOnClick, forKey: "copyOnClick")
        }
    }
    
    @Published var showTimestamps: Bool {
        didSet {
            UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps")
        }
    }
    
    @Published var captureScreenshots: Bool {
        didSet {
            UserDefaults.standard.set(captureScreenshots, forKey: "captureScreenshots")
        }
    }
    
    init() {
        // Use object(forKey:) to check if key exists, otherwise use default
        if UserDefaults.standard.object(forKey: "copyOnClick") != nil {
            self.copyOnClick = UserDefaults.standard.bool(forKey: "copyOnClick")
        } else {
            self.copyOnClick = false
        }
        
        if UserDefaults.standard.object(forKey: "showTimestamps") != nil {
            self.showTimestamps = UserDefaults.standard.bool(forKey: "showTimestamps")
        } else {
            self.showTimestamps = true
        }
        
        if UserDefaults.standard.object(forKey: "captureScreenshots") != nil {
            self.captureScreenshots = UserDefaults.standard.bool(forKey: "captureScreenshots")
        } else {
            self.captureScreenshots = true
        }
    }
}
