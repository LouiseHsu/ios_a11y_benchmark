import UIKit
import os

final class TraversalHierarchyViewController: UIViewController, UITextViewDelegate {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "TraversalHierarchy")

    private let gridContainerView = TraversalGridContainerView()
    private let orderingControl = UISegmentedControl(items: ["Row-Major", "Column-Major"])
    private let disclosureHeaderButton = UIButton(type: .system)
    private let disclosureBodyLabel = UILabel()
    private let linksTextView = UITextView()
    private let statusLabel = UILabel()

    private var isDisclosureExpanded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Traversal Hierarchy"
        view.backgroundColor = .systemBackground

        configureViews()
        registerNotifications()
        updateOrderingStatus()
    }

    private func configureViews() {
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

        view.addSubview(orderingControl)
        view.addSubview(gridContainerView)
        view.addSubview(disclosureHeaderButton)
        view.addSubview(disclosureBodyLabel)
        view.addSubview(linksTextView)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            orderingControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            orderingControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            orderingControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            gridContainerView.topAnchor.constraint(equalTo: orderingControl.bottomAnchor, constant: 20),
            gridContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            gridContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            disclosureHeaderButton.topAnchor.constraint(equalTo: gridContainerView.bottomAnchor, constant: 16),
            disclosureHeaderButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            disclosureHeaderButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            disclosureBodyLabel.topAnchor.constraint(equalTo: disclosureHeaderButton.bottomAnchor, constant: 6),
            disclosureBodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            disclosureBodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            linksTextView.topAnchor.constraint(equalTo: disclosureBodyLabel.bottomAnchor, constant: 12),
            linksTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            linksTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: linksTextView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
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
