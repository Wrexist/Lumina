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

        var body: some View {
            VStack(spacing: LuminaSpacing.lg) {
                Spacer()
                if let error {
                    LuminaErrorState(error: error, onRetry: handleRetry, onCancel: handleCancel)
                } else {
                    revealCircle
                    Spacer()
                    Text(state.chartReady
                        ? "The full animated chart wheel ships in Phase 4. For now your chart is computed and cached."
                        : "Crunching planetary positions for your moment in time.")
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
                _ = try await ephemeris.chart(for: birthData)
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
