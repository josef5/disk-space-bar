//
//  DiskSpaceBarApp.swift
//  DiskSpaceBar
//
//  Created by Jose Espejo on 18/02/2026.
//

import SwiftUI

@main
struct DiskSpaceBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() } // Required to suppress default window
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Hide from Dock

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit DiskSpaceBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        updateDiskInfo()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDiskInfo()
        }
    }

    func updateDiskInfo() {
        guard
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
            //let total = attrs[.systemSize] as? Int64,
            let free = attrs[.systemFreeSize] as? Int64
        else {
            print("❌ Failed to read disk attributes")
            return
        }

        // let used = total - free
        // let label = "\(formatBytes(used)) / \(formatBytes(total))"
        let freeGB = Double(free) / 1_000_000_000
        let label = "\(formatBytes(free))"
        print("✅ Disk info: \(label)")

        let color: NSColor = freeGB < 1.0 ? .red : .labelColor

        let attributed = NSAttributedString(
            string: label,
            attributes: [.foregroundColor: color]
        )

        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.attributedTitle = attributed
                //button.title = label
                //button.title = "💾 \(label)"
            } else {
                print("❌ statusItem.button is nil")
            }
        }
    }

    func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        }
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.2f MB", mb)
    }
}
