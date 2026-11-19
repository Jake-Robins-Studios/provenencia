import AppKit
import Foundation
import Testing
@testable import Provenencia

@Suite @MainActor
struct AppLaunchTests {
    @Test func hostRunsTheTestApp() {
        #expect(ProvenenciaMain.isTestHost)
        #expect(NSApplication.shared.activationPolicy() == .accessory)
    }

    @Test func noWindowIsVisible() {
        let visible = NSApplication.shared.windows.filter(\.isVisible)
        #expect(visible.isEmpty)
    }

    @Test func closingTheWindowQuits() {
        let delegate = ProvenenciaAppDelegate()
        #expect(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }

    @Test func launchTurnsOffWindowTabs() {
        let before = NSWindow.allowsAutomaticWindowTabbing
        defer { NSWindow.allowsAutomaticWindowTabbing = before }
        NSWindow.allowsAutomaticWindowTabbing = true
        ProvenenciaAppDelegate().applicationWillFinishLaunching(
            Notification(name: NSApplication.willFinishLaunchingNotification)
        )
        #expect(!NSWindow.allowsAutomaticWindowTabbing)
    }
}
