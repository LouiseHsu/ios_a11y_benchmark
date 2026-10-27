import UIKit
import os

final class CompositeArenaViewController: UIViewController {

    private static let inputCellIdentifier = "CompositeTextInputCell"
    private static let rowCount = 24
    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "CompositeArena")

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let floatingTopBar = UIView()
    private let floatingModalLauncherButton = UIButton(type: .system)
    private let resignAndPresentButton = UIButton(type: .system)

    private var textValues: [Int: String] = [:]
    private weak var activeTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Composite Arena"
        view.backgroundColor = .systemBackground

        // 1. Add tableView first in subview hierarchy
        configureTableView()
        // 2. Add floating launcher bar after tableView in view hierarchy,
        // but position it visually at the top of the screen above the list
        // to benchmark visual vs. view-hierarchy focus ordering.
        configureFloatingTopControls()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "composite.tableView"
        tableView.keyboardDismissMode = .interactive
        tableView.dataSource = self
        tableView.rowHeight = 60
        // Inset top of table content so rows start below the floating overlay bar
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 24, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        tableView.register(
            CompositeTextInputCell.self,
            forCellReuseIdentifier: Self.inputCellIdentifier
        )
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureFloatingTopControls() {
        floatingTopBar.translatesAutoresizingMaskIntoConstraints = false
        floatingTopBar.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        floatingTopBar.layer.cornerRadius = 12
        floatingTopBar.layer.shadowColor = UIColor.black.cgColor
        floatingTopBar.layer.shadowOpacity = 0.12
        floatingTopBar.layer.shadowRadius = 6
        floatingTopBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        floatingTopBar.accessibilityIdentifier = "composite.floatingTopBar"

        var launcherConfig = UIButton.Configuration.filled()
        launcherConfig.title = "Floating Modal Launcher (Top Visual)"
        floatingModalLauncherButton.configuration = launcherConfig
        floatingModalLauncherButton.accessibilityIdentifier = "composite.launchModalButton"
        floatingModalLauncherButton.addTarget(
            self,
            action: #selector(launchFloatingModalTapped),
            for: .touchUpInside
        )

        var resignPresentConfig = UIButton.Configuration.tinted()
        resignPresentConfig.title = "Resign FirstResponder & Present Alert"
        resignAndPresentButton.configuration = resignPresentConfig
        resignAndPresentButton.accessibilityIdentifier = "composite.resignAndPresentButton"
        resignAndPresentButton.addTarget(
            self,
            action: #selector(concurrentResignFirstResponderAndPresentModal),
            for: .touchUpInside
        )

        let buttonStack = UIStackView(arrangedSubviews: [
            floatingModalLauncherButton,
            resignAndPresentButton,
        ])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 8

        floatingTopBar.addSubview(buttonStack)
        view.addSubview(floatingTopBar)

        NSLayoutConstraint.activate([
            floatingTopBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            floatingTopBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floatingTopBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: floatingTopBar.topAnchor, constant: 10),
            buttonStack.leadingAnchor.constraint(equalTo: floatingTopBar.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: floatingTopBar.trailingAnchor, constant: -12),
            buttonStack.bottomAnchor.constraint(equalTo: floatingTopBar.bottomAnchor, constant: -10),
        ])
    }

    @objc private func launchFloatingModalTapped() {
        Self.logger.info("[CompositeArena] Launching modal sheet from floating top button")
        let modalVC = BarrierModalSheetViewController()
        modalVC.modalPresentationStyle = .pageSheet
        if let sheet = modalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(modalVC, animated: true)
    }

    @objc private func concurrentResignFirstResponderAndPresentModal() {
        let didResign: Bool
        if let activeTextField {
            didResign = activeTextField.resignFirstResponder()
        } else {
            didResign = view.endEditing(true)
        }

        Self.logger.info(
            "[CompositeArena] Concurrent resignFirstResponder (didResign=\(didResign)) + present alert"
        )
        print("[CompositeArena] Concurrent resignFirstResponder (didResign=\(didResign)) + present alert")

        let alert = UIAlertController(
            title: "Concurrent Keyboard Dismiss & Modal",
            message: "Presented simultaneously with resignFirstResponder() (didResign=\(didResign)).",
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = "composite.concurrentAlert"
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CompositeArenaViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Self.inputCellIdentifier,
                for: indexPath
            ) as? CompositeTextInputCell
        else {
            return UITableViewCell()
        }

        let row = indexPath.row
        cell.configure(
            row: row,
            text: textValues[row] ?? "",
            onDidBeginEditing: { [weak self] textField in
                self?.activeTextField = textField
            },
            onTextChanged: { [weak self] updatedText in
                self?.textValues[row] = updatedText
            }
        )
        return cell
    }
}

// MARK: - CompositeTextInputCell

final class CompositeTextInputCell: UITableViewCell, UITextFieldDelegate {

    private let titleLabel = UILabel()
    private let textField = UITextField()
    private var onDidBeginEditing: ((UITextField) -> Void)?
    private var onTextChanged: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        row: Int,
        text: String,
        onDidBeginEditing: @escaping (UITextField) -> Void,
        onTextChanged: @escaping (String) -> Void
    ) {
        self.onDidBeginEditing = onDidBeginEditing
        self.onTextChanged = onTextChanged
        titleLabel.text = "Field #\(row)"
        textField.text = text
        textField.placeholder = "Enter text for row \(row)"
        textField.accessibilityLabel = "Composite Input \(row)"
        textField.accessibilityIdentifier = "composite.textField.\(row)"
        accessibilityIdentifier = "composite.cell.\(row)"
    }

    @objc private func editingChanged() {
        onTextChanged?(textField.text ?? "")
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onDidBeginEditing?(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
