# IAppRater 

<img src="https://github.com/ukushu/IAppRater/blob/main/IAppRaterLogo.png" width="170">


Tiny lib to show "Rate my app" alert for macOS and iOS apps.

## SupportedOS:
iOS(?), MacOS(>=12)

## KeyFeatures:
* Ability to set minimal amount of app launches before yout app perform request to rate your app
*  --//-- minimum days of usage --//--
* Do not ask to rate your app if this version already was rated by user
* Ability to open standard "Rate Me" alert OR open "Rate me" popup inside of AppStore window
* Ability to work with custom View logic like "Show "Rate my app" button only if rate is needed"
* Ability to set additional custom rules for "rate is needed" state :)


## How to use, sample with SwiftUI:

//init custom AppDelegate
```swift
import SwiftUI

@main
struct FocusitoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MainView()
    }
}
```

//init AppRater on `DidFinishLaunching` inside of AppDelegate
```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    
    var appRater: IAppRater!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // if we do not need custom display alert logic
        //appRater = IAppRater(minLaunches: 10,
        //                     minDays: 15,
        //                     rateWndType: .standardAlert
        //)
        
        // if we need custom display logic
        appRater = IAppRater(minLaunches: 10,
                             minDays: 15,
                             other: { _ in Stats.shared.sessions.count > 100 },
                             rateWndType: .standardAlert
        )
        
        // if we need to show request on app run:
        // appRater.requestIfNeeded()
        // and other code does not needed
    }
}
```

// We can locate button to open some panel
```swift
struct MainView : View {
    var body: some View {
        VStack {
            MyMainViewBody()
            
            if AppDelegate.shared.appRater.isNeededToRate() {
                Button("Rate my app") { model.showBottomPanel.toggle() }
            } 
        }
    }
}
```

// We can locate button  to show "Rate my app" alert
```swift
struct MainView : View {
    var body: some View {
        VStack {
            MyMainViewBody()
            
            if AppDelegate.shared.appRater.isNeededToRate() {
                Button("Rate my app") { AppDelegate.shared.appRater.requestIfNeeded() }
            } 
        }
    }
}
```


// We can open standard OS's alert

<img src="https://i.sstatic.net/A2gyxsA8.png" width="500" height="200">

<img src="https://koenig-media.raywenderlich.com/uploads/2018/10/Simulator-Screen-Shot-iPhone-8-2018-10-27-at-16.39.08.png" height="550">

// Or we can call appStore's alert "Rate my app" 
```swift
appRater = IAppRater(...., rateWndType: .appStoreWnd(appId: "1473808464") )
```
<img src="https://i.sstatic.net/IYdbRLUW.png" width="500">

## Extra custom logic for display panel witn "Rate My App" button:
```swift
appRater = IAppRater(minLaunches: 2,
                     minDays: 2,
                     other: { me in // 0
                        (MainViewModel.shared.appState == .Idle || MainViewModel.shared.appState == .Paused) && // 1
                            Stats.shared.sessions.map{ $0.duration }.sum() > TimeInterval(hrs: 5) && // 2
                            me.lastReviewDate == nil // 3
                     },
                     rateWndType: .appStoreWnd(appId: "1473808464")
                    )
```
* - min app launches = 2
* - min days after first app launch = 3
* 0 - me = input of IAppRater's "self" for using some properties if needed for some custom purposes with them
* 1 - if application state is .idle or .paused
* 2 - if some sessions duration is larger than 5 hrs
* 3 - if user have never did rate the app. But if he is rated at least once - never show "rate app" button to user

### if you need to debug your "isNeededToRate()" value - you able to set input parameter
