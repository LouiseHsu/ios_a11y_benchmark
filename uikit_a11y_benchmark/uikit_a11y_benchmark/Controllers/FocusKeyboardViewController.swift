import UIKit
import os

final class FocusKeyboardViewController: UIViewController {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "FocusKeyboard")

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let topTextField = UITextField()
    private let liveStatusLabel = UILabel()
    private let announceButton = UIButton(type: .system)
    private let sliderValueLabel = UILabel()
    private let slider = UISlider()
    private let bottomTextField = UITextField()
    private let lastEventLabel = UILabel()

    private var announcementCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Focus & Keyboard"
        view.backgroundColor = .systemBackground

        configureNavigationItems()
        configureViews()
        registerNotifications()
        recordEvent("Ready. Top field pre-filled, slider at 25%, bottom field is secure.")
    }

    private func configureNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Dismiss Keyboard",
            style: .plain,
            target: self,
            action: #selector(dismissKeyboard)
        )
    }

    private func configureViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        scrollView.addSubview(contentStackView)

        // Top UITextField: non-empty placeholder + pre-filled text so deleting last character
        // benchmarks empty-field placeholder announcements.
        configureTextField(
            topTextField,
            placeholder: "Enter username",
            initialText: "A",
            isSecure: false
        )

        // Live status banner + polite announcement trigger to benchmark announcement
        // contention during typing and focus changes.
        liveStatusLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        liveStatusLabel.textColor = .secondaryLabel
        liveStatusLabel.numberOfLines = 0
        liveStatusLabel.text = "Live Status: Username length 1 chars"
        // Not the usual native live-region idiom (apps normally post .announcement); kept because Flutter's liveRegion maps to this trait, so the twin shows what the embedder targets.
        liveStatusLabel.accessibilityTraits = .updatesFrequently

        var announceConfig = UIButton.Configuration.tinted()
        announceConfig.title = "Post Polite Announcement"
        announceButton.configuration = announceConfig
        announceButton.addTarget(
            self,
            action: #selector(postPoliteAnnouncement),
            for: .touchUpInside
        )

        // UISlider between the two TextFields initialized to value = 0.25 (25%)
        sliderValueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        sliderValueLabel.text = "Slider Value: 0.25 (25%)"

        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.25
        // UISlider has no title of its own; the name is developer intent.
        slider.accessibilityLabel = "Volume Benchmark Slider"
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)

        // Bottom UITextField: isSecureTextEntry = true and placeholder "Password"
        configureTextField(
            bottomTextField,
            placeholder: "Password",
            initialText: "",
            isSecure: true
        )

        lastEventLabel.translatesAutoresizingMaskIntoConstraints = false
        lastEventLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        lastEventLabel.numberOfLines = 0
        lastEventLabel.backgroundColor = .secondarySystemBackground
        lastEventLabel.layer.cornerRadius = 8
        lastEventLabel.layer.masksToBounds = true
        // Tall status region ensures top and bottom text fields are separated by enough
        // vertical spacing to require scrolling.
        lastEventLabel.heightAnchor.constraint(equalToConstant: 520).isActive = true

        contentStackView.addArrangedSubview(makeLabel("Top Input Region (Pre-filled + Placeholder)"))
        contentStackView.addArrangedSubview(topTextField)
        contentStackView.addArrangedSubview(liveStatusLabel)
        contentStackView.addArrangedSubview(announceButton)
        contentStackView.addArrangedSubview(makeLabel("Intermediate Slider (Initial Value 25%)"))
        contentStackView.addArrangedSubview(sliderValueLabel)
        contentStackView.addArrangedSubview(slider)
        contentStackView.addArrangedSubview(makeLabel("Last App Event"))
        contentStackView.addArrangedSubview(lastEventLabel)
        contentStackView.addArrangedSubview(makeLabel("Bottom Input Region (Secure Text Entry)"))
        contentStackView.addArrangedSubview(bottomTextField)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
        ])
    }

    private func configureTextField(
        _ textField: UITextField,
        placeholder: String,
        initialText: String,
        isSecure: Bool
    ) {
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.text = initialText
        textField.isSecureTextEntry = isSecure
        // .always on both twins: UIKit's .whileEditing (first responder) and
        // Flutter's OverlayVisibilityMode.editing (text non-empty) mean different
        // things, so .always is the only mode with identical behaviour.
        textField.clearButtonMode = .always
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        let percentage = Int((sender.value * 100).rounded())
        sliderValueLabel.text = String(format: "Slider Value: %.2f (%d%%)", sender.value, percentage)
        recordEvent(String(format: "Slider -> %.2f (%d%%)", sender.value, percentage))
    }

    @objc private func textFieldEditingChanged(_ sender: UITextField) {
        let name = sender === topTextField ? "Top Username Field" : "Bottom Password Field"
        let text = sender.text ?? ""
        let isEmpty = text.isEmpty
        recordEvent(
            "\(name) text changed (isEmpty=\(isEmpty), placeholder='\(sender.placeholder ?? "")')"
        )
        if sender === topTextField {
            let statusMessage = "Live Status: Username length \(text.count) chars"
            liveStatusLabel.text = statusMessage
            UIAccessibility.post(notification: .announcement, argument: statusMessage)
        }
    }

    @objc private func postPoliteAnnouncement() {
        announcementCount += 1
        let message = "Live Status: Polite Announcement #\(announcementCount)"
        liveStatusLabel.text = message
        UIAccessibility.post(notification: .announcement, argument: message)
        recordEvent("Posted polite announcement #\(announcementCount)")
    }

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard
            let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        let keyboardFrameInView = view.convert(frameValue.cgRectValue, from: view.window)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    private func recordEvent(_ entry: String) {
        Self.logger.info("[FocusKeyboard] \(entry, privacy: .public)")
        print("[FocusKeyboard] \(entry)")
        lastEventLabel.text = entry
    }
}

// MARK: - UITextFieldDelegate

extension FocusKeyboardViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
