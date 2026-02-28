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

struct DiskReading {
    let date: Date
    let bytes: Int64
}

struct History {
    var diskReadings: [DiskReading] = []
    var spaceHigh: Int64?
    var spaceLow: Int64?
    var rate: Int64?
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    
    var diskInfoMenuItem: NSMenuItem!
    var history = History()
    let sampleSize = 3
    let interval = Double(60)
    
    // Noop function for menu item
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

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateDiskInfo()
        }
    }

    func updateDiskInfo() {
        guard
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
            let free = attrs[.systemFreeSize] as? Int64
        else {
            print("❌ Failed to read disk attributes")
            return
        }
        
        let freeGB = Double(free) / 1_000_000_000
        let color: NSColor = freeGB < 3.0 ? freeGB < 1.0 ? .systemRed : .systemOrange : .labelColor
        let barAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        
        updateHistory(currentFree: free)
        
        let infoText = textForDisplay(free: free, high: history.spaceHigh, low: history.spaceLow, rate: history.rate)
        
        print(infoText)

        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.attributedTitle = NSAttributedString(string: "\(self.formatBytes(free))", attributes: barAttributes)
            }
            self.diskInfoMenuItem.title = infoText
        }
    }
    
    func updateHistory(currentFree: Int64) {
        let now = Date()
        
        history.diskReadings.append(DiskReading(date: now, bytes: currentFree))
        
        history.spaceHigh = max(currentFree, history.spaceHigh ?? currentFree)
        history.spaceLow = min(currentFree, history.spaceLow ?? currentFree)
        
        if history.diskReadings.count >= sampleSize {
            let previous = history.diskReadings[history.diskReadings.count - sampleSize]
            let current = history.diskReadings.last
            
            if let current {
                history.rate = Int64((Double(current.bytes) - Double(previous.bytes)) / Double(sampleSize))
            }
            
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        
        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        }
        
        let mb = Double(bytes) / 1_000_000
        
        return String(format: "%.1f MB", mb)
    }
    
    func textForDisplay(free: Int64, high: Int64?, low: Int64?, rate: Int64? ) -> String {
        var rateDisplay = ""
        
        if let rate {
            let arrow = rate < 0 ? "↓" : "↑"
            rateDisplay = "\(arrow) \(formatBytes(rate))"
        } else {
            rateDisplay = "Calculating..."
        }
        
        return "Free: \(formatBytes(free)) High: \(formatBytes(high ?? 0)) Low: \(formatBytes(low ?? Int64.max)) Rate: \(rateDisplay)"
    }
}
