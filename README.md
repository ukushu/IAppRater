# IAppRater 

<img src="https://github.com/ukushu/IAppRater/blob/main/IAppRaterLogo.png" width="170">


Tiny lib to show "Rate my app" alert for macOS and iOS apps.

## SupportedOS:
iOS(?), MacOS(>=12)

## KeyFeatures:
* Ability to set minimal amount of app launches before yout app perform request to rate your app
*  --//-- minimum days of usage --//--
* Do not ask to rate your app if this version already was rated by user
* Ability to open standard "Rate Me" alert and as alternative open "Rate me" popup inside of AppStore window
* Ability to work with custom logic like "Show "Rate my app" button only if rate is needed"
* Ability to set additional rules for "rate is needed" state :)


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

// We can locate button to open Rate my app alert window
```swift
struct MainView : View {
    var body: some View {
        VStack {
            MyMainViewBody()
            
            if AppDelegate.shared.appRater.isNeeded {
                Button("Rate my app") { model.showBottomPanel.toggle() }
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

## Extra difficult logic for display panel witn "Rate My App" button:
```swift
appRater = IAppRater(minLaunches: 2,
                     minDays: 3,
                     other: { me in
                        (MainViewModel.shared.appState == .Idle || MainViewModel.shared.appState == .Paused) && // 1
                            Stats.shared.sessionsLaterThan(date: me.firstLaunchDate).map{ $0.duration }.sum() > TimeInterval(mins: 5) && //2
                            me.lastReviewDate == nil // 3
                     },
                     rateWndType: .appStoreWnd(appId: "1473808464")
)
        
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
* 0 - input of IAppRater's "self" for using some properties if needed for some custom purposes with them
* 1 - if application state is .idle or .paused
* 2 - if some sessions duration is larger than 5 hrs (had made after `appRater.firstLaunchDate` )
* 3 - if user have never rated app. But if he is rated at least once - never show "rate app" button to user


## 🇺🇦🇺🇦🇺🇦 UKRAINE NEEDS YOUR SUPPORT! 🇺🇦🇺🇦🇺🇦

Mariupol city before Russia invasion (2021):
<img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmistomariupol.com.ua%2Fwp-content%2Fuploads%2F2021%2F03%2Fdji_0301.mp4_snapshot_00.00.993-scaled.jpg" width="800" height="500">

Mariupol city after Russia invasion (2022):

( ruined almost all infrastructure )

<img src="https://www.ukrainianworldcongress.org/wp-content/uploads/2024/01/032522mariupol1_1920x1080.jpg" width="800" height="500">

<img src="https://truthout.org/app/uploads/2022/04/2022_0411-mariupol-ukraine-scaled.jpg" width="800" height="500">

Destruction of the Kakhovka Dam
==

Russia destroyed Kakhovka Dam in the early hours of 6 June 2023 in Kherson Oblast. This was the second-largest reservoir in Ukraine by area (2,155 km2 [832 sq mi]) and the largest by water volume (18.19 km3 [4.36 cu mi]).
According to Ukrainian military intelligence, Russian forces carried out "major mining" of the Kakhovka dam shortly after taking control in February 2022, and in April 2022 mined locks and supports and installed "tented trucks with explosives on the dam itself". In October 2022, the Foreign Minister of Moldova, Nicu Popescu, said that Ukraine had intercepted Russian missiles targeting a different dam, on the Dniester river. At the time, Ukrainian president Zelenskyy warned of Russian preparations to destroy the Kakhovka dam and blame Ukraine, and called for an international observation mission at the dam to prevent a potential catastrophe.

<img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftelegraf.com.ua%2Fstatic%2Fstorage%2Foriginals%2F0%2F63%2F007c82db0653baa77e7fb321b7dc0630.jpg" width="800" height="350">


The capacity of the Kakhovka reservoir was 18 million cubic meters of fresh water. 
==
This reservoir could have provided all people on the planet with fresh water for more than 2 years. And this water was lost. 

Not to mention the flooded residential areas and the environmental disaster caused by the washing away of cemeteries and desalination of water in the Black Sea.

<img src="https://upload.wikimedia.org/wikipedia/commons/c/c6/Ukrainereservoir_oli2_2023169.jpg" width="800" height="800">

