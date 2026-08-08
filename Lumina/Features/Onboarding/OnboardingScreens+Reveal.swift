import SwiftUI

extension OnboardingScreens {
    /// Step 7 — chart reveal. Calls the real `EphemerisService` with the
    /// captured `BirthData` and flips `OnboardingState.chartReady` on
    /// success. Falls through to a synthetic-ready path on
    /// `.missingConfiguration` so dev builds without Swiss Eph URL set
    /// can still complete onboarding.
    struct ChartReveal: View {
        @Bindable var state: OnboardingState

        @State private var error: LuminaError?
        @State private var inflight = false
        @State private var chart: NatalChart?

        var body: some View {
            VStack(spacing: LuminaSpacing.lg) {
                Spacer()
                if let error {
                    LuminaErrorState(error: error, onRetry: handleRetry, onCancel: handleCancel)
                } else if state.chartReady, let chart {
                    revealedSignature(chart)
                } else {
                    revealCircle
                    Spacer()
                    Text(revealCaption)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LuminaSpacing.lg)
                }
            }
            .padding(LuminaSpacing.lg)
            .task {
                await compute()
            }
        }

        private var revealCaption: String {
            if state.chartReady {
                return "Your chart is calculated and saved — explore the full wheel in the Chart tab."
            }
            if state.chartDeferred {
                // Don't leave a spinner captioned "Calculating…" when nothing
                // is in flight — say plainly what will happen instead.
                return "No problem — we'll work out your chart the next time you're online. Everything else is ready."
            }
            return "Calculating the exact planetary positions for your moment in time."
        }

        private var revealCircle: some View {
            Circle()
                .stroke(LuminaColors.inkBlack.opacity(0.15), lineWidth: 1)
                .frame(width: 240, height: 240)
                .overlay(
                    Group {
                        if state.chartReady {
                            Text("Your chart is ready")
                                .font(LuminaTypography.body)
                        } else {
                            ProgressView().tint(LuminaColors.celestialBlue)
                        }
                    }
                )
        }

        /// The first-impression wow-moment: their cosmic signature, ready to
        /// share the second it's computed (the onboarding virality hook).
        private func revealedSignature(_ chart: NatalChart) -> some View {
            let signature = CosmicSignatureMaker.make(from: chart)
            return VStack(spacing: LuminaSpacing.lg) {
                Text("Meet your chart")
                    .font(LuminaTypography.display)
                    .multilineTextAlignment(.center)
                VStack(spacing: LuminaSpacing.sm) {
                    Text(signature.headline)
                        .font(LuminaTypography.heading)
                        .multilineTextAlignment(.center)
                    Text(bigThreeLine(signature))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: LuminaSpacing.sm) {
                    Text("Share your signature")
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.celestialBlue)
                    ChartShareButton(chart: chart)
                }
                // Said once, up front, at the first reading anyone sees —
                // rather than only in a Settings footnote.
                EntertainmentDisclaimer()
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }

        private func bigThreeLine(_ signature: CosmicSignature) -> String {
            [
                signature.sunSign.map { "\($0) Sun" },
                signature.moonSign.map { "\($0) Moon" },
                signature.risingSign.map { "\($0) rising" },
            ]
            .compactMap { $0 }
            .joined(separator: " · ")
        }

        private func handleRetry() {
            Task { await compute() }
        }

        /// "Not now" — continue into the app without the chart rather than
        /// clearing the error back to a spinner that nothing will ever
        /// resolve. Today and Chart compute on demand, so nothing is lost
        /// but the reveal animation.
        private func handleCancel() {
            error = nil
            state.chartDeferred = true
        }

        private func compute() async {
            guard !state.chartReady, !inflight else { return }
            inflight = true
            defer { inflight = false }
            error = nil
            guard let birthData = state.makeBirthData() else {
                #if DEBUG
                // Simulator/dev paths without real coordinates — synthesise
                // so the flow stays exercisable.
                try? await Task.sleep(for: .milliseconds(800))
                state.chartReady = true
                #else
                // Release must never claim a chart it doesn't have. Without
                // coordinates there is nothing to compute; let the user
                // continue and fix their birth place in Settings.
                error = .missingConfiguration(key: "BirthData")
                Haptics.failure.play()
                #endif
                return
            }
            do {
                chart = try await ChartCache.shared.chart(for: birthData)
                state.chartReady = true
                Haptics.success.play()
            } catch let serviceError as EphemerisService.ServiceError where serviceError == .missingConfiguration {
                #if DEBUG
                // Dev build without Swiss Eph URL set — synthesise so
                // onboarding stays end-to-end testable.
                try? await Task.sleep(for: .milliseconds(800))
                state.chartReady = true
                #else
                // This branch used to fire in RELEASE too, unguarded: it slept
                // 800ms and set `chartReady = true`, so a user whose backend
                // was unreachable was shown "Your chart is ready", completed
                // onboarding, and then hit "App is mid-setup" on every tab.
                // Every other synthesised path in the app is `#if DEBUG`;
                // this one was the exception. Fail honestly instead.
                self.error = LuminaError.from(serviceError)
                Haptics.failure.play()
                #endif
            } catch {
                self.error = LuminaError.from(error)
                Haptics.failure.play()
            }
        }
    }
}
