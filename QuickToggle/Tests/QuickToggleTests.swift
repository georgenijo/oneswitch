import XCTest
@testable import QuickToggle

final class QuickToggleTests: XCTestCase {
    func testToggleTypeDisplayNames() {
        XCTAssertEqual(ToggleType.darkMode.displayName, "Dark Mode")
        XCTAssertEqual(ToggleType.keepAwake.displayName, "Keep Awake")
    }
    
    func testToggleTypeIsAction() {
        XCTAssertTrue(ToggleType.screenLock.isAction)
        XCTAssertTrue(ToggleType.emptyTrash.isAction)
        XCTAssertFalse(ToggleType.darkMode.isAction)
    }
}