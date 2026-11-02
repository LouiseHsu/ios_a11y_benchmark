import XCTest

/// Minimal smoke test. The benchmark is exercised by manual QA with
/// VoiceOver / Voice Control / Full Keyboard Access; the app deliberately
/// carries no accessibility identifiers, so this only verifies that it launches.
final class UIKitA11yBenchmarkUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesToMenu() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["UIKit A11y Benchmark"].waitForExistence(timeout: 5))
    }
}
