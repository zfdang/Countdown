import Foundation
import ScreenSaver

final class CountdownView: ScreenSaverView {

	// MARK: - Properties
    var wasStopped = false

	private let placeholderLabel: Label = {
		let view = Label()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.stringValue = "Open Screen Saver Options to set your date.\n在设置里指定目标日期。"
		view.textColor = .white
		view.isHidden = true
		return view
	}()

	private let daysView: PlaceView = {
		let view = PlaceView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.detailTextLabel.stringValue = "DAYS(天)"
		return view
	}()

	private let hoursView: PlaceView = {
		let view = PlaceView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.detailTextLabel.stringValue = "HOURS(小时)"
		return view
	}()

	private let minutesView: PlaceView = {
		let view = PlaceView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.detailTextLabel.stringValue = "MINUTES(分)"
		return view
	}()

	private let secondsView: PlaceView = {
		let view = PlaceView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.detailTextLabel.stringValue = "SECONDS(秒)"
		return view
	}()

	private let placesView: NSStackView = {
		let view = NSStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isHidden = true
		return view
	}()

	private lazy var configurationWindowController: NSWindowController = {
		return ConfigurationWindowController()
	}()

	private var date: Date? {
		didSet {
			updateFonts()
		}
	}


	// MARK: - Initializers
	convenience init() {
		self.init(frame: .zero, isPreview: false)
	}

	override init!(frame: NSRect, isPreview: Bool) {
		super.init(frame: frame, isPreview: isPreview)
		initialize()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		initialize()
	}

	deinit {
        clearNotifications()
	}
	

    // MARK: - Lifecycle stuff
    override func startAnimation() {
        super.startAnimation()
    }

    override func stopAnimation() {
        super.stopAnimation()
        wasStopped = true
    }

	// MARK: - NSView
	override func draw(_ rect: NSRect) {
		NSColor.black.setFill()
		NSBezierPath.fill(bounds)
	}

	// If the screen saver changes size, update the font
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
		updateFonts()
	}

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        updateFonts()
    }


	// MARK: - ScreenSaverView
	override func animateOneFrame() {
        if(wasStopped) {
            // hide all texts
            placeholderLabel.isHidden = true
            placesView.isHidden = true
            return
        }
    
        // update content
		placeholderLabel.isHidden = date != nil
		placesView.isHidden = !placeholderLabel.isHidden

		guard let date = date else { return }

		let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: date)

		daysView.textLabel.stringValue = components.day.flatMap { String(format: "%02d", abs($0)) } ?? ""
        hoursView.textLabel.stringValue = components.hour.flatMap { String(format: "%02d", abs($0)) } ?? ""
        minutesView.textLabel.stringValue = components.minute.flatMap { String(format: "%02d", abs($0)) } ?? ""
        secondsView.textLabel.stringValue = components.second.flatMap { String(format: "%02d", abs($0)) } ?? ""
	}

    override var hasConfigureSheet: Bool {
        return true
    }

    override var configureSheet: NSWindow? {
        return configurationWindowController.window
    }


	// MARK: - Private

	/// Shared initializer
	private func initialize() {
		// Set animation time interval
		animationTimeInterval = 1 / 30

		// Recall preferences
		date = Preferences().date

		// Setup the views
		addSubview(placeholderLabel)

		placesView.addArrangedSubview(daysView)
		placesView.addArrangedSubview(hoursView)
		placesView.addArrangedSubview(minutesView)
		placesView.addArrangedSubview(secondsView)
		addSubview(placesView)

		updateFonts()

		addConstraints([
            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

			placesView.centerXAnchor.constraint(equalTo: centerXAnchor),
			placesView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])

		// Listen for configuration changes
        setNotifications();
	}

    func setNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(dateDidChange), name: .dateDidChange, object: nil)

        // https://mastodon.social/@jwz/111185848804264757
        // https://github.com/JohnCoates/Aerial/blob/master/Aerial/Source/Views/AerialView.swift
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(CountdownView.willStart(_:)),
            name: Notification.Name("com.apple.screensaver.willstart"), object: nil)
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(CountdownView.willStop(_:)),
            name: Notification.Name("com.apple.screensaver.willstop"), object: nil)
    }

    func clearNotifications() {
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default.removeObserver(self)
    }

    @objc func willStart(_ aNotification: Notification) {
        NSLog("willstart")
    }

    @objc func willStop(_ aNotification: Notification) {
        if #available(macOS 14.0, *) {
            exit(0)
        }
        NSLog("willStop")
        self.stopAnimation()
    }

	/// Date changed
	@objc private func dateDidChange(_ notification: NSNotification?) {
		date = Preferences().date
	}

	/// Update the font for the current size
	private func updateFonts() {
		placesView.spacing = floor(bounds.width * 0.05)

        placeholderLabel.font = font(withSize: floor(bounds.width / 30), isMonospace: false)

		let places = [daysView, hoursView, minutesView, secondsView]
        let textFont = font(withSize: round(bounds.width / 8), weight: .ultraLight)
        let detailTextFont = font(withSize: floor(bounds.width / 38))

		for place in places {
			place.textLabel.font = textFont
			place.detailTextLabel.font = detailTextFont
		}
	}

	/// Get a font
    private func font(withSize fontSize: CGFloat, weight: NSFont.Weight = .thin, isMonospace monospace: Bool = true) -> NSFont {
        let font = NSFont.systemFont(ofSize: fontSize, weight: weight)

		let fontDescriptor: NSFontDescriptor
		if monospace {
            fontDescriptor = font.fontDescriptor.addingAttributes([
                .featureSettings: [
					[
                        NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
                        NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector
					]
				]
			])
		} else {
			fontDescriptor = font.fontDescriptor
		}

		return NSFont(descriptor: fontDescriptor, size: max(4, fontSize))!
	}

}
