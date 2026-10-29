import UIKit
import os

/// UIKit twin of the Flutter `SliverScrollPage`.
///
/// Native idiom mapping:
///  * `SliverAppBar(pinned: true, expandedHeight: 160)` → a large-title
///    navigation bar that collapses into the compact title as the table scrolls.
///  * `SliverList` of 60 rows → a plain `UITableView`.
///  * `SliverFillRemaining` footer → `tableFooterView` with a header label and
///    a button.
///  * `FloatingActionButton` → there is no stock FAB in UIKit. A stock iOS app
///    would normally put "Compose" in a `UIToolbar` (Mail) or a bar button
///    item; the closest stock control that keeps the same *layering* under test
///    (a button floating over a long scrolling list, like the Maps tracking
///    button) is a circular `UIButton` pinned bottom-trailing above the table.
final class SliverScrollViewController: UIViewController {

    private static let cellReuseIdentifier = "SliverScrollCell"
    private static let rowCount = 60
    private static let fabDiameter: CGFloat = 56
    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "SliverScroll")

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let footerContainerView = UIView()
    private let footerHeaderLabel = UILabel()
    private let footerActionButton = UIButton(type: .system)
    private let footerTapCountLabel = UILabel()
    private let composeButton = UIButton(type: .system)

    private var fabTapCount = 0
    private var footerTapCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sliver Scroll"
        view.backgroundColor = .systemBackground
        // Large title collapses on scroll: the native twin of a pinned,
        // expanded SliverAppBar.
        navigationItem.largeTitleDisplayMode = .always

        configureTableView()
        configureFooter()
        configureComposeButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore the menu's compact title bar.
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // tableFooterView is frame-based: keep its width in sync with the table.
        if footerContainerView.frame.width != tableView.bounds.width {
            footerContainerView.frame.size.width = tableView.bounds.width
            tableView.tableFooterView = footerContainerView
        }
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "sliver.list"
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 60
        // Keep the last rows / footer reachable above the floating button
        // (Flutter twin: 96pt bottom padding inside SliverFillRemaining).
        tableView.contentInset.bottom = Self.fabDiameter + 32
        tableView.verticalScrollIndicatorInsets.bottom = Self.fabDiameter + 32
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Pinned to the view (not the safe area) so the large title
            // collapses natively as the content scrolls underneath the bar.
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureFooter() {
        footerHeaderLabel.text = "End of List"
        footerHeaderLabel.font = .preferredFont(forTextStyle: .title2)
        footerHeaderLabel.adjustsFontForContentSizeCategory = true
        footerHeaderLabel.numberOfLines = 0
        footerHeaderLabel.accessibilityTraits.insert(.header)
        footerHeaderLabel.accessibilityIdentifier = "sliver.footerHeader"

        var footerConfig = UIButton.Configuration.filled()
        footerConfig.title = "Footer Action"
        footerActionButton.configuration = footerConfig
        footerActionButton.accessibilityIdentifier = "sliver.footerButton"
        footerActionButton.addTarget(
            self,
            action: #selector(footerActionTapped),
            for: .touchUpInside
        )

        footerTapCountLabel.text = "Footer Action taps: 0"
        footerTapCountLabel.font = .preferredFont(forTextStyle: .footnote)
        footerTapCountLabel.textColor = .secondaryLabel
        footerTapCountLabel.adjustsFontForContentSizeCategory = true

        let footerStack = UIStackView(arrangedSubviews: [
            footerHeaderLabel,
            footerActionButton,
            footerTapCountLabel,
        ])
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerStack.axis = .vertical
        footerStack.alignment = .leading
        footerStack.spacing = 12

        footerContainerView.addSubview(footerStack)
        NSLayoutConstraint.activate([
            footerStack.topAnchor.constraint(equalTo: footerContainerView.topAnchor, constant: 24),
            footerStack.leadingAnchor.constraint(equalTo: footerContainerView.leadingAnchor, constant: 16),
            footerStack.trailingAnchor.constraint(equalTo: footerContainerView.trailingAnchor, constant: -16),
            footerStack.bottomAnchor.constraint(equalTo: footerContainerView.bottomAnchor, constant: -24),
        ])

        // tableFooterView needs an explicit frame height; width is fixed up in
        // viewDidLayoutSubviews.
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let fittingHeight = footerContainerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        footerContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: max(fittingHeight, 160))
        tableView.tableFooterView = footerContainerView
    }

    private func configureComposeButton() {
        var composeConfig = UIButton.Configuration.filled()
        composeConfig.image = UIImage(systemName: "plus")
        composeConfig.cornerStyle = .capsule
        composeConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        composeButton.configuration = composeConfig
        composeButton.translatesAutoresizingMaskIntoConstraints = false
        composeButton.accessibilityLabel = "Compose"
        composeButton.accessibilityIdentifier = "sliver.fab"
        composeButton.layer.shadowColor = UIColor.black.cgColor
        composeButton.layer.shadowOpacity = 0.25
        composeButton.layer.shadowRadius = 6
        composeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        composeButton.addTarget(
            self,
            action: #selector(composeTapped),
            for: .touchUpInside
        )
        // Added after the table so it is layered on top of it.
        view.addSubview(composeButton)

        NSLayoutConstraint.activate([
            composeButton.widthAnchor.constraint(equalToConstant: Self.fabDiameter),
            composeButton.heightAnchor.constraint(equalToConstant: Self.fabDiameter),
            composeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            composeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    @objc private func composeTapped() {
        fabTapCount += 1
        let message = "Compose FAB Tapped (Count: \(fabTapCount))"
        Self.logger.info("[SliverScroll] \(message, privacy: .public)")
        print("[SliverScroll] \(message)")
    }

    @objc private func footerActionTapped() {
        footerTapCount += 1
        footerTapCountLabel.text = "Footer Action taps: \(footerTapCount)"
        let message = "Footer Action Tapped (Count: \(footerTapCount))"
        Self.logger.info("[SliverScroll] \(message, privacy: .public)")
        print("[SliverScroll] \(message)")
    }
}

// MARK: - UITableViewDataSource

extension SliverScrollViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellReuseIdentifier,
            for: indexPath
        )
        // Rows are 1-based ("Sliver Item 1" … "Sliver Item 60") on both platforms.
        let itemNumber = indexPath.row + 1
        var content = cell.defaultContentConfiguration()
        content.text = "Sliver Item \(itemNumber)"
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.accessibilityIdentifier = "sliver.row.\(itemNumber)"
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SliverScrollViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        Self.logger.debug(
            "[SliverScroll] contentOffset.y=\(scrollView.contentOffset.y, format: .fixed(precision: 1))"
        )
    }
}
