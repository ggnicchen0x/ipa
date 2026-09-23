import Foundation
import UIKit
import UserNotifications

public final class APNsManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = APNsManager()
    
    @Published public var devicePushToken: String? = nil
    @Published public var isRegistered: Bool = false
    
    private let tokenStorageKey = "com.threeoneosfive.apns.device_token"
    
    private override init() {
        super.init()
        self.devicePushToken = UserDefaults.standard.string(forKey: tokenStorageKey)
    }
    
    /// Requests push notification authorization from iOS and registers for remote notifications.
    public func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                log("apns: authorization request failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Called from AppDelegate when remote notifications token is received.
    public func didRegisterForRemoteNotifications(with deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let hexToken = tokenParts.joined()
        
        DispatchQueue.main.async {
            self.devicePushToken = hexToken
            UserDefaults.standard.set(hexToken, forKey: self.tokenStorageKey)
            self.sendTokenToBackendIfNeeded()
        }
    }
    
    public func didFailToRegisterForRemoteNotifications(with error: Error) {
        log("apns: registration failed: \(error.localizedDescription)")
    }
    
    /// Dispatches the APNs device token to the server with active session credentials.
    public func sendTokenToBackendIfNeeded() {
        guard let token = devicePushToken, !token.isEmpty else { return }
        let auth = AuthService.shared
        guard auth.isAuthenticated else { return }
        let sessionToken = auth.currentSessionToken
        guard !sessionToken.isEmpty else { return }
        
        let hwid = auth.hardwareID
        guard let url = URL(string: "\(auth.serverBaseURL)/api/v2/apns/register-token") else { return }
        
        #if DEBUG
        let env = "sandbox"
        #else
        let env = "production"
        #endif
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.threeoneosfive.app"
        let requestBody: [String: Any] = [
            "token": token,
            "device_hash": hwid,
            "session_token": sessionToken,
            "bundle_id": bundleID,
            "environment": env
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.isRegistered = true
                    log("apns: device token registered with server successfully")
                }
            } else if let error = error {
                log("apns: failed to dispatch token to server: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even if app is foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Check for new releases on notification open
        ReleasesService.shared.fetchUnseenReleases()
        completionHandler()
    }
}
