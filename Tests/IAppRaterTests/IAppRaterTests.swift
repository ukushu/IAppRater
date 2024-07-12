import XCTest
@testable import IAppRater

final class IAppRaterTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.clear()
    }
    
    func testMinLaunches_1() throws {
        // launch 1
        var review = IAppRater.prefs_3_0() // item created firstly, so launchesCount == 1
        XCTAssertEqual(review.launchesCount, 1)
        XCTAssertNil(review.lastReviewDate)
        XCTAssertNil(review.lastReviewVersion)
        XCTAssertEqual(review.requestIfNeeded(), false)
        
        // Launch 2
        review = IAppRater.prefs_3_0()
        XCTAssertEqual(review.requestIfNeeded(), false)
        XCTAssertEqual(review.isNeededToRate, false)
        
        // Launch 3, need to show review window
        review = IAppRater.prefs_3_0()
        XCTAssertEqual(review.isNeededToRate, true)
        XCTAssertEqual(review.requestIfNeeded(), true)
        XCTAssertEqual(review.launchesCount, 3)
        XCTAssertNotNil(review.lastReviewDate)
        XCTAssertNotNil(review.lastReviewVersion)
        XCTAssertEqual(review.isNeededToRate, false)
        
        // Launch 4
        review = IAppRater.prefs_3_0()
        XCTAssertEqual(review.isNeededToRate, false)
        XCTAssertEqual(review.requestIfNeeded(), false)
        XCTAssertEqual(review.launchesCount, 4)
    }
    
    func testMinLaunches_2() throws {
        //1 = static init
        //2 and next = reinit125_0
        var review: IAppRater!
        
        for i in (1...124) {
            review = IAppRater.prefs_125_0()
            XCTAssertEqual(review.launchesCount, i)
            XCTAssertEqual(review.isNeededToRate, false)
            XCTAssertEqual(review.requestIfNeeded(), false)
        }
        
        //Day 125
        review = IAppRater.prefs_125_0()
        XCTAssertEqual(review.launchesCount, 125)
        XCTAssertEqual(review.isNeededToRate, true)
        XCTAssertEqual(review.requestIfNeeded(), true)
        
        //Day 126
        review = IAppRater.prefs_125_0()
        XCTAssertEqual(review.isNeededToRate, false)
        XCTAssertEqual(review.requestIfNeeded(), false)
        XCTAssertEqual(review.launchesCount, 126)
    }
    
    func testMinDays() throws {
        var review = IAppRater.prefs_3_0()
        // item created firstly, so launchesCount == 1
        XCTAssertEqual(review.launchesCount, 1)
        XCTAssertNotNil(review.firstLaunchDate)
        XCTAssertNil(review.lastReviewDate)
        XCTAssertNil(review.lastReviewVersion)
        
        review = IAppRater.prefs_3_125()
        
        // Launch 2
        XCTAssertFalse(review.requestIfNeeded())
        XCTAssertEqual(review.launchesCount, 2)
        XCTAssertNil(review.lastReviewDate)
        XCTAssertNil(review.lastReviewVersion)
        XCTAssertEqual(review.daysAfterFirstLaunch, 0)
        
        // Launch 3 in 4 days after first launch
        review = IAppRater.prefs_3_125()
        review.firstLaunchDate = Date.now.addingTimeInterval(TimeInterval(days: -4))
        XCTAssertEqual(review.launchesCount, 3)
        XCTAssertEqual(review.daysAfterFirstLaunch, 4)
        XCTAssertFalse(review.requestIfNeeded()) // we expecte request on 3d launch
        
        // Launch 4
        review = IAppRater.prefs_3_125()
        XCTAssertFalse(review.requestIfNeeded())
        XCTAssertEqual(review.launchesCount, 4)
        
        // Launch 4 in 124 days after first launch
        review.firstLaunchDate = Date.now.addingTimeInterval(TimeInterval(days: -124))
        XCTAssertEqual(review.launchesCount, 4)
        XCTAssertEqual(review.daysAfterFirstLaunch, 124)
        XCTAssertNil(review.lastReviewDate)
        XCTAssertNil(review.lastReviewVersion)
        XCTAssertEqual(review.isNeededToRate, false)
        XCTAssertFalse(review.requestIfNeeded())
        
        // Launch 4 in 125 days after last review
        review.lastReviewDate = Date.now.addingTimeInterval(TimeInterval(days:-125))
        XCTAssertEqual(review.daysAfterLastReview, 125)
        XCTAssertEqual(review.launchesCount, 4)
        XCTAssertEqual(review.isNeededToRate, true)
        XCTAssertEqual(review.requestIfNeeded(), true)
        XCTAssertEqual(review.isNeededToRate, false)
        XCTAssertFalse(review.requestIfNeeded())
        
        // app version is the same, so no need to show
        review.lastReviewVersion = appVersion
        review.lastReviewDate = Date.now.addingTimeInterval(TimeInterval(days:-125))
        XCTAssertEqual(review.launchesCount, 4)
        XCTAssertEqual(review.isNeededToRate, false)
        XCTAssertEqual(review.requestIfNeeded(), false)
        
        // app version changed, so need to show and lastReviewDate > 125 so need to show
        review.lastReviewVersion = "125.0.1"
        review.lastReviewDate = Date.now.addingTimeInterval(TimeInterval(days:-125))
        let lastReviewDate = review.lastReviewDate
        XCTAssertTrue(review.requestIfNeeded())
        XCTAssertEqual(review.launchesCount, 4)
        XCTAssertNotEqual(review.lastReviewDate, lastReviewDate)
    }
    
    func testCustomRules() throws {
        var review = IAppRater(minLaunches: 0, minDays: 0, other: { _ in true }, rateWndType: .standardAlert)
        
        XCTAssertEqual(review.isNeededToRate, true)
        
        review = IAppRater(minLaunches: 0, minDays: 0, other: { _ in false }, rateWndType: .standardAlert)
        
        XCTAssertEqual(review.isNeededToRate, false)
    }
}

fileprivate extension UserDefaults {
    func clear() {
        for key in dictionaryRepresentation().keys {
            removeObject(forKey: key)
        }
    }
}

fileprivate extension IAppRater {
    static func prefs_3_0() -> IAppRater {
        IAppRater(minLaunches: 3, minDays: 0, rateWndType: .standardAlert)
    }
    
    static func prefs_3_125() -> IAppRater {
        IAppRater(minLaunches: 3, minDays: 125, rateWndType: .standardAlert)
    }
    
    static func prefs_125_0() -> IAppRater {
        IAppRater(minLaunches: 125, minDays: 0, rateWndType: .standardAlert)
    }
}

fileprivate extension TimeInterval {
    init(days: Int = 0, hrs: Int = 0, mins: Int = 0, sec: Int = 0) {
        let timeInSec = (sec) + (mins * 60) + (hrs * 60 * 60) + (days * 24 * 60 * 60)
        self.init(timeInSec)
    }
}
