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
    
    // Keep a reference to the info item so we can update it
    var diskInfoMenuItem: NSMenuItem!
    @objc func noOp() {}

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Hide from Dock

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
            diskInfoMenuItem = NSMenuItem(title: "", action: #selector(noOp), keyEquivalent: "")
            diskInfoMenuItem.target = self
            menu.addItem(diskInfoMenuItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu

        updateDiskInfo()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDiskInfo()
        }
    }

    func updateDiskInfo() {
        guard
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
            let total = attrs[.systemSize] as? Int64,
            let free = attrs[.systemFreeSize] as? Int64
        else {
            print("❌ Failed to read disk attributes")
            return
        }

        let used = total - free
        let freeGB = Double(free) / 1_000_000_000
        let color: NSColor = freeGB < 1.0 ? .red : .labelColor
        
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 11, weight: .light)
        ]

        let infoText = "Free: \(formatBytes(free))   Used: \(formatBytes(used))   Total: \(formatBytes(total))"

        let barAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        
        print("✅ Disk info: \(formatBytes(free))")

        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.attributedTitle = NSAttributedString(string: "\(self.formatBytes(free))", attributes: barAttributes)
            }
            self.diskInfoMenuItem.attributedTitle = NSAttributedString(string: infoText, attributes: infoAttributes)
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
