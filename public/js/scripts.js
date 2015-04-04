$(document).ready(function() {
	// Change of active highlighting in navbar
	$('.nav li').click(function() {
		$('.active').removeClass('active');
		$(this).addClass('active');
	});

	// Food submission handling
	$('#foodSubmit').click(function() {
		$('.foodEntryResult').text($('#foodEntry').serialize());
		$.get('/food', $('#foodEntry').serialize(), function(data) {
			outputData(data);
		});
	});

	$('#recipeSubmit').click(function() {
		$('.foodEntryResult').text($('#inputRecipe').val().replace("\n","\\n"));
		$.post('/recipe', $('#inputRecipe').val().replace("\n","\\n"), function(data) {
			outputData(data);
		});
	});

	var outputData = function(data) {
		JSONdata = JSON.parse(data);
		for (var i = 0; i < JSONdata.length; i++) {
			if (JSONdata[i].success) {
				$("#foodWaterDataTable").append("<tr><td>" + JSONdata[i].input + "</td><td>" + JSONdata[i].gallons + "</td></tr>");
			}
		}
	}

	var worstFoodsOptions = { 
		scaleFontColor: "#EEE", 
		scaleGridLineColor: "#AAA",
		graphTitle: "Worst Foods by Water Requirements",
		graphTitleFontFamily : "'Roboto'",
		graphTitleFontSize : 18,
		graphTitleFontStyle : "bold",
		graphTitleFontColor : "#EEE",
		yAxisLabel : "Gallons of Water per Kilogram of Food",
		yAxisFontFamily : "'Roboto'",
		yAxisFontSize : 16,
		yAxisFontStyle : "normal",
		yAxisFontColor : "#EEE",
		xAxisLabel : "Food/Ingredient",
		xAxisFontFamily : "'Roboto'",
		xAxisFontSize : 16,
		xAxisFontStyle : "normal",
		xAxisFontColor : "#EEE"
	};
	var worstFoodsctx = $("#worstFoods").get(0).getContext("2d");
	var worstFoodsData = {
		labels: ["Vanilla Beans", "Cloves", "Nutmeg", "Sesame Oil", "Cocoa Beans", "Roasted Coffee", "Chocolate", "Almonds", "Cinnamon", "Cashew Nuts"],
		datasets: [
			{
				label: "Worst Foods by Water Requirements",
				fillColor: "rgba(220,220,220,0.5)",
				strokeColor: "rgba(220,220,220,0.8)",
				highlightFill: "rgba(220,220,220,0.75)",
				highlightStroke: "rgba(220,220,220,1)",
				data: [36838.24273, 17822.88958, 9993.689201, 6346.119314, 5803.03151, 5510.958015, 5007.473397, 4686.862312, 4521.169572, 4140.280109]
			}
		]
	};
	var worstFoodsChart = new Chart(worstFoodsctx).Bar(worstFoodsData, worstFoodsOptions);


	var bestFoodsOptions = { 
		scaleFontColor: "#EEE", 
		scaleGridLineColor: "#AAA",
		graphTitle: "Best Foods by Water Requirements",
		graphTitleFontFamily : "'Roboto'",
		graphTitleFontSize : 18,
		graphTitleFontStyle : "bold",
		graphTitleFontColor : "#EEE",
		yAxisLabel : "Gallons of Water per Kilogram of Food",
		yAxisFontFamily : "'Roboto'",
		yAxisFontSize : 16,
		yAxisFontStyle : "normal",
		yAxisFontColor : "#EEE",
		xAxisLabel : "Food/Ingredient",
		xAxisFontFamily : "'Roboto'",
		xAxisFontSize : 16,
		xAxisFontStyle : "normal",
		xAxisFontColor : "#EEE"
	};
	var bestFoodsctx = $("#bestFoods").get(0).getContext("2d");
	var bestFoodsData = {
		labels: ["Sugar Beet", "Carrots and Turnips", "Sugar Cane", "Tomatoes", "Watermelon", "Lettuce", "Pineapples", "Onions", "Cranberries", "Cabbage"],
		datasets: [
			{
				label: "Best Foods by Water Requirements",
				fillColor: "rgba(220,220,220,0.5)",
				strokeColor: "rgba(220,220,220,0.8)",
				highlightFill: "rgba(220,220,220,0.75)",
				highlightStroke: "rgba(220,220,220,1)",
				data: [38.43838616, 56.78397955, 61.15197798, 62.31677756, 68.43197535, 69.01437514, 74.25597326, 79.20637147, 80.37117105, 81.53597063]
			}
		]
	};
	var bestFoodsChart = new Chart(bestFoodsctx).Bar(bestFoodsData, bestFoodsOptions);
});