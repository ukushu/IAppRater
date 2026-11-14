import StoreKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

@available(iOS 10.3, macOS 12, *)
public class IAppRater {
    private static let requestLock = NSLock()
    private static var requestPending = false
    private static var requestGeneration = 0

    public let minLaunches: Int
    public let minDays: Int
    
    private let rateWndType: RateType
    
    private let config = UserDefaults.standard
    
    private let other: (IAppRater) -> Bool
    let pointsConfiguration: PointsConfiguration?
    
    public init(minLaunches: Int = 0, minDays: Int = 0, other: @escaping (IAppRater) -> Bool = { _ in true }, points: PointsConfiguration? = nil, rateWndType: RateType) {
        self.minLaunches = minLaunches
        self.minDays = minDays
        self.rateWndType = rateWndType
        self.other = other
        self.pointsConfiguration = points
        
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        
        self.launchesCount += 1
    }
    
    public func isNeededToRate(printDbgInfo: Bool = false) -> Bool {
        let currentAppVersion = appVersion
        if printDbgInfo {
            print("""
            ---
            guard lastReviewVersion [\(String(describing: lastReviewVersion))] != appVersion[\(currentAppVersion)] else { return false }
            """)
        }
        
        guard lastReviewVersion != currentAppVersion else { return false }
        
        let customRequirementsMet = other(self)
        if printDbgInfo {
            print("""
            guard customUserRequirements [\(customRequirementsMet)] else { return false }
            """)
        }
        
        guard customRequirementsMet else { return false }
        
        if printDbgInfo {
            print("""
            return daysAfterLastReview[\(daysAfterLastReview)] >= 125 || ( launchesCount[\(launchesCount)] >= minLaunches[\(minLaunches)] && daysAfterFirstLaunch[\(daysAfterFirstLaunch)] >= minDays[\(minDays)] )
            """)
        }
        
        let pointsReached = pointsConfiguration.map { currentPoints >= $0.threshold } ?? true
        return pointsReached && (daysAfterLastReview >= 125 || ( launchesCount >= minLaunches && daysAfterFirstLaunch >= minDays ))
    }
    
    @discardableResult
    public func requestIfNeeded() -> Bool {
        Self.requestLock.lock()
        guard !Self.requestPending else {
            Self.requestLock.unlock()
            return false
        }
        Self.requestPending = true
        let generation = Self.requestGeneration
        Self.requestLock.unlock()
        guard isNeededToRate() else {
            Self.finishRequest(generation)
            return false
        }
        performRequest { [weak self] succeeded in
            Self.finishRequest(generation) { if succeeded { self?.recordRequest() } }
        }
        return true
    }
    
    /// Use this method only for custom rate logic, or use requestIfNeeded() instead
    public func request() {
        Self.requestLock.lock()
        guard !Self.requestPending else { Self.requestLock.unlock(); return }
        Self.requestPending = true
        let generation = Self.requestGeneration
        Self.requestLock.unlock()
        performRequest { [weak self] succeeded in
            Self.finishRequest(generation) { if succeeded { self?.recordRequest() } }
        }
    }

    private static func finishRequest(_ generation: Int, record: () -> Void = {}) {
        requestLock.lock()
        if requestGeneration == generation {
            record()
            requestPending = false
        }
        requestLock.unlock()
    }

    private func recordRequest() {
        lastReviewDate = Date()
        lastReviewVersion = appVersion
    }

    private func performRequest(completion: @escaping (Bool) -> Void) {
        switch rateWndType {
        case .standardAlert:
            displayStandartAlert(completion: completion)
        case .appStoreWnd(let appId):
            openAppStoreRate(appId: appId, completion: completion)
        }
    }
    
    public func resetIAppRaterData() {
        Self.requestLock.lock()
        Self.requestGeneration += 1
        Self.requestPending = false
        Self.requestLock.unlock()
        launchesCount = 1
        firstLaunchDate = Date()
        lastReviewDate = nil
        lastReviewVersion = nil
        pointsReset()
    }

}

public enum RateType {
    case standardAlert
    
    ///.
    ///
    /// you can get app id from AppStore link:
    /// https://apps.apple.com/ua/app/taogit/id1582642693
    ///
    /// here appId is: 1582642693
    case appStoreWnd(appId: String)
}

@available(iOS 10.3, macOS 12, *)
public extension IAppRater {
    var launchesCount: Int {
        get { config.integer(forKey: "ArrRaterLaunchesCounter") }
        set(value) { config.set(value, forKey: "ArrRaterLaunchesCounter") }
    }
    
    var firstLaunchDate: Date! {
        get { config.object(forKey: "ArrRaterFirstLaunchDate") as? Date }
        set(value) { config.set(value, forKey: "ArrRaterFirstLaunchDate") }
    }
    
    var lastReviewDate: Date? {
        get { config.object(forKey: "ArrRaterLastReviewDate") as? Date }
        set(value) { config.set(value, forKey: "ArrRaterLastReviewDate") }
    }
    
    var lastReviewVersion: String? {
        get { config.string(forKey: "ArrRaterLastReviewVersion") }
        set(value) { config.set(value, forKey: "ArrRaterLastReviewVersion") }
    }
    
    var daysAfterFirstLaunch: Int {
        firstLaunchDate?.daysDistanceTo(date: Date()) ?? 0
    }
    
    var daysAfterLastReview: Int {
        lastReviewDate?.daysDistanceTo(date: Date()) ?? 0
    }
}

//////////////////////
///HELPERS
///////////////////////

internal var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
}

 

fileprivate extension Date {
    func daysDistanceTo(date end: Date) -> Int {
        if let days = Calendar.current.dateComponents([.day], from: self, to: end).day {
            return days
        }
        
        return 0
    }
}

//////////////////////
///Show AppReview wnd
///////////////////////

@available(iOS 10.3, macOS 12, *)
fileprivate func displayStandartAlert(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
#if os(iOS)
        if #available(iOS 14.0, *) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) else {
                completion(false)
                return
            }
            SKStoreReviewController.requestReview(in: scene)
            completion(true)
        } else {
            SKStoreReviewController.requestReview()
            completion(true)
        }
#else
        SKStoreReviewController.requestReview()
        completion(true)
#endif
    }
}

@available(iOS 10.3, macOS 12, *)
fileprivate func openAppStoreRate(appId: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review") else {
        completion(false)
        return
    }
    DispatchQueue.main.async {
#if os(macOS)
        completion(NSWorkspace.shared.open(url))
#else
        UIApplication.shared.open(url, completionHandler: completion)
#endif
    }
}
