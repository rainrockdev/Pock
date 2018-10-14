//
//  GeneralPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Preferences
import Defaults
import LaunchAtLogin

final class GeneralPreferencePane: NSViewController, Preferenceable {
    
    /// UI
    @IBOutlet weak var versionLabel:                       NSTextField!
    @IBOutlet weak var notificationBadgeRefreshRatePicker: NSPopUpButton!
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    @IBOutlet weak var checkForUpdatesButton:              NSButton!
    
    /// Core
    private var appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Preferenceable
    let toolbarItemTitle: String   = "General"
    let toolbarItemIcon:  NSImage  = NSImage(named: NSImage.Name("pock-icon"))!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "GeneralPreferencePane")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadVersionNumber()
        self.populatePopUpButton()
        self.setupLaunchAtLoginCheckbox()
    }
    
    private func loadVersionNumber() {
        self.versionLabel.stringValue = appVersion
    }
    
    private func populatePopUpButton() {
        self.notificationBadgeRefreshRatePicker.removeAllItems()
        self.notificationBadgeRefreshRatePicker.addItems(withTitles: NotificationBadgeRefreshRateKeys.allCases.map({ $0.toString() }))
        self.notificationBadgeRefreshRatePicker.selectItem(withTitle: defaults[.notificationBadgeRefreshInterval].toString())
    }
    
    private func setupLaunchAtLoginCheckbox() {
        self.launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off
    }
    
    @IBAction private func didSelectNotificationBadgeRefreshRate(_: NSButton) {
        defaults[.notificationBadgeRefreshInterval] = NotificationBadgeRefreshRateKeys.allCases[self.notificationBadgeRefreshRatePicker.indexOfSelectedItem]
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNotificationBadgeRefreshRate, object: nil)
    }
    
    @IBAction private func didChangeLaunchAtLoginValue(button: NSButton) {
        LaunchAtLogin.isEnabled = button.state == .on
    }
    
    @IBAction private func checkForUpdates(_: NSButton) {
        
        self.checkForUpdatesButton.isEnabled = false
        self.checkForUpdatesButton.title     = "Checking..."
        
        let latestVersionURL: URL = URL(string: "http://pock.pigigaldi.com/api/latestRelease.json")!
        
        URLSession.shared.dataTask(with: latestVersionURL, completionHandler: { [weak self] data, response, error in
            guard let _self = self else { return }
            
            var buttonTitle: String = "Check for updates"; defer {
                DispatchQueue.main.async { [weak self] in
                    self?.checkForUpdatesButton.isEnabled = true
                    self?.checkForUpdatesButton.title     = buttonTitle
                }
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: String] {
                if let latestVersionNumber = json?["version_number"] {
                    if _self.appVersion < latestVersionNumber {
                        /// Show alert
                        DispatchQueue.main.sync {
                            let alert: NSAlert = NSAlert()
                            alert.messageText = "New version available!"
                            alert.informativeText = "Do you want to download version \"\(latestVersionNumber)\" now?"
                            alert.addButton(withTitle: "Download")
                            alert.addButton(withTitle: "Later")
                            alert.alertStyle = NSAlert.Style.informational
                            
                            alert.beginSheetModal(for: _self.view.window!, completionHandler: { modalResponse in
                                if modalResponse == .alertFirstButtonReturn {
                                    NSWorkspace.shared.open(URL(string: json!["download_link"]!)!)
                                }
                            })
                        }
                    }else {
                        buttonTitle = "Already on latest version"
                    }
                }
            }
            
        }).resume()
    }
}
