import SwiftUI

extension OnboardingScreens {
    /// Step 7 — chart reveal. Calls the real `EphemerisService` with the
    /// captured `BirthData` and flips `OnboardingState.chartReady` on
    /// success. Falls through to a synthetic-ready path on
    /// `.missingConfiguration` so dev builds without Swiss Eph URL set
    /// can still complete onboarding.
    struct ChartReveal: View {
        @Bindable var state: OnboardingState
        let ephemeris: EphemerisService

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
                    Text(state.chartReady
                        ? "Your chart is calculated and saved — explore the full wheel in the Chart tab."
                        : "Calculating the exact planetary positions for your moment in time.")
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

        private func handleCancel() {
            error = nil
        }

        private func compute() async {
            guard !state.chartReady, !inflight else { return }
            inflight = true
            defer { inflight = false }
            error = nil
            guard let birthData = state.makeBirthData() else {
                // Without real coordinates (e.g. simulator paths or
                // missing-config dev builds) we don't fail the flow —
                // we synthesise readiness so the user can proceed.
                try? await Task.sleep(for: .milliseconds(800))
                state.chartReady = true
                return
            }
            do {
                chart = try await ephemeris.chart(for: birthData)
                state.chartReady = true
                Haptics.success.play()
            } catch let serviceError as EphemerisService.ServiceError where serviceError == .missingConfiguration {
                // Dev build without Swiss Eph URL set — synthesise so
                // onboarding stays end-to-end testable.
                try? await Task.sleep(for: .milliseconds(800))
                state.chartReady = true
            } catch {
                self.error = LuminaError.from(error)
                Haptics.failure.play()
            }
        }
    }
}
