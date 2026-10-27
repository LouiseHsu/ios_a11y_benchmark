import XCTest

final class UIKitA11yBenchmarkUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testScrollBaselineUpdatesContentOffsetAndDelta() throws {
        let app = XCUIApplication()
        app.launch()

        let scrollBaselineCell = app.cells["menu.scrollBaseline"]
        XCTAssertTrue(scrollBaselineCell.waitForExistence(timeout: 5))
        scrollBaselineCell.tap()

        let tableView = app.tables["scroll.tableView"]
        XCTAssertTrue(tableView.waitForExistence(timeout: 5))

        let offsetYLabel = app.staticTexts["scroll.offsetYLabel"]
        let heightLabel = app.staticTexts["scroll.heightLabel"]
        let deltaLabel = app.staticTexts["scroll.deltaLabel"]
        let ratioLabel = app.staticTexts["scroll.ratioLabel"]

        XCTAssertTrue(offsetYLabel.exists)
        XCTAssertTrue(heightLabel.exists)
        XCTAssertTrue(deltaLabel.exists)
        XCTAssertTrue(ratioLabel.exists)

        let initialHeight = Double(heightLabel.value as? String ?? "0") ?? 0
        XCTAssertGreaterThan(initialHeight, 0, "Table view frame.size.height should be greater than 0")

        let initialOffsetY = Double(offsetYLabel.value as? String ?? "0") ?? 0
        XCTAssertEqual(initialOffsetY, 0, accuracy: 1.0)

        tableView.swipeUp()

        let scrolledOffsetY = Double(offsetYLabel.value as? String ?? "0") ?? 0
        let deltaY = Double(deltaLabel.value as? String ?? "0") ?? 0
        let ratio = Double(ratioLabel.value as? String ?? "0") ?? 0

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

        let modalBarrierCell = app.cells["menu.modalBarrier"]
        XCTAssertTrue(modalBarrierCell.waitForExistence(timeout: 5))
        modalBarrierCell.tap()

        let backgroundButton1 = app.buttons["modal.backgroundButton1"]
        let backgroundButton2 = app.buttons["modal.backgroundButton2"]
        let presentButton = app.buttons["modal.presentButton"]

        XCTAssertTrue(backgroundButton1.waitForExistence(timeout: 5))
        XCTAssertTrue(backgroundButton2.exists)
        XCTAssertTrue(presentButton.exists)
        XCTAssertTrue(backgroundButton1.isHittable)
        XCTAssertTrue(backgroundButton2.isHittable)

        presentButton.tap()

        let sheetTitle = app.staticTexts["modal.sheetTitle"]
        let dismissButton = app.buttons["modal.dismissButton"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(dismissButton.exists)
        XCTAssertTrue(dismissButton.isHittable)

        // With accessibilityViewIsModal = true on the presented modal sheet,
        // background buttons are isolated from the accessibility hierarchy.
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
            backgroundButton1.waitForExistence(timeout: 5),
            "Background Button 1 should be accessible again after modal dismissal"
        )
        XCTAssertTrue(backgroundButton1.isHittable)
        XCTAssertTrue(backgroundButton2.isHittable)
    }
}
