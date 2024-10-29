import StoreKit
import SwiftUI

@available(macOS 12, *)
public class IAppRater {
    public let minLaunches: Int
    public let minDays: Int
    
    private let rateWndType: RateType
    
    private let config = UserDefaults.standard
    
    private let other: (IAppRater) -> Bool
    
    public init(minLaunches: Int = 0, minDays: Int = 0, other: @escaping (IAppRater) -> Bool = { _ in true }, rateWndType: RateType) {
        self.minLaunches = minLaunches
        self.minDays = minDays
        self.rateWndType = rateWndType
        self.other = other
        
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        
        self.launchesCount += 1
    }
    
    public func isNeededToRate(printDbgInfo: Bool = false) -> Bool {
        if printDbgInfo {
            let text = """
                    ---
                    guard lastReviewVersion[\(String(describing: lastReviewVersion))] != appVersion[\(appVersion)], 
                          other(self) [\(other(self))] 
                    else { return false }
                    
                    return daysAfterLastReview[\(daysAfterLastReview)] >= 125 ||
                        ( launchesCount[\(launchesCount)] >= minLaunches[\(minLaunches)] && daysAfterFirstLaunch[\(daysAfterFirstLaunch)] >= minDays[\(minDays)] )
                    ---
                    
                    """
            
            print(text)
        }
        
        guard lastReviewVersion != appVersion,
              other(self)
        else { return false }
        
        return daysAfterLastReview >= 125 ||
            ( launchesCount >= minLaunches && daysAfterFirstLaunch >= minDays )
    }
    
    @discardableResult
    public func requestIfNeeded() -> Bool {
        guard isNeededToRate() else { return false }
        
        request()
        
        return true
    }
    
    /// Use this method only for custom rate logic, or use requestIfNeeded() instead
    public func request() {
        switch self.rateWndType {
        case .standardAlert:
            displayStandartAlert()
        case .appStoreWnd(let appId):
            openAppStoreRate(appId: appId)
        }
        
        lastReviewDate = Date()
        lastReviewVersion = appVersion
    }
    
    public func resetIAppRaterData() {
        launchesCount = 1
        firstLaunchDate = Date()
        lastReviewDate = nil
        lastReviewVersion = nil
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

@available(macOS 12, *)
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
        return firstLaunchDate.daysDistanceTo(date: Date())
    }
    
    var daysAfterLastReview: Int {
        lastReviewDate?.daysDistanceTo(date: Date()) ?? 0
    }
}

//////////////////////
///HELPERS
///////////////////////

internal var appVersion: String {
    Bundle.main.object( forInfoDictionaryKey: "CFBundleShortVersionString" ) as! String
}

 

fileprivate extension Date {
    func daysDistanceTo(date end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: end).day ?? 0
    }
}

//////////////////////
///Show AppReview wnd
///////////////////////

@available(macOS 12, *)
fileprivate func displayStandartAlert() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
#if os(iOS)
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
#else
        if #available(macOS 14, *) {
            let a = NSViewController()
            AppStore.requestReview(in: a)
        } else {
            SKStoreReviewController.requestReview()
        }
#endif
    }
}

@available(macOS 12, *)
fileprivate func openAppStoreRate(appId: String) {
    if let url = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review"), !url.absoluteString.isEmpty {
        // fix of unsupported openAppStoreRate url functionality for iOS 15.0 & macOS 15, forcing displayStandartAlert
        #if os(macOS)
        if #available(macOS 15, *) {
            displayStandartAlert()
        } else {
            NSWorkspace.shared.open(url)
        }
        #endif
            
        #if os(iOS)
        if #available(iOS 14.0, *) {
            displayStandartAlert()
        } else {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
