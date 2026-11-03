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

    // Custom-actions fixture row (VoiceOver Actions rotor).
    private let messageRowView = UIView()
    private let messageTitleLabel = UILabel()
    private let messagePreviewLabel = UILabel()

    // "Traits & Attributes" section (image / hidden / hint / attributed label /
    // focus highlight fixtures).
    private let traitsSectionStack = UIStackView()
    private let traitsHeaderLabel = UILabel()
    private let meaningfulImageView = UIImageView()
    private let decorativeImageView = UIImageView()
    private let imageCaptionLabel = UILabel()
    private let toggleHiddenRowButton = UIButton(configuration: .bordered())
    private let hiddenRowLabel = UILabel()
    private let offstageLabel = UILabel()
    private let sendButton = UIButton(configuration: .tinted())
    private let orderIdLabel = UILabel()
    private let frenchLabel = UILabel()
    private let focusHighlightRowView = FocusHighlightRowView()

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

        gridContainerView.translatesAutoresizingMaskIntoConstraints = false
        gridContainerView.onStatusEvent = { [weak self] eventMessage in
            self?.recordEvent(eventMessage)
        }

        disclosureHeaderButton.translatesAutoresizingMaskIntoConstraints = false
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

        linksTextView.translatesAutoresizingMaskIntoConstraints = false
        linksTextView.isEditable = false
        linksTextView.isScrollEnabled = false
        linksTextView.backgroundColor = .clear
        linksTextView.textContainerInset = .zero
        linksTextView.textContainer.lineFragmentPadding = 0
        linksTextView.delegate = self
        linksTextView.attributedText = makeLinksAttributedString()

        configureMessageRow()
        configureTraitsAndAttributes()

        contentView.addSubview(orderingControl)
        contentView.addSubview(gridContainerView)
        contentView.addSubview(disclosureHeaderButton)
        contentView.addSubview(disclosureBodyLabel)
        contentView.addSubview(linksTextView)
        contentView.addSubview(messageRowView)
        contentView.addSubview(traitsSectionStack)
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

            messageRowView.topAnchor.constraint(equalTo: linksTextView.bottomAnchor, constant: 12),
            messageRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            traitsSectionStack.topAnchor.constraint(equalTo: messageRowView.bottomAnchor, constant: 24),
            traitsSectionStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            traitsSectionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: traitsSectionStack.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Custom Actions fixture

    /// Twin of the Flutter `customSemanticsActions` row. A message row that is
    /// one accessibility element (title + preview) and exposes "Archive" /
    /// "Delete" in the VoiceOver Actions rotor. Intent: nothing in a stock
    /// UIView implies these actions; the developer must declare them.
    private func configureMessageRow() {
        messageRowView.translatesAutoresizingMaskIntoConstraints = false

        messageTitleLabel.text = "Message from Alex"
        messageTitleLabel.font = .preferredFont(forTextStyle: .body)
        messageTitleLabel.adjustsFontForContentSizeCategory = true
        messageTitleLabel.numberOfLines = 0

        messagePreviewLabel.text = "Lunch tomorrow?"
        messagePreviewLabel.font = .preferredFont(forTextStyle: .footnote)
        messagePreviewLabel.adjustsFontForContentSizeCategory = true
        messagePreviewLabel.textColor = .secondaryLabel
        messagePreviewLabel.numberOfLines = 0

        let messageStack = UIStackView(arrangedSubviews: [messageTitleLabel, messagePreviewLabel])
        messageStack.translatesAutoresizingMaskIntoConstraints = false
        messageStack.axis = .vertical
        messageStack.spacing = 2
        messageRowView.addSubview(messageStack)

        NSLayoutConstraint.activate([
            messageStack.topAnchor.constraint(equalTo: messageRowView.topAnchor, constant: 8),
            messageStack.leadingAnchor.constraint(equalTo: messageRowView.leadingAnchor, constant: 4),
            messageStack.trailingAnchor.constraint(equalTo: messageRowView.trailingAnchor, constant: -4),
            messageStack.bottomAnchor.constraint(equalTo: messageRowView.bottomAnchor, constant: -8),
        ])

        // Group the two labels as a single element so the custom actions are
        // offered on the row, not on each line of text.
        messageRowView.isAccessibilityElement = true
        messageRowView.accessibilityLabel = "Message from Alex, Lunch tomorrow?"
        messageRowView.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Archive") { [weak self] _ in
                self?.recordEvent("Custom action -> Archive")
                return true
            },
            UIAccessibilityCustomAction(name: "Delete") { [weak self] _ in
                self?.recordEvent("Custom action -> Delete")
                return true
            },
        ]
    }

    // MARK: - Traits & Attributes fixtures

    /// Twins of the Flutter image / hidden / hint / attributed-label / focus
    /// fixtures. Each item uses only the one stock accessibility API that is
    /// itself the thing under test.
    private func configureTraitsAndAttributes() {
        traitsSectionStack.translatesAutoresizingMaskIntoConstraints = false
        traitsSectionStack.axis = .vertical
        traitsSectionStack.spacing = 8

        traitsHeaderLabel.text = "Traits & Attributes"
        traitsHeaderLabel.font = .preferredFont(forTextStyle: .headline)
        traitsHeaderLabel.adjustsFontForContentSizeCategory = true
        traitsHeaderLabel.accessibilityTraits = .header

        // 1. Image: meaningful (labelled) vs decorative (left inert).
        //    UIImageView supplies the .image trait by itself.
        meaningfulImageView.image = UIImage(systemName: "photo")
        meaningfulImageView.contentMode = .scaleAspectFit
        meaningfulImageView.isAccessibilityElement = true
        meaningfulImageView.accessibilityLabel = "Sunset over the bay"

        decorativeImageView.image = UIImage(systemName: "sparkles")
        decorativeImageView.contentMode = .scaleAspectFit

        let imageSpacer = UIView()
        imageSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let imageRow = UIStackView(arrangedSubviews: [meaningfulImageView, decorativeImageView, imageSpacer])
        imageRow.axis = .horizontal
        imageRow.alignment = .center
        imageRow.spacing = 12

        imageCaptionLabel.text = "Meaningful image / Decorative image"
        imageCaptionLabel.font = .preferredFont(forTextStyle: .footnote)
        imageCaptionLabel.adjustsFontForContentSizeCategory = true
        imageCaptionLabel.textColor = .secondaryLabel
        imageCaptionLabel.numberOfLines = 0

        // 2. Hidden: a row toggled at runtime plus one permanently offstage.
        toggleHiddenRowButton.configuration?.title = "Toggle hidden row"
        toggleHiddenRowButton.addTarget(
            self,
            action: #selector(toggleHiddenRow),
            for: .touchUpInside
        )

        hiddenRowLabel.text = "Hidden row (visible only after toggle)"
        hiddenRowLabel.font = .preferredFont(forTextStyle: .body)
        hiddenRowLabel.adjustsFontForContentSizeCategory = true
        hiddenRowLabel.numberOfLines = 0
        hiddenRowLabel.isHidden = true

        offstageLabel.text = "Offstage text"
        offstageLabel.font = .preferredFont(forTextStyle: .body)
        offstageLabel.adjustsFontForContentSizeCategory = true
        offstageLabel.numberOfLines = 0
        offstageLabel.isHidden = true

        // 3. Hint.
        sendButton.configuration?.title = "Send"
        sendButton.accessibilityHint = "Sends the message"
        sendButton.addTarget(
            self,
            action: #selector(sendTapped),
            for: .touchUpInside
        )

        // 4. Attributed label: spell-out range and per-label speech language.
        orderIdLabel.text = "Order ID: ABC123"
        orderIdLabel.font = .preferredFont(forTextStyle: .body)
        orderIdLabel.adjustsFontForContentSizeCategory = true
        orderIdLabel.numberOfLines = 0
        let orderText = NSMutableAttributedString(string: "Order ID: ABC123")
        let codeRange = (orderText.string as NSString).range(of: "ABC123")
        orderText.addAttribute(.accessibilitySpeechSpellOut, value: true, range: codeRange)
        orderIdLabel.accessibilityAttributedLabel = orderText

        frenchLabel.text = "Bonjour tout le monde"
        frenchLabel.font = .preferredFont(forTextStyle: .body)
        frenchLabel.adjustsFontForContentSizeCategory = true
        frenchLabel.numberOfLines = 0
        frenchLabel.accessibilityAttributedLabel = NSAttributedString(
            string: "Bonjour tout le monde",
            attributes: [.accessibilitySpeechLanguage: "fr-FR"]
        )

        // 5. Focus highlight.
        focusHighlightRowView.onFocus = { [weak self] eventMessage in
            self?.recordEvent(eventMessage)
        }

        for item in [
            traitsHeaderLabel,
            imageRow,
            imageCaptionLabel,
            toggleHiddenRowButton,
            hiddenRowLabel,
            offstageLabel,
            sendButton,
            orderIdLabel,
            frenchLabel,
            focusHighlightRowView,
        ] {
            traitsSectionStack.addArrangedSubview(item)
        }

        NSLayoutConstraint.activate([
            meaningfulImageView.widthAnchor.constraint(equalToConstant: 44),
            meaningfulImageView.heightAnchor.constraint(equalToConstant: 44),
            decorativeImageView.widthAnchor.constraint(equalToConstant: 44),
            decorativeImageView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func toggleHiddenRow() {
        hiddenRowLabel.isHidden.toggle()
        recordEvent("Hidden row -> \(hiddenRowLabel.isHidden ? "hidden" : "shown")")
    }

    @objc private func sendTapped() {
        recordEvent("Send tapped")
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

        let shippingStack = UIStackView()
        shippingStack.translatesAutoresizingMaskIntoConstraints = false
        shippingStack.axis = .vertical
        shippingStack.spacing = 2
        for (index, speed) in Self.shippingSpeeds.enumerated() {
            let button = UIButton(configuration: .plain())
            button.tag = index
            button.contentHorizontalAlignment = .leading
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
    }

    private func updateDisclosureAppearance() {
        var config = UIButton.Configuration.bordered()
        config.title = "Expandable Disclosure Section"
        config.image = UIImage(systemName: isDisclosureExpanded ? "chevron.up" : "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        disclosureHeaderButton.configuration = config
        // UIKit has no disclosure control; mirrors SwiftUI DisclosureGroup, which exposes Expanded/Collapsed via accessibilityValue.
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

    @objc private func orderingChanged(_ sender: UISegmentedControl) {
        let mode: TraversalGridContainerView.TraversalMode =
            sender.selectedSegmentIndex == 0 ? .rowMajor : .columnMajor
        gridContainerView.traversalMode = mode
        updateOrderingStatus()
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

// MARK: - FocusHighlightRowView

/// Twin of the Flutter `onFocus`-style fixture: a single element that reacts
/// visually (and logs) when VoiceOver focus lands on / leaves it.
final class FocusHighlightRowView: UIView {

    var onFocus: ((String) -> Void)?

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Focus-highlight row"
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Focus-highlight row"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        backgroundColor = .systemYellow
        onFocus?("VO focus -> gained (highlight row)")
    }

    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        backgroundColor = nil
        onFocus?("VO focus -> lost (highlight row)")
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
            button.addTarget(self, action: #selector(buttonBTapped(_:)), for: .touchUpInside)
            buttonB = button
        } else if row == 0 && col == 2 {
            // Button C ("Toggle Button B")
            var cConfig = config
            cConfig.title = "Toggle Button B"
            button.configuration = cConfig
            button.addTarget(self, action: #selector(buttonCTapped(_:)), for: .touchUpInside)
            buttonC = button
        } else {
            var cellConfig = config
            cellConfig.title = "R\(row + 1)C\(col + 1)"
            button.configuration = cellConfig
            button.addTarget(self, action: #selector(standardGridButtonTapped(_:)), for: .touchUpInside)
        }

        return button
    }

    @objc private func buttonATapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.setNeedsUpdateConfiguration()

        let stateDescription = sender.isSelected ? "Selected (with checkmark)" : "Unselected (no icon)"
        onStatusEvent?("Button A: \(stateDescription)")
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
