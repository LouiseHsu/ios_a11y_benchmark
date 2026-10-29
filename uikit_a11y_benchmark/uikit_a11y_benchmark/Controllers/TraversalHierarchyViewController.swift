import UIKit
import os

final class TraversalHierarchyViewController: UIViewController, UITextViewDelegate {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "TraversalHierarchy")

    // The Flutter twin is a SingleChildScrollView; the v2 "Selection Controls"
    // section pushes the content past one screen (especially at AX text sizes),
    // so all content lives in a scroll view.
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let gridContainerView = TraversalGridContainerView()
    private let orderingControl = UISegmentedControl(items: ["Row-Major", "Column-Major"])
    private let disclosureHeaderButton = UIButton(type: .system)
    private let disclosureBodyLabel = UILabel()
    private let linksTextView = UITextView()
    private let statusLabel = UILabel()

    // "Selection Controls" section (Switch / Checkbox / Radio traits).
    private static let shippingSpeeds = ["Standard", "Express", "Overnight"]
    private let selectionControlsHeaderLabel = UILabel()
    private let notificationsLabel = UILabel()
    private let notificationsSwitch = UISwitch()
    private let acceptTermsButton = UIButton(configuration: .plain())
    private let shippingSpeedLabel = UILabel()
    private var shippingSpeedButtons: [UIButton] = []

    private var isDisclosureExpanded = false
    private var selectedShippingSpeed = TraversalHierarchyViewController.shippingSpeeds[0]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Traversal Hierarchy"
        view.backgroundColor = .systemBackground

        configureViews()
        configureSelectionControls()
        registerNotifications()
        updateOrderingStatus()
    }

    private func configureViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        orderingControl.translatesAutoresizingMaskIntoConstraints = false
        orderingControl.selectedSegmentIndex = 0
        orderingControl.accessibilityIdentifier = "traversal.orderingControl"
        orderingControl.addTarget(
            self,
            action: #selector(orderingChanged(_:)),
            for: .valueChanged
        )

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.accessibilityIdentifier = "traversal.statusLabel"

        gridContainerView.translatesAutoresizingMaskIntoConstraints = false
        gridContainerView.accessibilityIdentifier = "traversal.gridContainer"
        gridContainerView.onStatusEvent = { [weak self] eventMessage in
            self?.recordEvent(eventMessage)
        }

        disclosureHeaderButton.translatesAutoresizingMaskIntoConstraints = false
        disclosureHeaderButton.accessibilityIdentifier = "traversal.disclosureHeader"
        disclosureHeaderButton.accessibilityLabel = "Expandable Disclosure Section"
        disclosureHeaderButton.addTarget(
            self,
            action: #selector(toggleDisclosure),
            for: .touchUpInside
        )
        updateDisclosureAppearance()

        disclosureBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        disclosureBodyLabel.text = "Hidden detail content revealed when expanded."
        disclosureBodyLabel.font = .preferredFont(forTextStyle: .footnote)
        disclosureBodyLabel.textColor = .secondaryLabel
        disclosureBodyLabel.numberOfLines = 0
        disclosureBodyLabel.isHidden = true
        disclosureBodyLabel.accessibilityIdentifier = "traversal.disclosureBody"

        linksTextView.translatesAutoresizingMaskIntoConstraints = false
        linksTextView.isEditable = false
        linksTextView.isScrollEnabled = false
        linksTextView.backgroundColor = .clear
        linksTextView.textContainerInset = .zero
        linksTextView.textContainer.lineFragmentPadding = 0
        linksTextView.delegate = self
        linksTextView.accessibilityIdentifier = "traversal.linksParagraph"
        linksTextView.attributedText = makeLinksAttributedString()

        contentView.addSubview(orderingControl)
        contentView.addSubview(gridContainerView)
        contentView.addSubview(disclosureHeaderButton)
        contentView.addSubview(disclosureBodyLabel)
        contentView.addSubview(linksTextView)
        contentView.addSubview(statusLabel)

        // The scroll view's adjusted content inset already accounts for the
        // safe area, so the 16pt top margin is measured from contentView.top.
        NSLayoutConstraint.activate([
            orderingControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            orderingControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            orderingControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            gridContainerView.topAnchor.constraint(equalTo: orderingControl.bottomAnchor, constant: 20),
            gridContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gridContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            disclosureHeaderButton.topAnchor.constraint(equalTo: gridContainerView.bottomAnchor, constant: 16),
            disclosureHeaderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            disclosureHeaderButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            disclosureBodyLabel.topAnchor.constraint(equalTo: disclosureHeaderButton.bottomAnchor, constant: 6),
            disclosureBodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            disclosureBodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            linksTextView.topAnchor.constraint(equalTo: disclosureBodyLabel.bottomAnchor, constant: 12),
            linksTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            linksTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: linksTextView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Selection Controls (v2)

    /// Native twins of the Flutter Material selection controls:
    ///  * `Switch`        → `UISwitch` labelled by the row's `UILabel`.
    ///  * `Checkbox`      → iOS has NO checkbox control; nearest idiom is a
    ///                      tappable row with a checkmark image that toggles
    ///                      `isSelected` (so VoiceOver reports `.selected`).
    ///  * `Radio` group   → iOS has NO radio control; nearest idiom is a group
    ///                      of single-select rows with a checkmark accessory on
    ///                      the selected one (like a UITableView checkmark list).
    ///  * `DropdownMenu`  → `UIButton` pop-up menu (`showsMenuAsPrimaryAction` +
    ///                      `changesSelectionAsPrimaryAction`).
    private func configureSelectionControls() {
        selectionControlsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionControlsHeaderLabel.text = "Selection Controls"
        selectionControlsHeaderLabel.font = .preferredFont(forTextStyle: .headline)
        selectionControlsHeaderLabel.adjustsFontForContentSizeCategory = true
        selectionControlsHeaderLabel.accessibilityTraits = .header
        selectionControlsHeaderLabel.accessibilityIdentifier = "traversal.selectionControlsHeader"

        // 1. Switch row.
        notificationsLabel.text = "Notifications"
        notificationsLabel.font = .preferredFont(forTextStyle: .body)
        notificationsLabel.adjustsFontForContentSizeCategory = true
        // The visible label is folded into the switch's accessibilityLabel so
        // the row is one element, like a Settings-app switch cell.
        notificationsLabel.isAccessibilityElement = false

        notificationsSwitch.isOn = false
        notificationsSwitch.setContentHuggingPriority(.required, for: .horizontal)
        notificationsSwitch.accessibilityLabel = "Notifications"
        notificationsSwitch.accessibilityIdentifier = "traversal.notificationsSwitch"
        notificationsSwitch.addTarget(
            self,
            action: #selector(notificationsChanged(_:)),
            for: .valueChanged
        )

        let notificationsRow = UIStackView(arrangedSubviews: [notificationsLabel, notificationsSwitch])
        notificationsRow.translatesAutoresizingMaskIntoConstraints = false
        notificationsRow.axis = .horizontal
        notificationsRow.alignment = .center
        notificationsRow.distribution = .fill
        notificationsRow.spacing = 8

        // 2. Checkbox row (nearest idiom: checkmark toggle button).
        acceptTermsButton.translatesAutoresizingMaskIntoConstraints = false
        acceptTermsButton.contentHorizontalAlignment = .leading
        acceptTermsButton.accessibilityIdentifier = "traversal.acceptTermsCheckbox"
        acceptTermsButton.accessibilityLabel = "Accept Terms"
        acceptTermsButton.configurationUpdateHandler = { btn in
            var updated = btn.configuration ?? .plain()
            updated.title = "Accept Terms"
            updated.image = UIImage(systemName: btn.isSelected ? "checkmark.square.fill" : "square")
            updated.imagePlacement = .leading
            updated.imagePadding = 10
            updated.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
            updated.baseForegroundColor = .label
            updated.background.backgroundColor = .clear
            btn.configuration = updated
        }
        acceptTermsButton.addTarget(
            self,
            action: #selector(acceptTermsTapped(_:)),
            for: .touchUpInside
        )

        // 3. Radio group (nearest idiom: single-select rows with leading radio-circle SF Symbol).
        shippingSpeedLabel.translatesAutoresizingMaskIntoConstraints = false
        shippingSpeedLabel.text = "Shipping Speed"
        shippingSpeedLabel.font = .preferredFont(forTextStyle: .footnote)
        shippingSpeedLabel.adjustsFontForContentSizeCategory = true
        shippingSpeedLabel.textColor = .secondaryLabel
        shippingSpeedLabel.accessibilityIdentifier = "traversal.shippingSpeedLabel"

        let shippingStack = UIStackView()
        shippingStack.translatesAutoresizingMaskIntoConstraints = false
        shippingStack.axis = .vertical
        shippingStack.spacing = 2
        for (index, speed) in Self.shippingSpeeds.enumerated() {
            let button = UIButton(configuration: .plain())
            button.tag = index
            button.contentHorizontalAlignment = .leading
            button.accessibilityIdentifier = "traversal.radio\(speed)"
            button.accessibilityLabel = speed
            button.isSelected = (speed == selectedShippingSpeed)
            button.configurationUpdateHandler = { btn in
                var updated = btn.configuration ?? .plain()
                updated.title = speed
                updated.image = UIImage(
                    systemName: btn.isSelected ? "circle.inset.filled" : "circle"
                )
                updated.imagePlacement = .leading
                updated.imagePadding = 10
                updated.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
                updated.baseForegroundColor = .label
                updated.background.backgroundColor = .clear
                btn.configuration = updated
            }
            button.addTarget(
                self,
                action: #selector(shippingSpeedTapped(_:)),
                for: .touchUpInside
            )
            shippingSpeedButtons.append(button)
            shippingStack.addArrangedSubview(button)
        }

        contentView.addSubview(selectionControlsHeaderLabel)
        contentView.addSubview(notificationsRow)
        contentView.addSubview(acceptTermsButton)
        contentView.addSubview(shippingSpeedLabel)
        contentView.addSubview(shippingStack)

        NSLayoutConstraint.activate([
            selectionControlsHeaderLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            selectionControlsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectionControlsHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            notificationsRow.topAnchor.constraint(equalTo: selectionControlsHeaderLabel.bottomAnchor, constant: 8),
            notificationsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notificationsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            acceptTermsButton.topAnchor.constraint(equalTo: notificationsRow.bottomAnchor, constant: 8),
            acceptTermsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            acceptTermsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            shippingSpeedLabel.topAnchor.constraint(equalTo: acceptTermsButton.bottomAnchor, constant: 8),
            shippingSpeedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shippingSpeedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            shippingStack.topAnchor.constraint(equalTo: shippingSpeedLabel.bottomAnchor, constant: 4),
            shippingStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shippingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shippingStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    @objc private func notificationsChanged(_ sender: UISwitch) {
        recordEvent("Notifications switch -> \(sender.isOn ? "on" : "off")")
    }

    @objc private func acceptTermsTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.setNeedsUpdateConfiguration()
        recordEvent("Accept Terms checkbox -> \(sender.isSelected ? "checked" : "unchecked")")
    }

    @objc private func shippingSpeedTapped(_ sender: UIButton) {
        let speed = Self.shippingSpeeds[sender.tag]
        selectedShippingSpeed = speed
        for button in shippingSpeedButtons {
            button.isSelected = (button === sender)
            button.setNeedsUpdateConfiguration()
        }
        recordEvent("Shipping Speed radio -> \(speed)")
    }

    @objc private func toggleDisclosure() {
        isDisclosureExpanded.toggle()
        disclosureBodyLabel.isHidden = !isDisclosureExpanded
        updateDisclosureAppearance()
        let state = isDisclosureExpanded ? "Expanded" : "Collapsed"
        recordEvent("Disclosure toggled -> \(state)")
        UIAccessibility.post(notification: .layoutChanged, argument: disclosureHeaderButton)
    }

    private func updateDisclosureAppearance() {
        var config = UIButton.Configuration.bordered()
        config.title = "Expandable Disclosure Section"
        config.image = UIImage(systemName: isDisclosureExpanded ? "chevron.up" : "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        disclosureHeaderButton.configuration = config
        disclosureHeaderButton.accessibilityValue = isDisclosureExpanded ? "Expanded" : "Collapsed"
    }

    private func makeLinksAttributedString() -> NSAttributedString {
        let fullText = "Read our Terms of Service and Privacy Policy."
        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.label,
            ]
        )
        let nsString = fullText as NSString
        let termsRange = nsString.range(of: "Terms of Service")
        let privacyRange = nsString.range(of: "Privacy Policy")
        attributed.addAttribute(.link, value: URL(string: "benchmark://terms")!, range: termsRange)
        attributed.addAttribute(.link, value: URL(string: "benchmark://privacy")!, range: privacyRange)
        return attributed
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        let name = URL.host == "terms" ? "Terms of Service" : "Privacy Policy"
        recordEvent("Link Activated: \(name)")
        return false
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleElementFocused(_:)),
            name: UIAccessibility.elementFocusedNotification,
            object: nil
        )
    }

    @objc private func handleElementFocused(_ notification: Notification) {
        let focused = notification.userInfo?[UIAccessibility.focusedElementUserInfoKey] as? NSObject
        let label = focused?.accessibilityLabel ?? "none"
        Self.logger.info("[TraversalHierarchy] VoiceOver focused element: \(label, privacy: .public)")
    }

    @objc private func orderingChanged(_ sender: UISegmentedControl) {
        let mode: TraversalGridContainerView.TraversalMode =
            sender.selectedSegmentIndex == 0 ? .rowMajor : .columnMajor
        gridContainerView.traversalMode = mode
        updateOrderingStatus()
        UIAccessibility.post(notification: .layoutChanged, argument: gridContainerView)
    }

    private func updateOrderingStatus() {
        let mode = gridContainerView.traversalMode
        let detail = mode == .rowMajor
            ? "natural geometric order"
            : "explicit UIAccessibilityContainer order"
        recordEvent("Mode: \(mode.rawValue) (\(detail))")
    }

    private func recordEvent(_ message: String) {
        statusLabel.text = message
        Self.logger.info("[TraversalHierarchy] \(message, privacy: .public)")
        print("[TraversalHierarchy] \(message)")
    }
}

// MARK: - TraversalGridContainerView

final class TraversalGridContainerView: UIView {

    enum TraversalMode: String {
        case rowMajor = "Row-Major"
        case columnMajor = "Column-Major"
    }

    var traversalMode: TraversalMode = .rowMajor {
        didSet {
            rebuildAccessibilityOrder()
        }
    }

    var onStatusEvent: ((String) -> Void)?

    private let outerStack = UIStackView()
    private var rowStacks: [UIStackView] = []
    private var rowHeaderLabels: [UILabel] = []
    private var gridButtons: [[UIButton]] = []

    // Stateful buttons in Row 1 (indices [0][0], [0][1], [0][2]):
    // Button A: Mutating Icon Button
    // Button B: Target Enableable Button (starts disabled)
    // Button C: Toggle Button B
    private weak var buttonA: UIButton?
    private weak var buttonB: UIButton?
    private weak var buttonC: UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        setupHierarchy()
        rebuildAccessibilityOrder()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.axis = .vertical
        outerStack.spacing = 12
        addSubview(outerStack)

        for row in 0..<3 {
            let headerLabel = UILabel()
            headerLabel.text = "Section Header \(row + 1)"
            headerLabel.font = .preferredFont(forTextStyle: .headline)
            headerLabel.accessibilityTraits = .header
            headerLabel.accessibilityIdentifier = "traversal.header.\(row)"
            rowHeaderLabels.append(headerLabel)
            outerStack.addArrangedSubview(headerLabel)

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 8
            rowStacks.append(rowStack)

            var rowButtons: [UIButton] = []
            for col in 0..<3 {
                let button = makeGridButton(row: row, col: col)
                rowButtons.append(button)
                rowStack.addArrangedSubview(button)
            }
            gridButtons.append(rowButtons)
            outerStack.addArrangedSubview(rowStack)
        }

        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func makeGridButton(row: Int, col: Int) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.titleAlignment = .center
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.tag = row * 3 + col

        if row == 0 && col == 0 {
            // Button A ("Mutating Icon Button")
            button.accessibilityIdentifier = "traversal.buttonA"
            button.accessibilityLabel = "Mutating Icon Button"
            button.configurationUpdateHandler = { btn in
                var updated = btn.configuration ?? .tinted()
                updated.title = "Mutating Icon Button"
                updated.image = btn.isSelected ? UIImage(systemName: "checkmark") : nil
                updated.imagePlacement = .leading
                updated.imagePadding = 4
                btn.configuration = updated
            }
            button.addTarget(self, action: #selector(buttonATapped(_:)), for: .touchUpInside)
            buttonA = button
        } else if row == 0 && col == 1 {
            // Button B ("Target Enableable Button") - starts with isEnabled = false
            var bConfig = config
            bConfig.title = "Target Enableable Button"
            button.configuration = bConfig
            button.isEnabled = false
            button.accessibilityIdentifier = "traversal.buttonB"
            button.accessibilityLabel = "Target Enableable Button"
            button.addTarget(self, action: #selector(buttonBTapped(_:)), for: .touchUpInside)
            buttonB = button
        } else if row == 0 && col == 2 {
            // Button C ("Toggle Button B")
            var cConfig = config
            cConfig.title = "Toggle Button B"
            button.configuration = cConfig
            button.accessibilityIdentifier = "traversal.buttonC"
            button.accessibilityLabel = "Toggle Button B"
            button.addTarget(self, action: #selector(buttonCTapped(_:)), for: .touchUpInside)
            buttonC = button
        } else {
            var cellConfig = config
            cellConfig.title = "R\(row + 1)C\(col + 1)"
            button.configuration = cellConfig
            button.accessibilityLabel = "Grid Button Row \(row + 1) Column \(col + 1)"
            button.accessibilityIdentifier = "traversal.button.\(row).\(col)"
            button.addTarget(self, action: #selector(standardGridButtonTapped(_:)), for: .touchUpInside)
        }

        return button
    }

    @objc private func buttonATapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.setNeedsUpdateConfiguration()

        let focusedObject = UIAccessibility.focusedElement(using: nil) as AnyObject?
        let focusAnchoredOnA = (focusedObject === sender)
        let stateDescription = sender.isSelected ? "Selected (with checkmark)" : "Unselected (no icon)"
        onStatusEvent?(
            "Button A: \(stateDescription) | VO Focus Anchored on A: \(focusAnchoredOnA)"
        )
    }

    @objc private func buttonBTapped(_ sender: UIButton) {
        onStatusEvent?("Button B activated while enabled")
    }

    @objc private func buttonCTapped(_ sender: UIButton) {
        guard let buttonB else { return }
        buttonB.isEnabled.toggle()
        onStatusEvent?(
            "Button C toggled Button B -> isEnabled = \(buttonB.isEnabled)"
        )
    }

    @objc private func standardGridButtonTapped(_ sender: UIButton) {
        let row = sender.tag / 3 + 1
        let col = sender.tag % 3 + 1
        onStatusEvent?("Activated Grid Button R\(row)C\(col)")
    }

    private func rebuildAccessibilityOrder() {
        switch traversalMode {
        case .rowMajor:
            // Nil restores UIKit's default geometric/subview traversal order.
            accessibilityElements = nil
        case .columnMajor:
            var elements: [Any] = []
            for col in 0..<3 {
                elements.append(rowHeaderLabels[col])
                for row in 0..<3 {
                    elements.append(gridButtons[row][col])
                }
            }
            accessibilityElements = elements
        }
    }
}
