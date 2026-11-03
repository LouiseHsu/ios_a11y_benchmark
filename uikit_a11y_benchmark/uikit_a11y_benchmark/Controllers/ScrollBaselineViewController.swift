import UIKit
import os

final class ScrollBaselineViewController: UIViewController {

    private static let cellReuseIdentifier = "ScrollBaselineCell"
    private static let rowCount = 100
    private static let logger = Logger(subsystem: "com.example.uikit-a11y-benchmark", category: "ScrollBaseline")

    private let headerContainerView = UIView()
    private let offsetYLabel = UILabel()
    private let heightLabel = UILabel()
    private let deltaLabel = UILabel()
    private let ratioLabel = UILabel()
    private let pageScrolledLabel = UILabel()
    private let chipStripScrollView = UIScrollView()
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
    /// Plain views only; nothing here touches UIAccessibility — the fixture is
    /// how the system handles a nested horizontal scroll view by itself.
    private func configureChipStrip() {
        chipStripScrollView.translatesAutoresizingMaskIntoConstraints = false
        chipStripScrollView.showsHorizontalScrollIndicator = true
        // Keep the status-bar tap targeting the table, not this strip.
        chipStripScrollView.scrollsToTop = false

        let chipStack = UIStackView()
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        chipStack.axis = .horizontal
        chipStack.alignment = .center
        chipStack.spacing = 8

        for index in 1...20 {
            let chip = UIView()
            chip.backgroundColor = .secondarySystemFill
            chip.layer.cornerRadius = 12

            let chipLabel = UILabel()
            chipLabel.translatesAutoresizingMaskIntoConstraints = false
            chipLabel.text = "Chip \(index)"
            chipLabel.font = .preferredFont(forTextStyle: .body)
            chipLabel.textAlignment = .center
            chip.addSubview(chipLabel)

            NSLayoutConstraint.activate([
                chip.widthAnchor.constraint(equalToConstant: 120),
                chip.heightAnchor.constraint(equalToConstant: 56),
                chipLabel.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
                chipLabel.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            ])
            chipStack.addArrangedSubview(chip)
        }

        chipStripScrollView.addSubview(chipStack)
        view.addSubview(chipStripScrollView)

        NSLayoutConstraint.activate([
            chipStripScrollView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            chipStripScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipStripScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipStripScrollView.heightAnchor.constraint(equalToConstant: 72),

            chipStack.topAnchor.constraint(equalTo: chipStripScrollView.contentLayoutGuide.topAnchor),
            chipStack.leadingAnchor.constraint(equalTo: chipStripScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            chipStack.trailingAnchor.constraint(equalTo: chipStripScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            chipStack.bottomAnchor.constraint(equalTo: chipStripScrollView.contentLayoutGuide.bottomAnchor),
            chipStack.heightAnchor.constraint(equalTo: chipStripScrollView.frameLayoutGuide.heightAnchor),
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
            tableView.topAnchor.constraint(equalTo: chipStripScrollView.bottomAnchor),
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
