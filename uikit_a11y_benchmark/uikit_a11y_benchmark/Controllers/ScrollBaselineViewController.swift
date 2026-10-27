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
    private let secondaryScrollView = UIScrollView()
    private let tableView = BaselineTableView(frame: .zero, style: .plain)

    private var previousFrameOffsetY: CGFloat = 0
    private var gestureStartOffsetY: CGFloat = 0
    private var lastScrollDeltaY: CGFloat = 0
    private var lastStepDeltaY: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scroll Baseline"
        view.backgroundColor = .systemBackground

        configureHeader()
        configureSecondaryScrollView()
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
        headerContainerView.accessibilityIdentifier = "scroll.headerView"

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

        offsetYLabel.accessibilityIdentifier = "scroll.offsetYLabel"
        heightLabel.accessibilityIdentifier = "scroll.heightLabel"
        deltaLabel.accessibilityIdentifier = "scroll.deltaLabel"
        ratioLabel.accessibilityIdentifier = "scroll.ratioLabel"
        pageScrolledLabel.accessibilityIdentifier = "scroll.pageScrolledLabel"

        headerContainerView.addSubview(metricsStack)
        view.addSubview(headerContainerView)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            metricsStack.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 10),
            metricsStack.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -16),
        ])
    }

    private func configureSecondaryScrollView() {
        // Secondary nested horizontal UIScrollView with scrollsToTop = false
        // so status-bar tap scroll-to-top remains deterministic on the primary UITableView.
        secondaryScrollView.translatesAutoresizingMaskIntoConstraints = false
        secondaryScrollView.scrollsToTop = false
        secondaryScrollView.showsHorizontalScrollIndicator = false
        secondaryScrollView.accessibilityIdentifier = "scroll.secondaryScrollView"
        secondaryScrollView.backgroundColor = .tertiarySystemBackground
        secondaryScrollView.layer.cornerRadius = 6

        let chipStack = UIStackView()
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        chipStack.axis = .horizontal
        chipStack.spacing = 8

        for index in 1...8 {
            let chipLabel = UILabel()
            chipLabel.font = .systemFont(ofSize: 12, weight: .medium)
            chipLabel.text = "Tag #\(index) (scrollsToTop=false)"
            chipLabel.textColor = .secondaryLabel
            chipLabel.backgroundColor = .quaternarySystemFill
            chipLabel.layer.cornerRadius = 4
            chipLabel.clipsToBounds = true
            chipLabel.accessibilityIdentifier = "scroll.secondaryChip.\(index)"
            chipStack.addArrangedSubview(chipLabel)
        }

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator

        secondaryScrollView.addSubview(chipStack)
        headerContainerView.addSubview(secondaryScrollView)
        headerContainerView.addSubview(separator)

        NSLayoutConstraint.activate([
            secondaryScrollView.topAnchor.constraint(equalTo: pageScrolledLabel.bottomAnchor, constant: 8),
            secondaryScrollView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            secondaryScrollView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -16),
            secondaryScrollView.heightAnchor.constraint(equalToConstant: 32),
            secondaryScrollView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -10),

            chipStack.topAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.topAnchor, constant: 4),
            chipStack.leadingAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            chipStack.trailingAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            chipStack.bottomAnchor.constraint(equalTo: secondaryScrollView.contentLayoutGuide.bottomAnchor, constant: -4),
            chipStack.heightAnchor.constraint(equalTo: secondaryScrollView.frameLayoutGuide.heightAnchor, constant: -8),

            separator.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "scroll.tableView"
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        tableView.onWillBeginAccessibilityScroll = { [weak self] startOffsetY in
            self?.gestureStartOffsetY = startOffsetY
        }
        tableView.onDidPerformAccessibilityScroll = { [weak self] direction in
            guard let self else { return }
            let status = self.computePageScrollStatus(for: self.tableView)
            self.pageScrolledLabel.text = "Page Scroll Status: \(status) (dir=\(direction.rawValue))"
            self.pageScrolledLabel.accessibilityValue = status
            Self.logger.info(
                "[ScrollBaseline] UIAccessibilityPageScrolledNotification status: \(status, privacy: .public)"
            )
            print("[ScrollBaseline] UIAccessibilityPageScrolledNotification status: \(status)")
        }
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

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
        offsetYLabel.accessibilityValue = String(format: "%.1f", contentOffsetY)

        heightLabel.text = String(format: "frame.size.height: %.1f", viewportHeight)
        heightLabel.accessibilityValue = String(format: "%.1f", viewportHeight)

        deltaLabel.text = String(format: "Δy: %.1f (step: %.1f)", deltaY, stepDeltaY)
        deltaLabel.accessibilityValue = String(format: "%.1f", deltaY)

        ratioLabel.text = String(
            format: "Δy / viewportHeight: %.3f (%.1f%%)",
            ratio,
            ratio * 100.0
        )
        ratioLabel.accessibilityValue = String(format: "%.3f", ratio)

        pageScrolledLabel.text = "Page Scroll Status: \(pageStatus)"
        pageScrolledLabel.accessibilityValue = pageStatus
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
        cell.contentConfiguration = content
        cell.accessibilityIdentifier = "scroll.cell.\(indexPath.row)"
        return cell
    }
}

// MARK: - UITableViewDelegate & UIScrollViewAccessibilityDelegate

extension ScrollBaselineViewController: UITableViewDelegate, UIScrollViewAccessibilityDelegate {

    func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
        guard scrollView === tableView else { return nil }
        let status = computePageScrollStatus(for: scrollView)
        Self.logger.info(
            "[ScrollBaseline] accessibilityScrollStatus: \(status, privacy: .public)"
        )
        print("[ScrollBaseline] accessibilityScrollStatus: \(status)")
        return status
    }

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
            "[ScrollBaseline] contentOffset.y=\(currentOffsetY, format: .fixed(precision: 1)) frame.size.height=\(viewportHeight, format: .fixed(precision: 1)) Δy=\(deltaY, format: .fixed(precision: 1)) ratio=\(ratio, format: .fixed(precision: 3))"
        )
        print(
            String(
                format: "[ScrollBaseline] contentOffset.y=%.1f frame.size.height=%.1f Δy=%.1f ratio=%.3f",
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

// MARK: - BaselineTableView

final class BaselineTableView: UITableView {

    var onWillBeginAccessibilityScroll: ((CGFloat) -> Void)?
    var onDidPerformAccessibilityScroll: ((UIAccessibilityScrollDirection) -> Void)?

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        onWillBeginAccessibilityScroll?(contentOffset.y)
        let handled = super.accessibilityScroll(direction)
        if handled {
            onDidPerformAccessibilityScroll?(direction)
        }
        return handled
    }
}
