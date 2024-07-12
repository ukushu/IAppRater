#IAppRater 

Tiny lib to show "Rate my app" alert for macOS and iOS apps.

##SupportedOS:
iOS, MacOS

##KeyFeatures:
* Ability to set minimal amount of app launches before yout app perform request to rate your app
*  --//-- minimum days of usage --//--
* Do not ask to rate your app if this version already was rated by user
* Ability to open standard "Rate Me" alert and as alternative open "Rate me" popup inside of AppStore window
* Ability to work with custom logic like "show some button if need to rate"


## How to use, sample with SwiftUI:

//init custom AppDelegate
```
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
```
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
                             other: { Stats.shared.sessions.count > 100 },
                             rateWndType: .standardAlert
        )
        
        // if we need to show request on app run:
        // appRater.requestIfNeeded()
        // and other code does not needed
    }
}
```

// We can locate button to open Rate my app alert window
```
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

// We can open standard alert and 
[![Standard OS's "Rate my app" alert][1]][1]

// Or we can call appStore's alert "Rate my app" 
```
appRater = IAppRater(...., rateWndType: .appStoreWnd(appId: "1473808464") )
```

[![enter image description here][2]][2]


  [1]: https://i.sstatic.net/A2gyxsA8.png
  [2]: https://i.sstatic.net/IYdbRLUW.png
