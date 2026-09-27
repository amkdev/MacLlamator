//
//  AppDelegate.swift
//  MacLlamator
//

import AppKit

/// Adds a persistent menu bar (status bar) icon that toggles the main
/// window, and keeps that window alive when its close button is used so a
/// later click on the status item can simply reveal it again.
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?

    private static let mainWindowIdentifierPrefix = "main"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = Self.menuBarImage()
            button.action = #selector(toggleMainWindow)
            button.target = self
        }
        statusItem = item

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowDidBecomeMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    @objc private func handleWindowDidBecomeMain(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.identifier?.rawValue.hasPrefix(Self.mainWindowIdentifierPrefix) == true else { return }
        window.delegate = self
    }

    /// Hides the window instead of destroying it, so the status item always
    /// has a window to bring back.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    @objc private func toggleMainWindow() {
        guard let window = NSApp.windows.first(where: {
            $0.identifier?.rawValue.hasPrefix(Self.mainWindowIdentifierPrefix) == true
        }) else { return }

        if window.isVisible && NSApp.isActive {
            window.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    /// Uses a custom template image ("MenuBarIcon") if one has been added to
    /// the asset catalog; falls back to an SF Symbol otherwise. Custom
    /// artwork is re-centered with breathing room so it doesn't crowd
    /// neighboring status items, regardless of how tightly it was exported.
    private static func menuBarImage() -> NSImage? {
        if let custom = NSImage(named: "MenuBarIcon") {
            return Self.paddedTemplateImage(from: custom)
        }
        return NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "MacLlamator")
    }

    private static func paddedTemplateImage(
        from source: NSImage,
        canvasLength: CGFloat = 18,
        glyphScale: CGFloat = 0.75
    ) -> NSImage {
        let sourceSize = source.size
        let aspect = sourceSize.width > 0 ? sourceSize.height / sourceSize.width : 1
        let drawSize = NSSize(width: canvasLength * glyphScale, height: canvasLength * glyphScale * aspect)
        let origin = NSPoint(
            x: (canvasLength - drawSize.width) / 2,
            y: (canvasLength - drawSize.height) / 2
        )

        let padded = NSImage(size: NSSize(width: canvasLength, height: canvasLength))
        padded.lockFocus()
        source.draw(in: NSRect(origin: origin, size: drawSize), from: .zero, operation: .sourceOver, fraction: 1)
        padded.unlockFocus()
        padded.isTemplate = true
        return padded
    }
}
