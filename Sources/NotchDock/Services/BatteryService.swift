import Combine
import Foundation
import IOKit.ps

@MainActor
final class BatteryService: ObservableObject {
    @Published private(set) var percent: Int?
    @Published private(set) var charging = false
    private var poller: AnyCancellable?
    var label: String { percent.map { "\($0)%" } ?? "Desktop" }
    var symbol: String {
        guard let percent else { return "desktopcomputer" }
        if charging { return "battery.100.bolt" }
        if percent < 15 { return "battery.0" }
        if percent < 40 { return "battery.25" }
        if percent < 65 { return "battery.50" }
        if percent < 90 { return "battery.75" }
        return "battery.100"
    }
    init() {
        refresh()
        poller = Timer.publish(every: 30, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.refresh() }
    }
    private func refresh() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            percent = nil; charging = false; return
        }
        for source in sources {
            guard let details = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  details[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = details[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = details[kIOPSMaxCapacityKey] as? Int, maximum > 0 else { continue }
            percent = min(100, max(0, Int(Double(current) / Double(maximum) * 100)))
            charging = details[kIOPSIsChargingKey] as? Bool ?? false
            return
        }
        percent = nil; charging = false
    }
}
