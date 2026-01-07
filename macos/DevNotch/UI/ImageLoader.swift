//
//  ImageLoader.swift
//  DevNotch
//
//  Created on 2026-01-07.
//

import AppKit

struct ImageLoader {
    /// Load Copilot icon from bundle resources
    static func loadCopilotIcon(asTemplate: Bool = false) -> NSImage? {
        // Load from resource bundle
        if let resourcePath = Bundle.main.resourcePath {
            let imagePath = "\(resourcePath)/DevNotch_DevNotch.bundle/Contents/Resources/copilot-32.png"
            if let image = NSImage(contentsOfFile: imagePath) {
                if asTemplate {
                    image.isTemplate = true
                }
                return image
            }
        }
        
        // Fallback
        if let image = Bundle.main.image(forResource: "copilot-32") {
            if asTemplate {
                image.isTemplate = true
            }
            return image
        }
        
        return nil
    }
}
