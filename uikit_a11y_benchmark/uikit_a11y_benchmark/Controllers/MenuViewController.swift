import UIKit

final class MenuViewController: UIViewController {

    struct Destination {
        let title: String
        let subtitle: String
        let accessibilityIdentifier: String
        let makeViewController: @MainActor () -> UIViewController
    }

    private static let cellReuseIdentifier = "MenuDestinationCell"

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let destinations: [Destination] = [
        Destination(
            title: "Scroll Baseline",
            subtitle: "100-cell table with Δy/viewportHeight ratio & secondary scrollView",
            accessibilityIdentifier: "menu.scrollBaseline",
            makeViewController: { ScrollBaselineViewController() }
        ),
        Destination(
            title: "Traversal Hierarchy",
            subtitle: "3x3 grid with RTL toggle, headers, zero-rect & stateful buttons",
            accessibilityIdentifier: "menu.traversalHierarchy",
            makeViewController: { TraversalHierarchyViewController() }
        ),
        Destination(
            title: "Focus & Keyboard",
            subtitle: "Prefilled & secure text fields, 25% slider, VO & FKA focus logs",
            accessibilityIdentifier: "menu.focusKeyboard",
            makeViewController: { FocusKeyboardViewController() }
        ),
        Destination(
            title: "Modal Barrier",
            subtitle: "Background buttons & UISheetPresentationController modal barrier",
            accessibilityIdentifier: "menu.modalBarrier",
            makeViewController: { ModalBarrierViewController() }
        ),
        Destination(
            title: "Custom Actions",
            subtitle: "Merged-label cells with Primary & Secondary rotor actions",
            accessibilityIdentifier: "menu.customActions",
            makeViewController: { CustomActionsViewController() }
        ),
        Destination(
            title: "Composite Arena",
            subtitle: "Floating launcher & concurrent resignFirstResponder + modal present",
            accessibilityIdentifier: "menu.compositeArena",
            makeViewController: { CompositeArenaViewController() }
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit A11y Benchmark"
        view.backgroundColor = .systemGroupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "menu.tableView"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension MenuViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return destinations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellReuseIdentifier,
            for: indexPath
        )
        let destination = destinations[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = destination.title
        content.secondaryText = destination.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = destination.accessibilityIdentifier
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MenuViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let destination = destinations[indexPath.row]
        let viewController = destination.makeViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
