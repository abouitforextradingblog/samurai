package com.sirolf2009.samurai.dataprovider

import com.sirolf2009.samurai.annotations.Register
import eu.verdelhan.ta4j.TimeSeries
import java.io.File
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Date
import java.util.LinkedList
import java.util.Scanner

class DataProviderBitcoinCharts extends DataProvider {

	val String name
	val File file

	var progress = 0

	new(String file) {
		file = new File(class.getResource(file).toURI)
		name = file
	}

	new(File file) {
		this.file = file
		this.name = "bitcoincharts.com-" + file.name
	}

	override protected call() throws Exception {
		val ticks = buildEmptyTicks(from, to, period)
		val ticksQueue = new LinkedList(ticks)
		val scanner = new Scanner(file)
		val size = file.length

		updateMessage("Loading data")
		while(scanner.hasNextLine() && !isCancelled) {
			val line = scanner.nextLine()
			val data = line.split(",")
			val time = ZonedDateTime.ofInstant(new Date(Long.parseLong(data.get(0))*1000).toInstant(), ZoneId.systemDefault())

			while(ticksQueue.size > 0 && !ticksQueue.peek.inPeriod(time)) {
				ticksQueue.poll
			}
			if(ticksQueue.size > 0) {
				ticksQueue.peek => [
					val price = Double.parseDouble(data.get(1))
					val amount = Double.parseDouble(data.get(2))
					addTrade(amount, price)
					updateMessage("Loading " + time.getYear + "-" + time.monthValue + "-" + time.getDayOfMonth)
				]
			}
			progress += line.bytes.length
			updateProgress(progress, size)
		}
		removeEmptyTicks(ticks)

		return new TimeSeries(name, ticks)
	}

	@Register(name="Bitstamp USD", type="Built-In")
	public static class DataproviderBitstampUSD extends DataProviderBitcoinCharts {
		new() {
			super(new File("data/bitstampUSD.csv"))
		}
	}
	
	@Register(name="Bitfinex USD", type="Built-In")
	public static class DataproviderBitfinexUSD extends DataProviderBitcoinCharts {
		new() {
			super(new File("data/bitfinexUSD.csv"))
		}
	}

}
