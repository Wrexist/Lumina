@testable import Lumina
import XCTest

/// Phase-8 channel-definition tests. The 36-channel table is hand-coded
/// so the schema-level invariants (every gate referenced by a channel
/// is owned by the right center, exactly 36 channels, no duplicates)
/// ride CI on every push.
final class HumanDesignChannelsTests: XCTestCase {
    func testThirtySixChannelsExist() {
        XCTAssertEqual(HumanDesignChannels.all.count, 36)
    }

    func testNoDuplicateChannels() {
        let ids = HumanDesignChannels.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate channel: \(ids)")
    }

    func testChannelEndpointsAreOwnedByDeclaredCenters() {
        for channel in HumanDesignChannels.all {
            XCTAssertTrue(
                channel.centerA.gates.contains(channel.gateA),
                "channel \(channel.id) names \(channel.centerA) but gate \(channel.gateA) belongs elsewhere"
            )
            XCTAssertTrue(
                channel.centerB.gates.contains(channel.gateB),
                "channel \(channel.id) names \(channel.centerB) but gate \(channel.gateB) belongs elsewhere"
            )
        }
    }

    @MainActor
    func testDefinedChannelsRequireBothGatesActivated() {
        let chart = BirthChartViewModel.sampleChart()
        let activation = HumanDesignActivation.compute(from: chart)
        let defined = HumanDesignChannels.defined(in: activation)
        for channel in defined {
            XCTAssertTrue(activation.activatedGates.contains(channel.gateA))
            XCTAssertTrue(activation.activatedGates.contains(channel.gateB))
        }
    }
}
