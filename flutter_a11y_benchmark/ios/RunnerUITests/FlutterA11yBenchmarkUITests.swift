import XCTest

/// XCUITests for the Flutter twin of `uikit_a11y_benchmark`.
///
/// The assertions are identical to `UIKitA11yBenchmarkUITests`; only the element
/// queries differ. Flutter exposes its semantics tree as `UIAccessibilityElement`s
/// (not `UITableViewCell`s / `UITableView`s), so elements are looked up by
/// `accessibilityIdentifier` (Flutter `SemanticsProperties.identifier`) across all
/// element types instead of `app.cells[...]` / `app.tables[...]`.
final class FlutterA11yBenchmarkUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func numericValue(of element: XCUIElement) -> Double {
        return Double(element.value as? String ?? "0") ?? 0
    }

    @MainActor
    func testScrollBaselineUpdatesContentOffsetAndDelta() throws {
        let app = XCUIApplication()
        app.launch()

        let scrollBaselineItem = element(app, "menu.scrollBaseline")
        XCTAssertTrue(scrollBaselineItem.waitForExistence(timeout: 30))
        scrollBaselineItem.tap()

        let offsetYLabel = element(app, "scroll.offsetYLabel")
        let heightLabel = element(app, "scroll.heightLabel")
        let deltaLabel = element(app, "scroll.deltaLabel")
        let ratioLabel = element(app, "scroll.ratioLabel")

        XCTAssertTrue(offsetYLabel.waitForExistence(timeout: 10))
        XCTAssertTrue(heightLabel.exists)
        XCTAssertTrue(deltaLabel.exists)
        XCTAssertTrue(ratioLabel.exists)

        let initialHeight = numericValue(of: heightLabel)
        XCTAssertGreaterThan(initialHeight, 0, "List viewport frame.size.height should be greater than 0")

        let initialOffsetY = numericValue(of: offsetYLabel)
        XCTAssertEqual(initialOffsetY, 0, accuracy: 1.0)

        // Swipe in the list area (the window centre is well below the pinned header).
        app.swipeUp()

        let scrolledOffsetY = numericValue(of: offsetYLabel)
        let deltaY = numericValue(of: deltaLabel)
        let ratio = numericValue(of: ratioLabel)

        XCTAssertGreaterThan(
            scrolledOffsetY,
            initialOffsetY,
            "contentOffset.y should increase after swiping up"
        )
        XCTAssertGreaterThan(
            deltaY,
            0,
            "Scroll Δy should be positive after scrolling down"
        )
        XCTAssertGreaterThan(
            ratio,
            0,
            "Δy / viewportHeight ratio should be positive after scrolling down"
        )
    }

    @MainActor
    func testModalBarrierIsolatesBackgroundButtons() throws {
        let app = XCUIApplication()
        app.launch()

        let modalBarrierItem = element(app, "menu.modalBarrier")
        XCTAssertTrue(modalBarrierItem.waitForExistence(timeout: 30))
        modalBarrierItem.tap()

        let backgroundButton1 = element(app, "modal.backgroundButton1")
        let backgroundButton2 = element(app, "modal.backgroundButton2")
        let presentButton = element(app, "modal.presentButton")

        XCTAssertTrue(backgroundButton1.waitForExistence(timeout: 10))
        XCTAssertTrue(backgroundButton2.exists)
        XCTAssertTrue(presentButton.exists)
        XCTAssertTrue(backgroundButton1.isHittable)
        XCTAssertTrue(backgroundButton2.isHittable)

        presentButton.tap()

        let sheetTitle = element(app, "modal.sheetTitle")
        let dismissButton = element(app, "modal.dismissButton")
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(dismissButton.exists)
        XCTAssertTrue(dismissButton.isHittable)

        // The modal route's BlockSemantics barrier (accessibilityViewIsModal twin)
        // must isolate the background buttons from the accessibility hierarchy.
        XCTAssertFalse(
            backgroundButton1.exists && backgroundButton1.isHittable,
            "Background Button 1 must be isolated while modal barrier is active"
        )
        XCTAssertFalse(
            backgroundButton2.exists && backgroundButton2.isHittable,
            "Background Button 2 must be isolated while modal barrier is active"
        )

        dismissButton.tap()

        XCTAssertTrue(
            backgroundButton1.waitForExistence(timeout: 10),
            "Background Button 1 should be accessible again after modal dismissal"
        )
        XCTAssertTrue(backgroundButton1.isHittable)
        XCTAssertTrue(backgroundButton2.isHittable)
    }
}
