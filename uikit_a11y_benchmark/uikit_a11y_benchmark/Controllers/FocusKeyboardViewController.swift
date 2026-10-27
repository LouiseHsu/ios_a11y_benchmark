import UIKit
import os

final class FocusKeyboardViewController: UIViewController {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "FocusKeyboard")

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let topTextField = FocusLoggingTextField(fieldName: "Top Username Field")
    private let sliderValueLabel = UILabel()
    private let slider = FocusLoggingSlider(controlName: "Benchmark Slider")
    private let bottomTextField = FocusLoggingTextField(fieldName: "Bottom Password Field")
    private let eventLogTextView = UITextView()

    private var logEntries: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Focus & Keyboard"
        view.backgroundColor = .systemBackground

        configureNavigationItems()
        configureViews()
        registerNotifications()
        appendLog("Ready. Top field pre-filled, slider at 25%, bottom field is secure.")
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        let previous = describeElement(context.previouslyFocusedItem)
        let next = describeElement(context.nextFocusedItem)
        appendLog("FKA didUpdateFocusIn: \(previous) -> \(next)")
    }

    private func configureNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Dismiss Keyboard",
            style: .plain,
            target: self,
            action: #selector(dismissKeyboard)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "focus.dismissKeyboardButton"
    }

    private func configureViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "focus.scrollView"
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
            identifier: "focus.topTextField",
            placeholder: "Enter username",
            initialText: "A",
            isSecure: false
        )

        // UISlider between the two TextFields initialized to value = 0.25 (25%)
        sliderValueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        sliderValueLabel.text = "Slider Value: 0.25 (25%)"
        sliderValueLabel.accessibilityIdentifier = "focus.sliderValueLabel"

        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.25
        slider.accessibilityIdentifier = "focus.slider"
        slider.accessibilityLabel = "Volume Benchmark Slider"
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.onFocusEvent = { [weak self] eventMessage in
            self?.appendLog(eventMessage)
        }

        // Bottom UITextField: isSecureTextEntry = true and placeholder "Password"
        configureTextField(
            bottomTextField,
            identifier: "focus.bottomTextField",
            placeholder: "Password",
            initialText: "",
            isSecure: true
        )

        eventLogTextView.translatesAutoresizingMaskIntoConstraints = false
        eventLogTextView.isEditable = false
        eventLogTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventLogTextView.backgroundColor = .secondarySystemBackground
        eventLogTextView.layer.cornerRadius = 8
        eventLogTextView.accessibilityIdentifier = "focus.eventLog"
        // Tall log region ensures top and bottom text fields are separated by enough
        // vertical spacing to require scrolling.
        eventLogTextView.heightAnchor.constraint(equalToConstant: 520).isActive = true

        contentStackView.addArrangedSubview(makeLabel("Top Input Region (Pre-filled + Placeholder)"))
        contentStackView.addArrangedSubview(topTextField)
        contentStackView.addArrangedSubview(makeLabel("Intermediate Slider (Initial Value 25%)"))
        contentStackView.addArrangedSubview(sliderValueLabel)
        contentStackView.addArrangedSubview(slider)
        contentStackView.addArrangedSubview(makeLabel("Responder, VoiceOver & FKA Focus Log"))
        contentStackView.addArrangedSubview(eventLogTextView)
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
        _ textField: FocusLoggingTextField,
        identifier: String,
        placeholder: String,
        initialText: String,
        isSecure: Bool
    ) {
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.text = initialText
        textField.isSecureTextEntry = isSecure
        textField.clearButtonMode = .whileEditing
        textField.accessibilityIdentifier = identifier
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        textField.onFocusEvent = { [weak self] eventMessage in
            self?.appendLog(eventMessage)
        }
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
            selector: #selector(handleAccessibilityElementFocused(_:)),
            name: UIAccessibility.elementFocusedNotification,
            object: nil
        )
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
        appendLog(String(format: "Slider valueChanged: %.2f (%d%%)", sender.value, percentage))
    }

    @objc private func textFieldEditingChanged(_ sender: UITextField) {
        let name = (sender as? FocusLoggingTextField)?.fieldName ?? "TextField"
        let isEmpty = (sender.text ?? "").isEmpty
        appendLog(
            "\(name) text changed (isEmpty=\(isEmpty), placeholder='\(sender.placeholder ?? "")')"
        )
    }

    @objc private func handleAccessibilityElementFocused(_ notification: Notification) {
        let focusedElement = notification.userInfo?[UIAccessibility.focusedElementUserInfoKey]
        let unfocusedElement = notification.userInfo?[UIAccessibility.unfocusedElementUserInfoKey]
        let focusedDescription = describeElement(focusedElement)
        let unfocusedDescription = describeElement(unfocusedElement)
        appendLog("VO Notification: focused=\(focusedDescription), unfocused=\(unfocusedDescription)")
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

    private func describeElement(_ element: Any?) -> String {
        guard let object = element as? NSObject else { return "none" }
        if let field = object as? FocusLoggingTextField {
            return field.fieldName
        }
        if let sliderControl = object as? FocusLoggingSlider {
            return sliderControl.controlName
        }
        return object.accessibilityLabel ?? String(describing: type(of: object))
    }

    private func appendLog(_ entry: String) {
        Self.logger.info("[FocusKeyboard] \(entry, privacy: .public)")
        print("[FocusKeyboard] \(entry)")
        logEntries.append(entry)
        eventLogTextView.text = logEntries.joined(separator: "\n")
    }
}

// MARK: - UITextFieldDelegate

extension FocusKeyboardViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - FocusLoggingTextField

final class FocusLoggingTextField: UITextField {

    let fieldName: String
    var onFocusEvent: ((String) -> Void)?

    init(fieldName: String) {
        self.fieldName = fieldName
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        if didBecome {
            onFocusEvent?("becomeFirstResponder: \(fieldName) (secure=\(isSecureTextEntry))")
        }
        return didBecome
    }

    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign {
            onFocusEvent?("resignFirstResponder: \(fieldName)")
        }
        return didResign
    }

    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        onFocusEvent?("accessibilityElementDidBecomeFocused: \(fieldName)")
    }

    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        onFocusEvent?("accessibilityElementDidLoseFocus: \(fieldName)")
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        if context.nextFocusedItem === self {
            onFocusEvent?("didUpdateFocusIn (gained): \(fieldName)")
        } else if context.previouslyFocusedItem === self {
            onFocusEvent?("didUpdateFocusIn (lost): \(fieldName)")
        }
    }
}

// MARK: - FocusLoggingSlider

final class FocusLoggingSlider: UISlider {

    let controlName: String
    var onFocusEvent: ((String) -> Void)?

    init(controlName: String) {
        self.controlName = controlName
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFocused: Bool {
        return true
    }

    override func accessibilityIncrement() {
        super.accessibilityIncrement()
        sendActions(for: .valueChanged)
        onFocusEvent?(String(format: "accessibilityIncrement: \(controlName) -> %.2f", value))
    }

    override func accessibilityDecrement() {
        super.accessibilityDecrement()
        sendActions(for: .valueChanged)
        onFocusEvent?(String(format: "accessibilityDecrement: \(controlName) -> %.2f", value))
    }

    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        onFocusEvent?(String(format: "accessibilityElementDidBecomeFocused: \(controlName) (value=%.2f)", value))
    }

    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        onFocusEvent?("accessibilityElementDidLoseFocus: \(controlName)")
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        if context.nextFocusedItem === self {
            onFocusEvent?(String(format: "didUpdateFocusIn (gained): \(controlName) (value=%.2f)", value))
        } else if context.previouslyFocusedItem === self {
            onFocusEvent?("didUpdateFocusIn (lost): \(controlName)")
        }
    }
}
