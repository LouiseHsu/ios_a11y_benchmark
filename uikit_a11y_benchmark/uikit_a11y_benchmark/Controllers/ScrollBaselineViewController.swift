import UIKit
import os

final class ScrollBaselineViewController: UIViewController {

    private static let cellReuseIdentifier = "ScrollBaselineCell"
    private static let chipCellReuseIdentifier = "ScrollBaselineChipCell"
    private static let rowCount = 100
    private static let chipCount = 20
    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "ScrollBaseline")

    private let headerContainerView = UIView()
    private let offsetYLabel = UILabel()
    private let heightLabel = UILabel()
    private let deltaLabel = UILabel()
    private let ratioLabel = UILabel()
    private let pageScrolledLabel = UILabel()
    private let chipCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 56)
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var previousFrameOffsetY: CGFloat = 0
    private var gestureStartOffsetY: CGFloat = 0
    private var lastScrollDeltaY: CGFloat = 0
    private var lastStepDeltaY: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scroll Baseline"
        view.backgroundColor = .systemBackground

        configureHeader()
        configureChipStrip()
        configureTableView()
        updateMetricsDisplay(contentOffsetY: 0, viewportHeight: 0, deltaY: 0, stepDeltaY: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMetricsDisplay(
            contentOffsetY: tableView.contentOffset.y,
            viewportHeight: tableView.frame.size.height,
            deltaY: lastScrollDeltaY,
            stepDeltaY: lastStepDeltaY
        )
    }

    private func configureHeader() {
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.backgroundColor = .secondarySystemBackground

        let metricsStack = UIStackView(arrangedSubviews: [
            offsetYLabel,
            heightLabel,
            deltaLabel,
            ratioLabel,
            pageScrolledLabel,
        ])
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        metricsStack.axis = .vertical
        metricsStack.spacing = 4

        for label in [offsetYLabel, heightLabel, deltaLabel, ratioLabel, pageScrolledLabel] {
            label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            label.textColor = .label
        }
        pageScrolledLabel.textColor = .secondaryLabel
        pageScrolledLabel.text = "Page Scroll Status: Page 1 of 1"

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator

        headerContainerView.addSubview(metricsStack)
        headerContainerView.addSubview(separator)
        view.addSubview(headerContainerView)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            metricsStack.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 10),
            metricsStack.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -16),
            metricsStack.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -10),

            separator.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    /// Horizontal strip of 20 chips between the metrics header and the table.
    /// A horizontal UICollectionView so cells are recycled like Flutter's
    /// ListView.builder. Nothing here touches UIAccessibility — the fixture is
    /// how the system handles a nested horizontal scroll view by itself.
    private func configureChipStrip() {
        chipCollectionView.translatesAutoresizingMaskIntoConstraints = false
        chipCollectionView.backgroundColor = .clear
        chipCollectionView.showsHorizontalScrollIndicator = true
        // Keep the status-bar tap targeting the table, not this strip.
        chipCollectionView.scrollsToTop = false
        // Delegate intentionally left nil so this strip never reaches the
        // scroll-view delegate methods that feed the table metrics.
        chipCollectionView.dataSource = self
        chipCollectionView.register(ChipCell.self, forCellWithReuseIdentifier: Self.chipCellReuseIdentifier)
        view.addSubview(chipCollectionView)

        NSLayoutConstraint.activate([
            chipCollectionView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            chipCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipCollectionView.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: chipCollectionView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // On-screen diagnostic only. VoiceOver's own "Page X of Y" scroll status is
    // deliberately left to the system; nothing here feeds UIAccessibility.
    private func computePageScrollStatus(for scrollView: UIScrollView) -> String {
        let viewportHeight = max(1, scrollView.frame.size.height)
        let contentHeight = max(viewportHeight, scrollView.contentSize.height)
        let totalPages = max(1, Int(ceil(contentHeight / viewportHeight)))
        let currentPage = min(
            totalPages,
            max(1, Int(floor((scrollView.contentOffset.y + viewportHeight * 0.5) / viewportHeight)) + 1)
        )
        return "Page \(currentPage) of \(totalPages)"
    }

    private func updateMetricsDisplay(
        contentOffsetY: CGFloat,
        viewportHeight: CGFloat,
        deltaY: CGFloat,
        stepDeltaY: CGFloat
    ) {
        let ratio = viewportHeight > 0 ? (deltaY / viewportHeight) : 0
        let pageStatus = computePageScrollStatus(for: tableView)

        offsetYLabel.text = String(format: "contentOffset.y: %.1f", contentOffsetY)
        heightLabel.text = String(format: "frame.size.height: %.1f", viewportHeight)
        deltaLabel.text = String(format: "deltaY: %.1f (step: %.1f)", deltaY, stepDeltaY)
        ratioLabel.text = String(
            format: "deltaY / viewportHeight: %.3f (%.1f%%)",
            ratio,
            ratio * 100.0
        )
        pageScrolledLabel.text = "Page Scroll Status: \(pageStatus)"
    }
}

// MARK: - UITableViewDataSource

extension ScrollBaselineViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellReuseIdentifier,
            for: indexPath
        )
        var content = cell.defaultContentConfiguration()
        content.text = "Item #\(indexPath.row)"
        content.secondaryText = "Baseline scroll row \(indexPath.row + 1) of \(Self.rowCount)"
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UICollectionViewDataSource (chip strip)

extension ScrollBaselineViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Self.chipCount
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.chipCellReuseIdentifier,
            for: indexPath
        )
        if let chipCell = cell as? ChipCell {
            chipCell.label.text = "Chip \(indexPath.item + 1)"
        }
        return cell
    }
}

// MARK: - ChipCell

/// Recycled chip cell for the horizontal strip. Plain label only; no
/// accessibility code so the system's default handling is what gets measured.
final class ChipCell: UICollectionViewCell {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemFill
        contentView.layer.cornerRadius = 12

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDelegate

extension ScrollBaselineViewController: UITableViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        gestureStartOffsetY = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }

        let currentOffsetY = scrollView.contentOffset.y
        let stepDeltaY = currentOffsetY - previousFrameOffsetY
        previousFrameOffsetY = currentOffsetY

        let deltaY = currentOffsetY - gestureStartOffsetY
        lastScrollDeltaY = deltaY
        lastStepDeltaY = stepDeltaY

        let viewportHeight = scrollView.frame.size.height
        let ratio = viewportHeight > 0 ? (deltaY / viewportHeight) : 0

        updateMetricsDisplay(
            contentOffsetY: currentOffsetY,
            viewportHeight: viewportHeight,
            deltaY: deltaY,
            stepDeltaY: stepDeltaY
        )

        Self.logger.info(
            "[ScrollBaseline] contentOffset.y=\(currentOffsetY, format: .fixed(precision: 1)) frame.size.height=\(viewportHeight, format: .fixed(precision: 1)) deltaY=\(deltaY, format: .fixed(precision: 1)) ratio=\(ratio, format: .fixed(precision: 3))"
        )
        print(
            String(
                format: "[ScrollBaseline] contentOffset.y=%.1f frame.size.height=%.1f deltaY=%.1f ratio=%.3f",
                currentOffsetY,
                viewportHeight,
                deltaY,
                ratio
            )
        )
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView === tableView else { return false }
        gestureStartOffsetY = scrollView.contentOffset.y
        return true
    }
}
