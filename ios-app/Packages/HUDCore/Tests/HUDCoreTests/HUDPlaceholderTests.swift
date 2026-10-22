import Testing
@testable import HUDCore

@Test func placeholderShowsDashInKilometresPerHour() {
    #expect(HUDPlaceholder.speedText == "—")
    #expect(HUDPlaceholder.unitText == "km/h")
}
