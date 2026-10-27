import XCTest

/// Visual tour: launches into every destination and attaches full-screen
/// screenshots (exported from the `.xcresult` with
/// `xcrun xcresulttool export attachments`). Identical in both benchmark apps.
final class ScreenshotTourUITests: XCTestCase {

    private struct Stop {
        let menuIdentifier: String
        let readyIdentifier: String
        let name: String
        /// Optional interaction performed before a second screenshot is taken.
        let interaction: ((XCUIApplication) -> Void)?
        let interactionName: String?
    }

    private static let stops: [Stop] = [
        Stop(
            menuIdentifier: "menu.scrollBaseline",
            readyIdentifier: "scroll.offsetYLabel",
            name: "01_scroll_baseline",
            interaction: { app in app.swipeUp() },
            interactionName: "01b_scroll_baseline_after_swipe"
        ),
        Stop(
            menuIdentifier: "menu.traversalHierarchy",
            readyIdentifier: "traversal.statusLabel",
            name: "02_traversal_hierarchy",
            interaction: { app in
                app.descendants(matching: .any).matching(identifier: "traversal.buttonA").firstMatch.tap()
                app.descendants(matching: .any).matching(identifier: "traversal.buttonC").firstMatch.tap()
            },
            interactionName: "02b_traversal_buttonA_selected_buttonB_enabled"
        ),
        Stop(
            menuIdentifier: "menu.focusKeyboard",
            readyIdentifier: "focus.topTextField",
            name: "03_focus_keyboard",
            interaction: { app in
                app.descendants(matching: .any).matching(identifier: "focus.topTextField").firstMatch.tap()
            },
            interactionName: "03b_focus_keyboard_top_field_focused"
        ),
        Stop(
            menuIdentifier: "menu.modalBarrier",
            readyIdentifier: "modal.presentButton",
            name: "04_modal_barrier",
            interaction: { app in
                app.descendants(matching: .any).matching(identifier: "modal.presentButton").firstMatch.tap()
                _ = app.descendants(matching: .any).matching(identifier: "modal.sheetTitle").firstMatch
                    .waitForExistence(timeout: 10)
            },
            interactionName: "04b_modal_barrier_sheet_presented"
        ),
        Stop(
            menuIdentifier: "menu.customActions",
            readyIdentifier: "customActions.statusLabel",
            name: "05_custom_actions",
            interaction: nil,
            interactionName: nil
        ),
        Stop(
            menuIdentifier: "menu.compositeArena",
            readyIdentifier: "composite.launchModalButton",
            name: "06_composite_arena",
            interaction: { app in
                app.descendants(matching: .any).matching(identifier: "composite.textField.1").firstMatch.tap()
                app.descendants(matching: .any).matching(identifier: "composite.resignAndPresentButton").firstMatch.tap()
                _ = app.descendants(matching: .any).matching(identifier: "composite.alertOkButton").firstMatch
                    .waitForExistence(timeout: 10)
            },
            interactionName: "06b_composite_arena_alert_after_unfocus"
        ),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureEveryScreen() throws {
        let app = XCUIApplication()
        app.launch()
        let menuItem = app.descendants(matching: .any).matching(identifier: "menu.scrollBaseline").firstMatch
        XCTAssertTrue(menuItem.waitForExistence(timeout: 30))
        sleep(1)
        attachScreenshot(named: "00_menu")

        for stop in Self.stops {
            app.launch()
            let item = app.descendants(matching: .any).matching(identifier: stop.menuIdentifier).firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 30), stop.menuIdentifier)
            item.tap()

            let ready = app.descendants(matching: .any).matching(identifier: stop.readyIdentifier).firstMatch
            XCTAssertTrue(ready.waitForExistence(timeout: 10), stop.readyIdentifier)
            sleep(1)
            attachScreenshot(named: stop.name)

            if let interaction = stop.interaction, let interactionName = stop.interactionName {
                interaction(app)
                sleep(1)
                attachScreenshot(named: interactionName)
            }
        }
    }
}
