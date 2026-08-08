import Foundation
import MetricKit
import OSLog

/// Crash and hang reporting via MetricKit.
///
/// Before this, the app had no crash reporting of any kind — no Sentry, no
/// Crashlytics, no MetricKit — and `LuminaError.analyticsKey` computed a
/// stable key for an analytics system that was never built. If the app
/// crashed for a user after launch, the only signal would have been an App
/// Store review.
///
/// MetricKit is deliberately the choice here rather than a third-party SDK:
/// - It needs no vendor account, no API key, and no new dependency, so it
///   can ship now rather than waiting on provisioning.
/// - It adds nothing to Apple's "commonly used third-party SDK" signature and
///   privacy-manifest burden, which the alternatives all do.
/// - It collects no personal data, so the privacy manifest is unaffected.
///
/// The trade-off is that iOS delivers payloads at most once every 24 hours,
/// on device, and only after a relaunch — so this is post-hoc triage, not
/// live alerting. That is the right first step; a hosted service can layer on
/// later without changing the call sites.
///
/// Diagnostics are logged to the unified log by default. Set an
/// `LuminaDiagnosticsEndpoint` value in Info.plist to POST them somewhere.
@MainActor
final class CrashReporter: NSObject {
    static let shared = CrashReporter()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Diagnostics")

    private override init() {
        super.init()
    }

    /// Call once, from `AppDelegate`. Subscribing late means missing the
    /// payload iOS delivers shortly after launch.
    func start() {
        MXMetricManager.shared.add(self)
        logger.info("MetricKit diagnostics subscriber registered")
    }
}

extension CrashReporter: MXMetricManagerSubscriber {
    /// Crashes, hangs, disk-write exceptions and CPU exceptions.
    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let logger = Logger(subsystem: "app.lumina.ios", category: "Diagnostics")
        for payload in payloads {
            for crash in payload.crashDiagnostics ?? [] {
                logger.critical(
                    """
                    CRASH \(crash.metaData.applicationBuildVersion, privacy: .public) \
                    signal=\(crash.signal?.stringValue ?? "nil", privacy: .public) \
                    exception=\(crash.exceptionType?.stringValue ?? "nil", privacy: .public) \
                    code=\(crash.exceptionCode?.stringValue ?? "nil", privacy: .public) \
                    reason=\(crash.terminationReason ?? "nil", privacy: .public)
                    """
                )
            }
            for hang in payload.hangDiagnostics ?? [] {
                logger.error("HANG duration=\(hang.hangDuration.description, privacy: .public)")
            }
            for cpu in payload.cpuExceptionDiagnostics ?? [] {
                logger.error("CPU EXCEPTION time=\(cpu.totalCPUTime.description, privacy: .public)")
            }
            for disk in payload.diskWriteExceptionDiagnostics ?? [] {
                logger.error("DISK WRITE EXCEPTION \(disk.totalWritesCaused.description, privacy: .public)")
            }
            Self.forward(payload.jsonRepresentation(), kind: "diagnostic")
        }
    }

    /// Daily rollups — launch time, memory, battery, network.
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            Self.forward(payload.jsonRepresentation(), kind: "metric")
        }
    }

    /// POSTs a payload when an endpoint is configured; otherwise no-ops.
    /// Same "degrade rather than crash" contract every other service in the
    /// app follows when its config is absent.
    private nonisolated static func forward(_ json: Data, kind: String) {
        guard let raw = Bundle.main.infoDictionary?["LuminaDiagnosticsEndpoint"] as? String,
              !raw.isEmpty,
              !raw.hasPrefix("$("),
              let url = URL(string: raw) else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(kind, forHTTPHeaderField: "X-Lumina-Payload-Kind")
        request.httpBody = json
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request).resume()
    }
}
