var options = {
	series: {
    	bars: {
    		horizontal: true,
    		show: true,
    		barWidth: 0.9,
    		align: 'center'
    	}
	},
	legend: {
		show: false
	},
	grid: {
		borderWidth: 0
	},
	xaxis: {
		tickLength: 0,
		minTickSize: 1,
		tickDecimals: 0,
		min: 0
	},
	yaxis: {
		tickLength: 0,
		ticks: [
			[1,'Not at all'],
			[2,'A little'],
			[3,'Moderately'],
			[4,'Quite a bit'],
            [5,'Extremely']
		]
	}
};