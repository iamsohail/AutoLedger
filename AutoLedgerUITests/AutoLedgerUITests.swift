import XCTest

final class AutoLedgerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Teardown code
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Test onboarding screen appears for new users
    }
}
