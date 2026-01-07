//
//  ImageLoader.swift
//  DevNotch
//
//  Created on 2026-01-07.
//

import AppKit

struct ImageLoader {
    /// Load Copilot icon from asset catalog (works in dev and packaged app)
    static func loadCopilotIcon(asTemplate: Bool = false) -> NSImage? {
        // Try multiple approaches to load the icon
        var image: NSImage?

        // 1. Try loading from SPM resource bundle (Bundle.module)
        image = Bundle.module.image(forResource: NSImage.Name("CopilotIcon"))

        // 2. Fallback: try NSImage(named:) which searches all bundles
        if image == nil {
            image = NSImage(named: "CopilotIcon")
        }

        // 3. Fallback: try main bundle
        if image == nil {
            image = Bundle.main.image(forResource: "CopilotIcon")
        }

        // 4. Final fallback: try loading PNG directly
        if image == nil {
            image = Bundle.module.image(forResource: "copilot-32")
        }

        guard let finalImage = image else {
            return nil
        }

        // Disable template mode to show original colors
        finalImage.isTemplate = asTemplate
        return finalImage
    }
}
