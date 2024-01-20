import AppKit

final class ConfigurationWindowController: NSWindowController {

	// MARK: - NSWindowController

	override var windowNibName: String {
		return "Configuration"
	}


	// MARK: - Action

	@IBAction func close(_ sender: Any?) {
        // Now close the sheet (this works on older macOS versions too)
        window?.sheetParent?.endSheet(window!)
	}
}
