import UIKit
import os

final class ModalBarrierViewController: UIViewController {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "ModalBarrier")

    private static let popupOptions = ["Option Alpha", "Option Beta", "Option Gamma"]

    private let statusLabel = UILabel()
    private let backgroundButton1 = UIButton(type: .system)
    private let backgroundButton2 = UIButton(type: .system)
    private let popupMenuButton = UIButton(type: .system)
    private let presentModalButton = UIButton(type: .system)

    private var backgroundTapCount = 0
    private var selectedPopupOption = ModalBarrierViewController.popupOptions[0]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Modal Barrier"
        view.backgroundColor = .systemBackground

        configureBackgroundContent()
    }

    private func configureBackgroundContent() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Background Action Count: 0"
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "modal.statusLabel"

        var button1Config = UIButton.Configuration.bordered()
        button1Config.title = "Background Button 1"
        backgroundButton1.configuration = button1Config
        backgroundButton1.accessibilityIdentifier = "modal.backgroundButton1"
        backgroundButton1.addTarget(
            self,
            action: #selector(backgroundButton1Tapped),
            for: .touchUpInside
        )

        var button2Config = UIButton.Configuration.bordered()
        button2Config.title = "Background Button 2"
        backgroundButton2.configuration = button2Config
        backgroundButton2.accessibilityIdentifier = "modal.backgroundButton2"
        backgroundButton2.addTarget(
            self,
            action: #selector(backgroundButton2Tapped),
            for: .touchUpInside
        )

        popupMenuButton.accessibilityIdentifier = "modal.popupMenuButton"
        popupMenuButton.showsMenuAsPrimaryAction = true
        rebuildPopupMenu()

        var presentConfig = UIButton.Configuration.filled()
        presentConfig.title = "Present Modal Sheet"
        presentModalButton.configuration = presentConfig
        presentModalButton.accessibilityIdentifier = "modal.presentButton"
        presentModalButton.addTarget(
            self,
            action: #selector(presentModalSheet),
            for: .touchUpInside
        )

        let stackView = UIStackView(arrangedSubviews: [
            statusLabel,
            backgroundButton1,
            backgroundButton2,
            popupMenuButton,
            presentModalButton,
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func backgroundButton1Tapped() {
        backgroundTapCount += 1
        let message = "Background Button 1 Tapped (Count: \(backgroundTapCount))"
        statusLabel.text = message
        Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
    }

    @objc private func backgroundButton2Tapped() {
        backgroundTapCount += 1
        let message = "Background Button 2 Tapped (Count: \(backgroundTapCount))"
        statusLabel.text = message
        Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
    }

    private func rebuildPopupMenu() {
        var menuConfig = UIButton.Configuration.tinted()
        menuConfig.title = "Anchored Popup Menu: \(selectedPopupOption)"
        popupMenuButton.configuration = menuConfig
        popupMenuButton.accessibilityValue = selectedPopupOption

        let actions: [UIAction] = Self.popupOptions.enumerated().map { index, option in
            let action = UIAction(
                title: option,
                state: option == selectedPopupOption ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                self.selectedPopupOption = option
                let message = "Popup Selected: \(option)"
                self.statusLabel.text = message
                self.rebuildPopupMenu()
                Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
            }
            action.accessibilityIdentifier = "modal.popupOption.\(index)"
            return action
        }
        popupMenuButton.menu = UIMenu(title: "Anchored Options", children: actions)
    }

    @objc private func presentModalSheet() {
        let sheetViewController = BarrierModalSheetViewController()
        sheetViewController.modalPresentationStyle = .pageSheet
        if let sheet = sheetViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        sheetViewController.onDismiss = { [weak self] in
            self?.statusLabel.text = "Modal Sheet Dismissed"
            Self.logger.info("[ModalBarrier] Modal sheet dismissed")
        }
        Self.logger.info("[ModalBarrier] Presenting UISheetPresentationController (.medium, .large, grabberVisible=true)")
        present(sheetViewController, animated: true)
    }
}

// MARK: - BarrierModalSheetViewController

final class BarrierModalSheetViewController: UIViewController {

    var onDismiss: (() -> Void)?

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let modalActionButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        view.accessibilityViewIsModal = true
        view.accessibilityIdentifier = "modal.sheetContainer"

        titleLabel.text = "Modal Barrier Active"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityIdentifier = "modal.sheetTitle"

        descriptionLabel.text =
            "Configured with accessibilityViewIsModal = true and UISheetPresentationController (detents: [.medium(), .large()], prefersGrabberVisible: true)."
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.accessibilityIdentifier = "modal.sheetDescription"

        var actionConfig = UIButton.Configuration.tinted()
        actionConfig.title = "Modal Sheet Action"
        modalActionButton.configuration = actionConfig
        modalActionButton.accessibilityIdentifier = "modal.sheetActionButton"
        modalActionButton.addTarget(
            self,
            action: #selector(modalActionTapped),
            for: .touchUpInside
        )

        var dismissConfig = UIButton.Configuration.filled()
        dismissConfig.title = "Dismiss Modal Sheet"
        dismissButton.configuration = dismissConfig
        dismissButton.accessibilityIdentifier = "modal.dismissButton"
        dismissButton.addTarget(
            self,
            action: #selector(dismissModalTapped),
            for: .touchUpInside
        )

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            descriptionLabel,
            modalActionButton,
            dismissButton,
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.accessibilityViewIsModal = true
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    @objc private func modalActionTapped() {
        titleLabel.text = "Modal Action Triggered"
    }

    @objc private func dismissModalTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}
