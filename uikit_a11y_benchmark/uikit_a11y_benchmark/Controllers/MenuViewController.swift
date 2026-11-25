import UIKit

final class MenuViewController: UIViewController {

    struct Destination {
        let title: String
        let subtitle: String
        let makeViewController: @MainActor () -> UIViewController
    }

    private static let cellReuseIdentifier = "MenuDestinationCell"

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let destinations: [Destination] = [
        Destination(
            title: "Scroll Baseline",
            subtitle: "100-cell table with deltaY/viewportHeight ratio & page scroll status",
            makeViewController: { ScrollBaselineViewController() }
        ),
        Destination(
            title: "Traversal Hierarchy",
            subtitle: "3x3 grid with headers, container ordering, stateful buttons, controls & mutation fixtures",
            makeViewController: { TraversalHierarchyViewController() }
        ),
        Destination(
            title: "Focus & Keyboard",
            subtitle: "Prefilled, secure, multiline & read-only fields, 25% slider, VO & FKA focus logs",
            makeViewController: { FocusKeyboardViewController() }
        ),
        Destination(
            title: "Modal Barrier",
            subtitle: "Background buttons & UISheetPresentationController modal barrier",
            makeViewController: { ModalBarrierViewController() }
        ),
        Destination(
            title: "Sliver Scroll",
            subtitle: "Collapsing large title, 60-row table, footer & floating button",
            makeViewController: { SliverScrollViewController() }
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit A11y Benchmark"
        view.backgroundColor = .systemGroupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
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

    /// Build identification for QA reports: iOS version, bundle version, and
    /// the benchmark commit if the build injected one (Info.plist key
    /// `BenchmarkCommit`). The Flutter twin shows the same three lines.
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        let commit = info["BenchmarkCommit"] as? String ?? "dev"
        return "iOS \(os)\napp \(version) (\(build))\nbenchmark commit: \(commit)"
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
        // Pin the fonts explicitly so both benchmark twins use identical metrics.
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
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
