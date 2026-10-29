import UIKit
import os

final class ModalBarrierViewController: UIViewController, UITabBarDelegate {

    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "ModalBarrier")

    private static let popupOptions = ["Option Alpha", "Option Beta", "Option Gamma"]
    private static let tabTitles = ["Overview", "Details", "Settings"]
    private static let tabSymbols = ["list.bullet", "doc.text", "gearshape"]

    private let statusLabel = UILabel()
    private let backgroundButton1 = UIButton(type: .system)
    private let backgroundButton2 = UIButton(type: .system)
    private let popupMenuButton = UIButton(type: .system)
    private let presentAlertButton = UIButton(type: .system)
    private let presentDatePickerButton = UIButton(type: .system)
    private let presentTimePickerButton = UIButton(type: .system)
    private let presentModalButton = UIButton(type: .system)
    private let bottomTabBar = UITabBar()

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

        var alertConfig = UIButton.Configuration.tinted()
        alertConfig.title = "Present Alert Dialog"
        presentAlertButton.configuration = alertConfig
        presentAlertButton.accessibilityIdentifier = "modal.presentAlertButton"
        presentAlertButton.addTarget(
            self,
            action: #selector(presentAlertDialog),
            for: .touchUpInside
        )

        var presentConfig = UIButton.Configuration.filled()
        presentConfig.title = "Present Modal Sheet"
        presentModalButton.configuration = presentConfig
        presentModalButton.accessibilityIdentifier = "modal.presentButton"
        presentModalButton.addTarget(
            self,
            action: #selector(presentModalSheet),
            for: .touchUpInside
        )

        var datePickerConfig = UIButton.Configuration.tinted()
        datePickerConfig.title = "Present Date Picker"
        presentDatePickerButton.configuration = datePickerConfig
        presentDatePickerButton.accessibilityIdentifier = "modal.presentDatePickerButton"
        presentDatePickerButton.addTarget(
            self,
            action: #selector(presentDatePicker),
            for: .touchUpInside
        )

        var timePickerConfig = UIButton.Configuration.tinted()
        timePickerConfig.title = "Present Time Picker"
        presentTimePickerButton.configuration = timePickerConfig
        presentTimePickerButton.accessibilityIdentifier = "modal.presentTimePickerButton"
        presentTimePickerButton.addTarget(
            self,
            action: #selector(presentTimePicker),
            for: .touchUpInside
        )

        let tabItems: [UITabBarItem] = Self.tabTitles.enumerated().map { index, title in
            let item = UITabBarItem(
                title: title,
                image: UIImage(systemName: Self.tabSymbols[index]),
                tag: index
            )
            item.accessibilityIdentifier = "modal.tab.\(index)"
            return item
        }
        bottomTabBar.translatesAutoresizingMaskIntoConstraints = false
        bottomTabBar.items = tabItems
        bottomTabBar.selectedItem = tabItems.first
        bottomTabBar.delegate = self
        bottomTabBar.accessibilityIdentifier = "modal.tabBar"

        let stackView = UIStackView(arrangedSubviews: [
            statusLabel,
            backgroundButton1,
            backgroundButton2,
            popupMenuButton,
            presentAlertButton,
            presentDatePickerButton,
            presentTimePickerButton,
            presentModalButton,
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        view.addSubview(stackView)
        view.addSubview(bottomTabBar)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            bottomTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
        // Disabled item (issue #171231: disabled menu item not announced as
        // "dimmed"). Flutter twin: CupertinoMenuItem(onPressed: null).
        let disabledAction = UIAction(
            title: "Option Delta (Unavailable)",
            attributes: .disabled
        ) { _ in }
        disabledAction.accessibilityIdentifier = "modal.popupOption.disabled"
        popupMenuButton.menu = UIMenu(title: "Anchored Options", children: actions + [disabledAction])
    }

    // MARK: - Date / time pickers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// 2026-01-15 09:30 in the current calendar, shared by both pickers.
    private static var initialPickerDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 9
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    private func presentPickerSheet(_ pickerViewController: BenchmarkPickerSheetViewController) {
        let navigationController = UINavigationController(rootViewController: pickerViewController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navigationController, animated: true)
    }

    /// Native idiom for Flutter's Material `showDatePicker`: a sheet with an
    /// inline calendar UIDatePicker (as in Calendar.app / Reminders).
    @objc private func presentDatePicker() {
        let picker = BenchmarkPickerSheetViewController(
            title: "Select Date",
            mode: .date,
            style: .inline,
            initialDate: Self.initialPickerDate,
            pickerIdentifier: "modal.datePicker"
        )
        picker.onDone = { [weak self] date in
            let message = "Date Picker: \(Self.dateFormatter.string(from: date))"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        picker.onCancel = { [weak self] in
            let message = "Date Picker: Cancelled"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        Self.logger.info("[ModalBarrier] Presenting UIDatePicker (.date, .inline) in .pageSheet")
        presentPickerSheet(picker)
    }

    /// Native idiom for Flutter's Material `showTimePicker`: a sheet with a
    /// wheels-style UIDatePicker in en_US so the AM/PM column is present
    /// (as in Clock.app alarms).
    @objc private func presentTimePicker() {
        let picker = BenchmarkPickerSheetViewController(
            title: "Select Time",
            mode: .time,
            style: .wheels,
            initialDate: Self.initialPickerDate,
            pickerIdentifier: "modal.timePicker"
        )
        picker.onDone = { [weak self] date in
            let message = "Time Picker: \(Self.timeFormatter.string(from: date))"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        picker.onCancel = { [weak self] in
            let message = "Time Picker: Cancelled"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        Self.logger.info("[ModalBarrier] Presenting UIDatePicker (.time, .wheels, en_US) in .pageSheet")
        presentPickerSheet(picker)
    }

    @objc private func presentAlertDialog() {
        let alert = UIAlertController(
            title: "Benchmark Alert Dialog",
            message: "Tests alert dialog announcement, Voice Control dismissal, and focus restoration on close.",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            let message = "Alert Dialog: Cancel"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        cancelAction.accessibilityIdentifier = "modal.alertCancelButton"

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            let message = "Alert Dialog: Confirm"
            self?.statusLabel.text = message
            Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
        }
        confirmAction.accessibilityIdentifier = "modal.alertConfirmButton"

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        Self.logger.info("[ModalBarrier] Presenting UIAlertController (.alert)")
        present(alert, animated: true)
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let title = item.title ?? "Tab"
        let index = item.tag + 1
        let message = "Selected Tab: \(title) (\(index) of \(Self.tabTitles.count))"
        statusLabel.text = message
        Self.logger.info("[ModalBarrier] \(message, privacy: .public)")
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

// MARK: - BenchmarkPickerSheetViewController

/// A UIDatePicker hosted in a navigation controller sheet with Cancel / Done
/// bar buttons — the stock iOS presentation for a one-off date or time choice.
/// Twin of Flutter's Material `showDatePicker` / `showTimePicker` dialogs.
final class BenchmarkPickerSheetViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    var onDone: ((Date) -> Void)?
    var onCancel: (() -> Void)?

    private let datePicker = UIDatePicker()
    private let pickerMode: UIDatePicker.Mode
    private let pickerStyle: UIDatePickerStyle
    private let initialDate: Date
    private let pickerIdentifier: String
    private var didFinish = false

    init(
        title: String,
        mode: UIDatePicker.Mode,
        style: UIDatePickerStyle,
        initialDate: Date,
        pickerIdentifier: String
    ) {
        pickerMode = mode
        pickerStyle = style
        self.initialDate = initialDate
        self.pickerIdentifier = pickerIdentifier
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = pickerMode
        datePicker.preferredDatePickerStyle = pickerStyle
        // en_US guarantees a 12-hour clock with an AM/PM column regardless of
        // the device's locale (issue #173302: AM/PM state not announced).
        datePicker.locale = Locale(identifier: "en_US")
        datePicker.date = initialDate
        datePicker.accessibilityIdentifier = pickerIdentifier
        view.addSubview(datePicker)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in
                self?.cancelTapped()
            }
        )
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "modal.pickerCancelButton"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in
                self?.doneTapped()
            }
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "modal.pickerDoneButton"

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePicker.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The navigation controller is what gets presented, so its
        // presentation controller is the one that reports swipe-to-dismiss.
        navigationController?.presentationController?.delegate = self
    }

    private func cancelTapped() {
        didFinish = true
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    private func doneTapped() {
        didFinish = true
        let date = datePicker.date
        dismiss(animated: true) { [weak self] in
            self?.onDone?(date)
        }
    }

    // Swipe-down / Escape (FKA) dismissal counts as Cancel.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !didFinish else { return }
        didFinish = true
        onCancel?()
    }
}
