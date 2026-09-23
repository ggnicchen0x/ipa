import Foundation
import SwiftUI

public struct PackageReleaseInfo: Identifiable, Equatable {
    public var id: String { releaseId }
    public let releaseId: String
    public let packageName: String
    public let filename: String
    public let versionTag: String
    public let releaseNotes: String
    public let changedFeatures: [String]
    public let fileSha256: String
    public let publishedAt: String
    
    public init(
        releaseId: String,
        packageName: String,
        filename: String,
        versionTag: String,
        releaseNotes: String,
        changedFeatures: [String],
        fileSha256: String,
        publishedAt: String
    ) {
        self.releaseId = releaseId
        self.packageName = packageName
        self.filename = filename
        self.versionTag = versionTag
        self.releaseNotes = releaseNotes
        self.changedFeatures = changedFeatures
        self.fileSha256 = fileSha256
        self.publishedAt = publishedAt
    }
}

public final class ReleasesService: ObservableObject {
    public static let shared = ReleasesService()
    
    @Published public var unseenReleases: [PackageReleaseInfo] = []
    @Published public var activeModalRelease: PackageReleaseInfo? = nil
    @Published public var isChecking: Bool = false
    
    private init() {}
    
    /// Queries the backend for any package releases that this device has not yet acknowledged.
    public func fetchUnseenReleases(completion: ((Bool) -> Void)? = nil) {
        let auth = AuthService.shared
        guard auth.isAuthenticated else {
            completion?(false)
            return
        }
        let token = auth.currentSessionToken
        guard !token.isEmpty else {
            completion?(false)
            return
        }
        
        let hwid = auth.hardwareID
        guard let url = URL(string: "\(auth.serverBaseURL)/api/v2/releases/unseen") else {
            completion?(false)
            return
        }
        
        let requestBody: [String: Any] = [
            "device_hash": hwid,
            "token": token
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion?(false)
            return
        }
        
        DispatchQueue.main.async {
            self.isChecking = true
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isChecking = false
                }
            }
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let releaseList = json["unseen_releases"] as? [[String: Any]] else {
                completion?(false)
                return
            }
            
            var parsed: [PackageReleaseInfo] = []
            for r in releaseList {
                guard let relId = r["release_id"] as? String,
                      let pkgName = r["package_name"] as? String,
                      let filename = r["filename"] as? String else { continue }
                
                let verTag = r["version_tag"] as? String ?? "v1.0"
                let notes = r["release_notes"] as? String ?? ""
                let features = r["changed_features"] as? [String] ?? []
                let hashVal = r["file_sha256"] as? String ?? ""
                let pubAt = r["published_at"] as? String ?? ""
                
                parsed.append(
                    PackageReleaseInfo(
                        releaseId: relId,
                        packageName: pkgName,
                        filename: filename,
                        versionTag: verTag,
                        releaseNotes: notes,
                        changedFeatures: features,
                        fileSha256: hashVal,
                        publishedAt: pubAt
                    )
                )
            }
            
            DispatchQueue.main.async {
                self.unseenReleases = parsed
                if self.activeModalRelease == nil && !parsed.isEmpty {
                    self.activeModalRelease = parsed.first
                }
                completion?(true)
            }
        }.resume()
    }
    
    /// Acknowledges a release on the server so the changelog notice will NEVER appear again for this device.
    public func acknowledgeRelease(release: PackageReleaseInfo, completion: (() -> Void)? = nil) {
        let auth = AuthService.shared
        let token = auth.currentSessionToken
        let hwid = auth.hardwareID
        
        // Remove locally first for instant UI response
        DispatchQueue.main.async {
            self.unseenReleases.removeAll(where: { $0.releaseId == release.releaseId })
            self.activeModalRelease = self.unseenReleases.first
            completion?()
        }
        
        guard let url = URL(string: "\(auth.serverBaseURL)/api/v2/releases/acknowledge") else { return }
        let requestBody: [String: Any] = [
            "device_hash": hwid,
            "token": token,
            "release_id": release.releaseId
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request).resume()
    }
}
