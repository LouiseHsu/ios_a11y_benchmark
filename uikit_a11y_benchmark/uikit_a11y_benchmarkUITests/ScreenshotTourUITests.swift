import XCTest

/// Minimal smoke test. The former screenshot tour relied on accessibility
/// identifiers, which the benchmark app no longer carries; this only verifies
/// that the app launches to its menu.
final class ScreenshotTourUITests: XCTestCase {

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
