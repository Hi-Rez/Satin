//
//  AppDelegate.swift
//  Example
//
//  Created by Haris Ali on 4/8/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Cocoa
import MetalKit

import Forge

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var viewController: Forge.ViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {        
        let window = NSWindow(
            contentRect: NSRect(origin: CGPoint(x: 100.0, y: 400.0), size: CGSize(width: 512, height: 512)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        self.window = window
        self.viewController = Forge.ViewController(nibName: .init("ViewController"), bundle: Bundle(for: Forge.ViewController.self))
        guard let view = self.viewController?.view else { return }
        self.viewController.renderer = Renderer(metalKitView: view as! MTKView)
        guard let contentView = window.contentView else { return }
        
        view.frame = contentView.bounds
        view.autoresizingMask = [.width, .height]
        contentView.addSubview(view)
        
        window.setFrameAutosaveName("Template")
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.viewController?.view.removeFromSuperview()
        self.viewController = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

