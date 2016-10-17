package com.sirolf2009.samurai.renderer

import com.sirolf2009.samurai.renderer.chart.ChartData
import com.sirolf2009.samurai.renderer.chart.NumberAxis
import eu.verdelhan.ta4j.Decimal
import eu.verdelhan.ta4j.Indicator
import eu.verdelhan.ta4j.Tick
import eu.verdelhan.ta4j.TimeSeries
import java.util.List
import javafx.scene.canvas.Canvas
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import javafx.scene.text.Text
import com.sirolf2009.samurai.renderer.chart.DateAxis
import javafx.geometry.VPos
import javafx.scene.text.TextAlignment
import com.sirolf2009.samurai.renderer.chart.Marker

class RendererDefault implements IRenderer {

	public static val WIDTH_CANDLESTICK = 9
	public static val WIDTH_WICK = 1
	public static val SPACING = 2
	public static val WIDTH_TICK = WIDTH_CANDLESTICK + SPACING
	public static val Y_AXIS_SIZE = 48
	public static val X_AXIS_SIZE = 24
	public static val AXIS_OFFSET = 16

	override drawChart(ChartData chart, Canvas canvas, GraphicsContext g, int x, double scaleX) {
		val panels = 2 + chart.indicators.size // price chart counts as 2, because it should be twice as big
		val heightPerPanel = (canvas.height - X_AXIS_SIZE - AXIS_OFFSET) / panels

		drawTimeseries(chart.timeseries, chart.markers.filter[key == 0].map[value].toList(), g, canvas.width, heightPerPanel * 2, x, scaleX)
		g.translate(0, heightPerPanel * 2)
		chart.indicators.forEach [ indicator, index |
			g.stroke = Color.WHITE
			g.lineWidth = 2
			g.strokeLine(0, 0, canvas.width, 0)

			drawLineIndicator(indicator, chart.markers.filter[key == index+1].map[value].toList(), g, canvas.width, heightPerPanel, x, scaleX)
			g.translate(0, heightPerPanel)
		]

		val panelWidth = canvas.width - Y_AXIS_SIZE - AXIS_OFFSET
		val widthCandleRendered = WIDTH_TICK * scaleX
		val startCandle = Math.max(0, Math.floor(x / widthCandleRendered)) as int
		val endCandle = Math.max(0, Math.min(chart.timeseries.tickCount - 1, startCandle + Math.floor(panelWidth / widthCandleRendered) as int))
		val candles = (startCandle .. endCandle).map[chart.timeseries.getTick(it)].toList()
		drawXAxis(canvas.width, g, candles)
	}

	def drawTimeseries(TimeSeries series, List<Marker> markers, GraphicsContext g, double width, double height, int x, double scaleX) {
		g.setLineWidth(1)
		g.fill = Color.WHITE
		g.fillText(series.name, Y_AXIS_SIZE + 2, g.font.size + 2)

		val panelWidth = width - Y_AXIS_SIZE - AXIS_OFFSET
		val panelHeight = height - AXIS_OFFSET

		val widthCandleRendered = WIDTH_TICK * scaleX
		val startCandle = Math.max(0, Math.floor(x / widthCandleRendered)) as int
		val endCandle = Math.max(0, Math.min(series.tickCount - 1, startCandle + Math.floor(panelWidth / widthCandleRendered) as int))
		val candles = (startCandle .. endCandle).map[series.getTick(it)].toList()
		val minPrice = candles.min[a, b|a.minPrice.compareTo(b.minPrice)].minPrice.toDouble
		val maxPrice = candles.max[a, b|a.maxPrice.compareTo(b.maxPrice)].maxPrice.toDouble

		val axis = NumberAxis.fromRange(minPrice, maxPrice, panelHeight)
		val map = [
			val valueToAxis = map(it, minPrice, maxPrice, axis.minValue, axis.maxValue)
			val valueOnChart = map(valueToAxis, axis.minValue, axis.maxValue, 0, -panelHeight)
			valueOnChart
		]

		g.save()
		g.translate(Y_AXIS_SIZE + (AXIS_OFFSET / 2), height - (AXIS_OFFSET / 2))
		g.scale(scaleX, 1)

		candles.forEach [ it, index |
			val yWick = map.apply(it.maxPrice.toDouble)
			val lengthWick = map.apply(it.minPrice.toDouble) - yWick

			val upper = it.openPrice.max(it.closePrice).toDouble
			val lower = it.openPrice.min(it.closePrice).toDouble
			val yBody = map.apply(upper)
			val lengthBody = map.apply(lower) - yBody

			drawCandlestick(g, bullish, yWick, lengthWick, yBody, lengthBody)
			markers.filter[it.x == startCandle + index].forEach [ marker |
				g.save()
				g.translate(0, map.apply(closePrice.toDouble))
				marker.renderable.render(g, it)
				g.restore()
			]

			g.translate(WIDTH_TICK, 0)
		]
		g.restore()

		drawYAxis(g, height, minPrice, maxPrice)
	}

	def drawCandlestick(GraphicsContext g, boolean bullish, double yWick, double lengthWick, double yBody, double lengthBody) {
		g.fill = Color.WHITE
		g.fillRect(0, yWick, WIDTH_WICK, lengthWick)
		g.fill = if(bullish) Color.GREEN else Color.RED
		g.fillRect(-Math.floor(WIDTH_CANDLESTICK / 2), yBody, WIDTH_CANDLESTICK, lengthBody)
	}

	def drawLineIndicatorChart(Indicator<?> indicator, List<Marker> markers, GraphicsContext g, double width, double height, int x, double scaleX) {
		drawLineIndicator(indicator, markers, g, width, height - X_AXIS_SIZE - AXIS_OFFSET, x, scaleX)
		g.translate(0, height - X_AXIS_SIZE - AXIS_OFFSET)
		val panelWidth = width - Y_AXIS_SIZE - AXIS_OFFSET

		val widthCandleRendered = WIDTH_TICK * scaleX
		val startCandle = Math.max(0, Math.floor(x / widthCandleRendered)) as int
		val endCandle = Math.max(0, Math.min(indicator.timeSeries.tickCount - 1, startCandle + Math.floor(panelWidth / widthCandleRendered) as int))
		val candles = (startCandle .. endCandle).map[indicator.timeSeries.getTick(it)].toList()
		drawXAxis(width, g, candles)
	}

	def drawLineIndicator(Indicator<?> indicator, List<Marker> markers, GraphicsContext g, double width, double height, int x, double scaleX) {
		val panelWidth = width - Y_AXIS_SIZE - AXIS_OFFSET
		val panelHeight = height - AXIS_OFFSET

		val widthCandleRendered = WIDTH_TICK * scaleX
		val startCandle = Math.max(0, Math.floor(x / widthCandleRendered)) as int
		val endCandle = Math.max(0, Math.min(indicator.timeSeries.tickCount - 1, startCandle + Math.floor(panelWidth / widthCandleRendered) as int))
		val candles = (startCandle .. endCandle).map[(indicator.getValue(it) as Decimal).toDouble].toList()
		val minPrice = candles.min[a, b|a.compareTo(b)]
		val maxPrice = candles.max[a, b|a.compareTo(b)]

		val axis = NumberAxis.fromRange(minPrice, maxPrice, height)
		val map = [
			val valueToAxis = map(it, minPrice, maxPrice, axis.minValue, axis.maxValue)
			val valueOnChart = map(valueToAxis, axis.minValue, axis.maxValue, 0, -panelHeight)
			valueOnChart
		]

		g.save()
		g.translate(Y_AXIS_SIZE + (AXIS_OFFSET / 2), height - (AXIS_OFFSET / 2))
		g.scale(scaleX, 1)

		candles.forEach [ tick, index |
			if(index != 0) {
				val previous = candles.get(index - 1)

				val startHeight = map.apply(previous)
				val endHeight = map.apply(tick)

				g.setStroke(Color.CYAN)
				g.setLineWidth(1)
				g.strokeLine(0, startHeight, WIDTH_TICK, endHeight)
				markers.filter[it.x == startCandle + index].forEach [ marker |
					g.save()
					g.translate(WIDTH_TICK, endHeight)
					marker.renderable.render(g, indicator.timeSeries.getTick(startCandle+index))
					g.restore()
				]
				g.translate(WIDTH_TICK, 0)
			}
		]
		g.restore()

		drawYAxis(g, height, minPrice, maxPrice)
		drawIndicatorName(indicator, g)
	}

	def drawIndicatorName(Indicator<?> indicator, GraphicsContext g) {
		g.fillText(indicator.toString(), Y_AXIS_SIZE + 2, g.font.size + 2)
	}

	def drawYAxis(GraphicsContext g, double height, double minPrice, double maxPrice) {
		g.fill = Color.WHITE
		g.fillRect(Y_AXIS_SIZE - 1, 0, 1, height)

		val axisLength = height - AXIS_OFFSET

		val axis = NumberAxis.fromRange(minPrice, maxPrice, axisLength)
		axis.ticks.forEach [ tick, index |
			val text = new Text(tick)
			g.fillText(tick, 0, axisLength - (axisLength / axis.ticks.size * index) + text.layoutBounds.height / 2, Y_AXIS_SIZE - 12)
			g.fillRect(Y_AXIS_SIZE - 10, axisLength - (axisLength / axis.ticks.size * index), 10, 1)
		]
	}

	def drawXAxis(double width, GraphicsContext g, List<Tick> candles) {
		g.fill = Color.WHITE
		g.fillRect(Y_AXIS_SIZE, -1, width - Y_AXIS_SIZE, 1)

		val from = candles.get(0).endTime
		val to = candles.last.endTime
		val axisWidth = width - Y_AXIS_SIZE - AXIS_OFFSET
		val axis = DateAxis.fromRange(from, to, width - AXIS_OFFSET)
		val size = g.font.size
		g.textAlign = TextAlignment.CENTER
		g.textBaseline = VPos.CENTER
		axis.ticks.forEach [ tick, index |
			val x = (axisWidth / axis.ticks.size * index) + (Y_AXIS_SIZE + AXIS_OFFSET)
			g.fillText(tick, x, size + 12)
			g.fillRect(x, 0, 1, 10)
		]
	}

	def map(double x, double in_min, double in_max, double out_min, double out_max) {
		return out_min + ((out_max - out_min) / (in_max - in_min)) * (x - in_min)
	}

	override getTickSize() {
		return WIDTH_TICK
	}

}
