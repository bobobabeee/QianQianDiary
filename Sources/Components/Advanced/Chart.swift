import DGCharts
import SwiftUI

// MARK: - Chart Colors

enum ChartColors {
    static let chart1 = Color(hsl: 12, 0.76, 0.61)
    static let chart2 = Color(hsl: 173, 0.58, 0.39)
    static let chart3 = Color(hsl: 197, 0.37, 0.24)
    static let chart4 = Color(hsl: 43, 0.74, 0.66)
    static let chart5 = Color(hsl: 27, 0.87, 0.67)

    static let all: [Color] = [chart1, chart2, chart3, chart4, chart5]
}

// MARK: - Chart Style

struct ChartStyle {
    var gridLineColor: Color = .init(UIColor.separator).opacity(0.5)
    var labelColor: Color = .init(UIColor.secondaryLabel)
    var valueColor: Color = .init(UIColor.label)
    var legendTextColor: Color = .init(UIColor.secondaryLabel)

    static let `default` = ChartStyle()
}

// MARK: - Chart Data

struct ChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color

    var uiColor: UIColor {
        UIColor(color)
    }

    init(label: String, value: Double, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
}

struct ChartDataSet: Identifiable {
    let id = UUID()
    let name: String
    let data: [Double]
    let color: Color

    var uiColor: UIColor {
        UIColor(color)
    }

    init(name: String, data: [Double], color: Color) {
        self.name = name
        self.data = data
        self.color = color
    }
}

// MARK: - Chart Container

struct AppChart<Content: View>: View {
    let content: Content
    var title: String?
    var subtitle: String?
    var aspectRatio: CGFloat = 16 / 9
    var background: AnyShapeStyle = AnyShapeStyle(Color.clear)
    var padding: CGFloat = 0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 2) {
                    if let title {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .padding(padding)
        }
        .background(background)
    }

    func title(_ value: String) -> Self { configure { $0.title = value } }
    func subtitle(_ value: String) -> Self { configure { $0.subtitle = value } }
    func aspectRatio(_ value: CGFloat) -> Self { configure { $0.aspectRatio = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}

// MARK: - Bar Chart

struct AppBarChart: View {
    let data: [ChartData]
    var animate: Bool = true
    var showLegend: Bool = false
    var showValues: Bool = false
    var enableHighlight: Bool = true
    var showCursor: Bool = true
    var barWidth: Double = 0.7
    var cornerRadius: CGFloat = 4
    var showXAxis: Bool = true
    var showYAxis: Bool = false
    var showGridLines: Bool = true
    var gridLineColor: Color = ChartStyle.default.gridLineColor
    var labelColor: Color = ChartStyle.default.labelColor

    init(data: [ChartData]) {
        self.data = data
    }

    var body: some View {
        BarChartViewRepresentable(
            data: data,
            animate: animate,
            showLegend: showLegend,
            showValues: showValues,
            enableHighlight: enableHighlight,
            showCursor: showCursor,
            barWidth: barWidth,
            cornerRadius: cornerRadius,
            showXAxis: showXAxis,
            showYAxis: showYAxis,
            showGridLines: showGridLines,
            gridLineColor: UIColor(gridLineColor),
            labelColor: UIColor(labelColor)
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func showValues(_ value: Bool) -> Self { configure { $0.showValues = value } }
    func enableHighlight(_ value: Bool) -> Self { configure { $0.enableHighlight = value } }
    func showCursor(_ value: Bool) -> Self { configure { $0.showCursor = value } }
    func barWidth(_ value: Double) -> Self { configure { $0.barWidth = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func showXAxis(_ value: Bool) -> Self { configure { $0.showXAxis = value } }
    func showYAxis(_ value: Bool) -> Self { configure { $0.showYAxis = value } }
    func showGridLines(_ value: Bool) -> Self { configure { $0.showGridLines = value } }
    func gridLineColor(_ value: Color) -> Self { configure { $0.gridLineColor = value } }
    func labelColor(_ value: Color) -> Self { configure { $0.labelColor = value } }
}

private struct BarChartViewRepresentable: UIViewRepresentable {
    let data: [ChartData]
    let animate: Bool
    let showLegend: Bool
    let showValues: Bool
    let enableHighlight: Bool
    let showCursor: Bool
    let barWidth: Double
    let cornerRadius: CGFloat
    let showXAxis: Bool
    let showYAxis: Bool
    let showGridLines: Bool
    let gridLineColor: UIColor
    let labelColor: UIColor

    func makeUIView(context _: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.leftAxis.axisMinimum = 0
        chartView.drawBarShadowEnabled = false
        chartView.drawGridBackgroundEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: BarChartView, context _: Context) {
        let entries = data.enumerated().map { index, item in
            BarChartDataEntry(x: Double(index), y: item.value)
        }

        let dataSet = BarChartDataSet(entries: entries)
        dataSet.colors = data.map(\.uiColor)
        dataSet.drawValuesEnabled = showValues
        dataSet.valueFont = .systemFont(ofSize: 10)
        dataSet.valueColors = [labelColor]
        dataSet.highlightEnabled = enableHighlight
        dataSet.highlightColor = labelColor.withAlphaComponent(0.3)

        let chartData = BarChartData(dataSet: dataSet)
        chartData.barWidth = barWidth

        chartView.data = chartData

        let renderer = RoundedBarChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler,
            cornerRadius: cornerRadius,
            showCursor: showCursor
        )
        chartView.renderer = renderer

        chartView.xAxis.enabled = showXAxis
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: data.map(\.label))
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelTextColor = labelColor

        chartView.leftAxis.enabled = true
        chartView.leftAxis.drawLabelsEnabled = showYAxis
        chartView.leftAxis.drawGridLinesEnabled = showGridLines
        chartView.leftAxis.gridColor = gridLineColor
        chartView.leftAxis.labelTextColor = labelColor
        chartView.leftAxis.drawAxisLineEnabled = false

        chartView.legend.enabled = showLegend
        chartView.legend.textColor = labelColor
        chartView.highlightPerTapEnabled = enableHighlight

        if animate {
            chartView.animate(yAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

// MARK: - Rounded Bar Chart Renderer

private class RoundedBarChartRenderer: BarChartRenderer {
    private var cornerRadius: CGFloat
    private let cursorColor: UIColor = .init(white: 0.96, alpha: 1.0)
    var showCursor: Bool = true

    init(
        dataProvider: BarChartDataProvider,
        animator: Animator,
        viewPortHandler: ViewPortHandler,
        cornerRadius: CGFloat,
        showCursor: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.showCursor = showCursor
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    private func drawRoundedBar(context: CGContext, rect: CGRect, color: UIColor) {
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        context.addPath(path.cgPath)
        context.fillPath()
    }

    override func drawDataSet(context: CGContext, dataSet: BarChartDataSetProtocol, index _: Int) {
        guard let dataProvider else { return }

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        let barData = dataProvider.barData
        let barWidth = barData?.barWidth ?? 0.85
        let phaseY = animator.phaseY

        var barRect = CGRect()

        for i in 0 ..< dataSet.entryCount {
            guard let entry = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }

            let x = entry.x
            let y = entry.y

            let left = CGFloat(x - barWidth / 2)
            let right = CGFloat(x + barWidth / 2)
            let top = CGFloat(y * phaseY)
            let bottom: CGFloat = 0

            barRect.origin.x = left
            barRect.origin.y = top
            barRect.size.width = right - left
            barRect.size.height = bottom - top

            trans.rectValueToPixel(&barRect)

            if !viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width) {
                continue
            }

            if !viewPortHandler.isInBoundsRight(barRect.origin.x) {
                break
            }

            drawRoundedBar(context: context, rect: barRect, color: dataSet.color(atIndex: i))
        }
    }

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        guard let dataProvider,
              let barData = dataProvider.barData else { return }

        let trans = dataProvider.getTransformer(forAxis: .left)
        let phaseY = animator.phaseY
        let barWidth = barData.barWidth

        for highlight in indices {
            let dataSetIndex = highlight.dataSetIndex
            guard let dataSet = barData.dataSets[safe: dataSetIndex] as? BarChartDataSetProtocol,
                  let entry = dataSet.entryForXValue(highlight.x, closestToY: highlight.y) as? BarChartDataEntry else { continue }

            let entryIndex = dataSet.entryIndex(entry: entry)

            var minX = Double.greatestFiniteMagnitude
            var maxX = -Double.greatestFiniteMagnitude

            for (_, ds) in barData.dataSets.enumerated() {
                guard let barDs = ds as? BarChartDataSetProtocol,
                      entryIndex < barDs.entryCount,
                      let e = barDs.entryForIndex(entryIndex) as? BarChartDataEntry else { continue }
                minX = min(minX, e.x - barWidth / 2)
                maxX = max(maxX, e.x + barWidth / 2)
            }

            let centerX = (minX + maxX) / 2
            let totalWidth = maxX - minX
            let cursorWidth = totalWidth + barWidth * 0.5
            let left = CGFloat(centerX - cursorWidth / 2)
            let right = CGFloat(centerX + cursorWidth / 2)
            let top = CGFloat(dataProvider.chartYMax)
            let bottom: CGFloat = 0

            var cursorRect = CGRect(
                x: left,
                y: top,
                width: right - left,
                height: bottom - top
            )

            trans.rectValueToPixel(&cursorRect)

            if showCursor {
                context.setFillColor(cursorColor.cgColor)
                let path = UIBezierPath(roundedRect: cursorRect, cornerRadius: 4)
                context.addPath(path.cgPath)
                context.fillPath()
            }

            for (_, ds) in barData.dataSets.enumerated() {
                guard let barDs = ds as? BarChartDataSetProtocol,
                      entryIndex < barDs.entryCount,
                      let e = barDs.entryForIndex(entryIndex) as? BarChartDataEntry else { continue }

                let x = e.x
                let y = e.y

                let barLeft = CGFloat(x - barWidth / 2)
                let barRight = CGFloat(x + barWidth / 2)
                let barTop = CGFloat(y * phaseY)
                let barBottom: CGFloat = 0

                var barRect = CGRect(
                    x: barLeft,
                    y: barTop,
                    width: barRight - barLeft,
                    height: barBottom - barTop
                )

                trans.rectValueToPixel(&barRect)
                drawRoundedBar(context: context, rect: barRect, color: barDs.color(atIndex: entryIndex))
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Grouped Bar Chart

struct AppGroupedBarChart: View {
    let labels: [String]
    let dataSets: [ChartDataSet]
    var animate: Bool = true
    var showLegend: Bool = true
    var showValues: Bool = false
    var showCursor: Bool = true
    var cornerRadius: CGFloat = 4
    var groupSpace: Double = 0.2
    var barSpace: Double = 0.02
    var barWidth: Double = 0.35
    var showYAxis: Bool = false
    var showGridLines: Bool = true

    init(labels: [String], dataSets: [ChartDataSet]) {
        self.labels = labels
        self.dataSets = dataSets
    }

    var body: some View {
        GroupedBarChartViewRepresentable(
            labels: labels,
            dataSets: dataSets,
            animate: animate,
            showLegend: showLegend,
            showValues: showValues,
            showCursor: showCursor,
            cornerRadius: cornerRadius,
            groupSpace: groupSpace,
            barSpace: barSpace,
            barWidth: barWidth,
            showYAxis: showYAxis,
            showGridLines: showGridLines
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func showValues(_ value: Bool) -> Self { configure { $0.showValues = value } }
    func showCursor(_ value: Bool) -> Self { configure { $0.showCursor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func showYAxis(_ value: Bool) -> Self { configure { $0.showYAxis = value } }
    func showGridLines(_ value: Bool) -> Self { configure { $0.showGridLines = value } }
}

private struct GroupedBarChartViewRepresentable: UIViewRepresentable {
    let labels: [String]
    let dataSets: [ChartDataSet]
    let animate: Bool
    let showLegend: Bool
    let showValues: Bool
    let showCursor: Bool
    let cornerRadius: CGFloat
    let groupSpace: Double
    let barSpace: Double
    let barWidth: Double
    let showYAxis: Bool
    let showGridLines: Bool

    func makeUIView(context _: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.leftAxis.axisMinimum = 0
        chartView.drawBarShadowEnabled = false
        chartView.drawGridBackgroundEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: BarChartView, context _: Context) {
        var barDataSets: [BarChartDataSet] = []

        for dataSet in dataSets {
            let entries = dataSet.data.enumerated().map { index, value in
                BarChartDataEntry(x: Double(index), y: value)
            }
            let barDataSet = BarChartDataSet(entries: entries, label: dataSet.name)
            barDataSet.colors = [dataSet.uiColor]
            barDataSet.drawValuesEnabled = showValues
            barDataSet.valueFont = .systemFont(ofSize: 9)
            barDataSet.highlightEnabled = true
            barDataSets.append(barDataSet)
        }

        let chartData = BarChartData(dataSets: barDataSets)
        chartData.barWidth = barWidth

        let groupCount = labels.count
        let startX: Double = 0
        chartData.groupBars(fromX: startX, groupSpace: groupSpace, barSpace: barSpace)

        chartView.data = chartData

        let renderer = RoundedBarChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler,
            cornerRadius: cornerRadius,
            showCursor: showCursor
        )
        chartView.renderer = renderer

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.centerAxisLabelsEnabled = true
        chartView.xAxis.axisMinimum = startX
        chartView.xAxis.axisMaximum = startX + chartData
            .groupWidth(groupSpace: groupSpace, barSpace: barSpace) * Double(groupCount)
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false

        chartView.leftAxis.enabled = true
        chartView.leftAxis.drawLabelsEnabled = showYAxis
        chartView.leftAxis.drawGridLinesEnabled = showGridLines
        chartView.leftAxis.gridColor = UIColor(white: 0.9, alpha: 0.5)
        chartView.leftAxis.gridLineWidth = 1
        chartView.leftAxis.gridLineDashLengths = nil
        chartView.leftAxis.drawAxisLineEnabled = false

        chartView.legend.enabled = showLegend
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.form = .circle
        chartView.legend.formSize = 8
        chartView.legend.font = .systemFont(ofSize: 12)
        chartView.legend.textColor = UIColor.secondaryLabel
        chartView.legend.yOffset = 10

        chartView.highlightPerTapEnabled = true

        if animate {
            chartView.animate(yAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

// MARK: - Line Chart

struct AppLineChart: View {
    let data: [ChartData]
    var animate: Bool = true
    var showCircles: Bool = true
    var showLegend: Bool = false
    var enableHighlight: Bool = true
    var lineWidth: CGFloat = 2
    var fillEnabled: Bool = true
    var fillAlpha: CGFloat = 0.2
    var curveMode: Bool = true
    var showXAxis: Bool = true
    var showYAxis: Bool = true
    var showGridLines: Bool = true
    var gridLineColor: Color = ChartStyle.default.gridLineColor
    var labelColor: Color = ChartStyle.default.labelColor
    var circleRadius: CGFloat = 4

    init(data: [ChartData]) {
        self.data = data
    }

    var body: some View {
        LineChartViewRepresentable(
            data: data,
            animate: animate,
            showCircles: showCircles,
            showLegend: showLegend,
            enableHighlight: enableHighlight,
            lineWidth: lineWidth,
            fillEnabled: fillEnabled,
            fillAlpha: fillAlpha,
            curveMode: curveMode,
            showXAxis: showXAxis,
            showYAxis: showYAxis,
            showGridLines: showGridLines,
            gridLineColor: UIColor(gridLineColor),
            labelColor: UIColor(labelColor),
            circleRadius: circleRadius
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showCircles(_ value: Bool) -> Self { configure { $0.showCircles = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func enableHighlight(_ value: Bool) -> Self { configure { $0.enableHighlight = value } }
    func lineWidth(_ value: CGFloat) -> Self { configure { $0.lineWidth = value } }
    func fillEnabled(_ value: Bool) -> Self { configure { $0.fillEnabled = value } }
    func fillAlpha(_ value: CGFloat) -> Self { configure { $0.fillAlpha = value } }
    func curveMode(_ value: Bool) -> Self { configure { $0.curveMode = value } }
    func showXAxis(_ value: Bool) -> Self { configure { $0.showXAxis = value } }
    func showYAxis(_ value: Bool) -> Self { configure { $0.showYAxis = value } }
    func showGridLines(_ value: Bool) -> Self { configure { $0.showGridLines = value } }
    func gridLineColor(_ value: Color) -> Self { configure { $0.gridLineColor = value } }
    func labelColor(_ value: Color) -> Self { configure { $0.labelColor = value } }
    func circleRadius(_ value: CGFloat) -> Self { configure { $0.circleRadius = value } }
}

private struct LineChartViewRepresentable: UIViewRepresentable {
    let data: [ChartData]
    let animate: Bool
    let showCircles: Bool
    let showLegend: Bool
    let enableHighlight: Bool
    let lineWidth: CGFloat
    let fillEnabled: Bool
    let fillAlpha: CGFloat
    let curveMode: Bool
    let showXAxis: Bool
    let showYAxis: Bool
    let showGridLines: Bool
    let gridLineColor: UIColor
    let labelColor: UIColor
    let circleRadius: CGFloat

    func makeUIView(context _: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: LineChartView, context _: Context) {
        let entries = data.enumerated().map { index, item in
            ChartDataEntry(x: Double(index), y: item.value)
        }

        let dataSet = LineChartDataSet(entries: entries)
        dataSet.colors = [data.first?.uiColor ?? .systemBlue]
        dataSet.circleColors = data.map(\.uiColor)
        dataSet.drawCirclesEnabled = showCircles
        dataSet.circleRadius = circleRadius
        dataSet.circleHoleRadius = circleRadius * 0.5
        dataSet.lineWidth = lineWidth
        dataSet.mode = curveMode ? .cubicBezier : .linear
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = fillEnabled
        dataSet.fillColor = data.first?.uiColor ?? .systemBlue
        dataSet.fillAlpha = fillAlpha
        dataSet.highlightEnabled = enableHighlight
        dataSet.highlightColor = labelColor.withAlphaComponent(0.5)
        dataSet.highlightLineWidth = 1
        dataSet.drawHorizontalHighlightIndicatorEnabled = false

        let chartData = LineChartData(dataSet: dataSet)
        chartView.data = chartData

        chartView.xAxis.enabled = showXAxis
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: data.map(\.label))
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.labelTextColor = labelColor

        chartView.leftAxis.enabled = true
        chartView.leftAxis.drawLabelsEnabled = showYAxis
        chartView.leftAxis.drawGridLinesEnabled = showGridLines
        chartView.leftAxis.gridColor = gridLineColor
        chartView.leftAxis.labelTextColor = labelColor

        chartView.legend.enabled = showLegend
        chartView.legend.textColor = labelColor
        chartView.highlightPerTapEnabled = enableHighlight

        if animate {
            chartView.animate(xAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

// MARK: - Multi Line Chart

struct AppMultiLineChart: View {
    let labels: [String]
    let dataSets: [ChartDataSet]
    var animate: Bool = true
    var showCircles: Bool = true
    var showLegend: Bool = true
    var enableHighlight: Bool = true
    var lineWidth: CGFloat = 2
    var curveMode: Bool = true

    init(labels: [String], dataSets: [ChartDataSet]) {
        self.labels = labels
        self.dataSets = dataSets
    }

    var body: some View {
        MultiLineChartViewRepresentable(
            labels: labels,
            dataSets: dataSets,
            animate: animate,
            showCircles: showCircles,
            showLegend: showLegend,
            enableHighlight: enableHighlight,
            lineWidth: lineWidth,
            curveMode: curveMode
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showCircles(_ value: Bool) -> Self { configure { $0.showCircles = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func enableHighlight(_ value: Bool) -> Self { configure { $0.enableHighlight = value } }
    func lineWidth(_ value: CGFloat) -> Self { configure { $0.lineWidth = value } }
    func curveMode(_ value: Bool) -> Self { configure { $0.curveMode = value } }
}

private struct MultiLineChartViewRepresentable: UIViewRepresentable {
    let labels: [String]
    let dataSets: [ChartDataSet]
    let animate: Bool
    let showCircles: Bool
    let showLegend: Bool
    let enableHighlight: Bool
    let lineWidth: CGFloat
    let curveMode: Bool

    func makeUIView(context _: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: LineChartView, context _: Context) {
        var lineDataSets: [LineChartDataSet] = []

        for dataSet in dataSets {
            let entries = dataSet.data.enumerated().map { index, value in
                ChartDataEntry(x: Double(index), y: value)
            }
            let lineDataSet = LineChartDataSet(entries: entries, label: dataSet.name)
            lineDataSet.colors = [dataSet.uiColor]
            lineDataSet.circleColors = [dataSet.uiColor]
            lineDataSet.drawCirclesEnabled = showCircles
            lineDataSet.circleRadius = 4
            lineDataSet.circleHoleRadius = 2
            lineDataSet.lineWidth = lineWidth
            lineDataSet.mode = curveMode ? .cubicBezier : .linear
            lineDataSet.drawValuesEnabled = false
            lineDataSet.highlightEnabled = enableHighlight
            lineDataSet.highlightColor = dataSet.uiColor.withAlphaComponent(0.5)
            lineDataSet.highlightLineWidth = 1
            lineDataSet.drawHorizontalHighlightIndicatorEnabled = false
            lineDataSets.append(lineDataSet)
        }

        let chartData = LineChartData(dataSets: lineDataSets)
        chartView.data = chartData

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.gridColor = UIColor(white: 0.9, alpha: 0.5)

        chartView.legend.enabled = showLegend
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.form = .line
        chartView.legend.formSize = 16
        chartView.legend.font = .systemFont(ofSize: 11)

        chartView.highlightPerTapEnabled = enableHighlight

        if animate {
            chartView.animate(xAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

// MARK: - Area Chart

struct AppAreaChart: View {
    let data: [ChartData]
    var animate: Bool = true
    var showLegend: Bool = false
    var enableHighlight: Bool = true
    var lineWidth: CGFloat = 2
    var fillAlpha: CGFloat = 0.3
    var curveMode: Bool = true

    init(data: [ChartData]) {
        self.data = data
    }

    var body: some View {
        AreaChartViewRepresentable(
            data: data,
            animate: animate,
            showLegend: showLegend,
            enableHighlight: enableHighlight,
            lineWidth: lineWidth,
            fillAlpha: fillAlpha,
            curveMode: curveMode
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func enableHighlight(_ value: Bool) -> Self { configure { $0.enableHighlight = value } }
    func lineWidth(_ value: CGFloat) -> Self { configure { $0.lineWidth = value } }
    func fillAlpha(_ value: CGFloat) -> Self { configure { $0.fillAlpha = value } }
    func curveMode(_ value: Bool) -> Self { configure { $0.curveMode = value } }
}

private struct AreaChartViewRepresentable: UIViewRepresentable {
    let data: [ChartData]
    let animate: Bool
    let showLegend: Bool
    let enableHighlight: Bool
    let lineWidth: CGFloat
    let fillAlpha: CGFloat
    let curveMode: Bool

    func makeUIView(context _: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.leftAxis.axisMinimum = 0
        return chartView
    }

    func updateUIView(_ chartView: LineChartView, context _: Context) {
        let entries = data.enumerated().map { index, item in
            ChartDataEntry(x: Double(index), y: item.value)
        }

        let dataSet = LineChartDataSet(entries: entries)
        let mainColor = data.first?.uiColor ?? .systemBlue
        dataSet.colors = [mainColor]
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = lineWidth
        dataSet.mode = curveMode ? .cubicBezier : .linear
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = mainColor
        dataSet.fillAlpha = fillAlpha
        dataSet.highlightEnabled = enableHighlight
        dataSet.highlightColor = mainColor.withAlphaComponent(0.7)
        dataSet.highlightLineWidth = 1
        dataSet.drawHorizontalHighlightIndicatorEnabled = false

        let chartData = LineChartData(dataSet: dataSet)
        chartView.data = chartData

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: data.map(\.label))
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.gridColor = UIColor(white: 0.9, alpha: 0.5)

        chartView.legend.enabled = showLegend
        chartView.highlightPerTapEnabled = enableHighlight

        if animate {
            chartView.animate(xAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

// MARK: - Pie Chart

struct AppPieChart: View {
    let data: [ChartData]
    var animate: Bool = true
    var showLabels: Bool = true
    var showLegend: Bool = true
    var showPercentage: Bool = true
    var holeRadius: CGFloat = 0.5
    var enableHighlight: Bool = true

    init(data: [ChartData]) {
        self.data = data
    }

    var body: some View {
        PieChartViewRepresentable(
            data: data,
            animate: animate,
            showLabels: showLabels,
            showLegend: showLegend,
            showPercentage: showPercentage,
            holeRadius: holeRadius,
            enableHighlight: enableHighlight
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showLabels(_ value: Bool) -> Self { configure { $0.showLabels = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func showPercentage(_ value: Bool) -> Self { configure { $0.showPercentage = value } }
    func holeRadius(_ value: CGFloat) -> Self { configure { $0.holeRadius = value } }
    func enableHighlight(_ value: Bool) -> Self { configure { $0.enableHighlight = value } }
}

private struct PieChartViewRepresentable: UIViewRepresentable {
    let data: [ChartData]
    let animate: Bool
    let showLabels: Bool
    let showLegend: Bool
    let showPercentage: Bool
    let holeRadius: CGFloat
    let enableHighlight: Bool

    func makeUIView(context _: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.rotationEnabled = false
        chartView.drawCenterTextEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: PieChartView, context _: Context) {
        let entries = data.map { item in
            PieChartDataEntry(value: item.value, label: item.label)
        }

        let dataSet = PieChartDataSet(entries: entries)
        dataSet.colors = data.map(\.uiColor)
        dataSet.drawValuesEnabled = showLabels
        dataSet.valueFont = .systemFont(ofSize: 11, weight: .medium)
        dataSet.valueTextColor = .white
        dataSet.sliceSpace = 2
        dataSet.selectionShift = 8
        dataSet.highlightEnabled = enableHighlight

        if showPercentage {
            chartView.usePercentValuesEnabled = true
            dataSet.valueFormatter = PercentFormatter()
        } else {
            chartView.usePercentValuesEnabled = false
            dataSet.valueFormatter = DefaultValueFormatter(decimals: 0)
        }

        let chartData = PieChartData(dataSet: dataSet)
        chartView.data = chartData

        chartView.holeRadiusPercent = holeRadius
        chartView.transparentCircleRadiusPercent = holeRadius > 0 ? holeRadius + 0.03 : 0
        chartView.drawEntryLabelsEnabled = false

        chartView.legend.enabled = showLegend
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.form = .circle
        chartView.legend.formSize = 8
        chartView.legend.font = .systemFont(ofSize: 12)
        chartView.legend.textColor = UIColor.secondaryLabel
        chartView.legend.yOffset = 10
        chartView.legend.xEntrySpace = 16

        chartView.highlightPerTapEnabled = enableHighlight

        if animate {
            chartView.animate(xAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}

private class PercentFormatter: ValueFormatter {
    func stringForValue(
        _ value: Double,
        entry _: ChartDataEntry,
        dataSetIndex _: Int,
        viewPortHandler _: ViewPortHandler?
    ) -> String {
        "\(Int(round(value)))%"
    }
}

// MARK: - Radar Chart

struct AppRadarChart: View {
    let labels: [String]
    let dataSets: [ChartDataSet]
    var animate: Bool = true
    var showLegend: Bool = true
    var fillAlpha: CGFloat = 0.3

    init(labels: [String], dataSets: [ChartDataSet]) {
        self.labels = labels
        self.dataSets = dataSets
    }

    var body: some View {
        RadarChartViewRepresentable(
            labels: labels,
            dataSets: dataSets,
            animate: animate,
            showLegend: showLegend,
            fillAlpha: fillAlpha
        )
    }

    func animate(_ value: Bool) -> Self { configure { $0.animate = value } }
    func showLegend(_ value: Bool) -> Self { configure { $0.showLegend = value } }
    func fillAlpha(_ value: CGFloat) -> Self { configure { $0.fillAlpha = value } }
}

private struct RadarChartViewRepresentable: UIViewRepresentable {
    let labels: [String]
    let dataSets: [ChartDataSet]
    let animate: Bool
    let showLegend: Bool
    let fillAlpha: CGFloat

    func makeUIView(context _: Context) -> RadarChartView {
        let chartView = RadarChartView()
        chartView.rotationEnabled = false
        return chartView
    }

    func updateUIView(_ chartView: RadarChartView, context _: Context) {
        var radarDataSets: [RadarChartDataSet] = []

        for dataSet in dataSets {
            let entries = dataSet.data.map { value in
                RadarChartDataEntry(value: value)
            }
            let radarDataSet = RadarChartDataSet(entries: entries, label: dataSet.name)
            radarDataSet.colors = [dataSet.uiColor]
            radarDataSet.fillColor = dataSet.uiColor
            radarDataSet.drawFilledEnabled = true
            radarDataSet.fillAlpha = fillAlpha
            radarDataSet.lineWidth = 2
            radarDataSet.drawValuesEnabled = false
            radarDataSets.append(radarDataSet)
        }

        let chartData = RadarChartData(dataSets: radarDataSets)
        chartView.data = chartData

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelFont = .systemFont(ofSize: 10)
        chartView.yAxis.drawLabelsEnabled = false
        chartView.webLineWidth = 1
        chartView.innerWebLineWidth = 1
        chartView.webColor = UIColor.separator
        chartView.innerWebColor = UIColor.separator.withAlphaComponent(0.5)

        chartView.legend.enabled = showLegend
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.form = .circle
        chartView.legend.formSize = 8
        chartView.legend.font = .systemFont(ofSize: 12)
        chartView.legend.textColor = UIColor.secondaryLabel
        chartView.legend.yOffset = 10

        if animate {
            chartView.animate(xAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
    }
}
