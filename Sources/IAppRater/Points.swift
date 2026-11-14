import Foundation

public struct PointsConfiguration {
    public let threshold: Double
    public let halfLifeDays: Int

    public init(threshold: Double, halfLifeDays: Int) {
        precondition(threshold.isFinite && threshold >= 0, "threshold must be finite and nonnegative")
        precondition(halfLifeDays > 0, "halfLifeDays must be positive")
        self.threshold = threshold
        self.halfLifeDays = halfLifeDays
    }
}

@available(macOS 12, *)
public extension IAppRater {
    private static let pointsLock = NSLock()

    var currentPoints: Double { pointsBalance }

    func pointsAdd(_ value: Double) {
        guard value.isFinite, value > 0 else { return }
        Self.pointsLock.lock()
        defer { Self.pointsLock.unlock() }
        let (balance, anchor) = decayedPoints
        let updatedBalance = balance + value
        guard updatedBalance.isFinite else { return }
        savePoints(updatedBalance, updatedAt: anchor)
    }

    func pointsRemove(_ value: Double) {
        guard value.isFinite, value > 0 else { return }
        Self.pointsLock.lock()
        defer { Self.pointsLock.unlock() }
        let (balance, anchor) = decayedPoints
        savePoints(max(0, balance - value), updatedAt: anchor)
    }

    func pointsReset() {
        Self.pointsLock.lock()
        defer { Self.pointsLock.unlock() }
        savePoints(0, updatedAt: Date())
    }

    private var pointsBalance: Double {
        Self.pointsLock.lock()
        defer { Self.pointsLock.unlock() }
        return decayedPoints.balance
    }

    private var decayedPoints: (balance: Double, anchor: Date) {
        let defaults = UserDefaults.standard
        let balance = defaults.double(forKey: "IAppRaterPoints")
        let updatedAt = defaults.object(forKey: "IAppRaterPointsUpdatedAt") as? Date ?? Date()
        guard let pointsConfiguration else { return (balance, updatedAt) }
        let elapsedDays = max(0, floor(Date().timeIntervalSince(updatedAt) / 86_400))
        let anchor = updatedAt.addingTimeInterval(elapsedDays * 86_400)
        let decayedBalance = balance * pow(0.5, elapsedDays / Double(pointsConfiguration.halfLifeDays))
        return (max(0, decayedBalance), anchor)
    }

    private func savePoints(_ value: Double, updatedAt: Date) {
        UserDefaults.standard.set(value, forKey: "IAppRaterPoints")
        UserDefaults.standard.set(updatedAt, forKey: "IAppRaterPointsUpdatedAt")
    }
}
