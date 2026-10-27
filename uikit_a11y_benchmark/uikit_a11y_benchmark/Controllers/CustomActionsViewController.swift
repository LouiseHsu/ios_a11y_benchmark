import UIKit
import os

final class CustomActionsViewController: UIViewController {

    struct ActionItem {
        let title: String
        let subtitle: String
        var primaryCount: Int
        var secondaryCount: Int
    }

    private static let cellReuseIdentifier = "MergedCustomActionCell"
    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "CustomActions")

    private let statusHeaderLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var items: [ActionItem] = (0..<20).map { index in
        ActionItem(
            title: "Merged Item #\(index)",
            subtitle: "VoiceOver rotor actions benchmark row \(index + 1)",
            primaryCount: 0,
            secondaryCount: 0
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom Actions"
        view.backgroundColor = .systemGroupedBackground

        configureStatusHeader()
        configureTableView()
    }

    private func configureStatusHeader() {
        statusHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        statusHeaderLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusHeaderLabel.textColor = .label
        statusHeaderLabel.textAlignment = .center
        statusHeaderLabel.numberOfLines = 0
        statusHeaderLabel.text = "Last Rotor Action: None"
        statusHeaderLabel.accessibilityIdentifier = "customActions.statusLabel"
        view.addSubview(statusHeaderLabel)

        NSLayoutConstraint.activate([
            statusHeaderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            statusHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "customActions.tableView"
        tableView.dataSource = self
        tableView.register(MergedCustomActionCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: statusHeaderLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func handlePrimaryAction(forRow row: Int) -> Bool {
        guard items.indices.contains(row) else { return false }
        items[row].primaryCount += 1
        let message = "Primary Action fired on \(items[row].title) (count=\(items[row].primaryCount))"
        statusHeaderLabel.text = "Last Rotor Action: \(message)"
        Self.logger.info("[CustomActions] \(message, privacy: .public)")
        print("[CustomActions] \(message)")
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        return true
    }

    private func handleSecondaryAction(forRow row: Int) -> Bool {
        guard items.indices.contains(row) else { return false }
        items[row].secondaryCount += 1
        let message = "Secondary Action fired on \(items[row].title) (count=\(items[row].secondaryCount))"
        statusHeaderLabel.text = "Last Rotor Action: \(message)"
        Self.logger.info("[CustomActions] \(message, privacy: .public)")
        print("[CustomActions] \(message)")
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        return true
    }
}

// MARK: - UITableViewDataSource

extension CustomActionsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Self.cellReuseIdentifier,
                for: indexPath
            ) as? MergedCustomActionCell
        else {
            return UITableViewCell()
        }

        let row = indexPath.row
        let item = items[row]

        let primaryAction = UIAccessibilityCustomAction(name: "Primary Action") { [weak self] _ in
            return self?.handlePrimaryAction(forRow: row) ?? false
        }
        let secondaryAction = UIAccessibilityCustomAction(name: "Secondary Action") { [weak self] _ in
            return self?.handleSecondaryAction(forRow: row) ?? false
        }

        cell.configure(
            row: row,
            item: item,
            customActions: [primaryAction, secondaryAction]
        )
        return cell
    }
}

// MARK: - MergedCustomActionCell

final class MergedCustomActionCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let countBadgeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        // Merge child labels into a single accessible element on the cell
        isAccessibilityElement = true
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
        countBadgeLabel.isAccessibilityElement = false

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        countBadgeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        countBadgeLabel.textColor = .systemBlue

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, countBadgeLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 4
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        row: Int,
        item: CustomActionsViewController.ActionItem,
        customActions: [UIAccessibilityCustomAction]
    ) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        let badgeText = "Primary: \(item.primaryCount) • Secondary: \(item.secondaryCount)"
        countBadgeLabel.text = badgeText

        accessibilityIdentifier = "customActions.cell.\(row)"
        accessibilityLabel = "\(item.title), \(item.subtitle)"
        accessibilityValue = badgeText
        accessibilityCustomActions = customActions
    }
}
