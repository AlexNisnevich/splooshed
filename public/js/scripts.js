$(document).ready(function() {
	// Change of active highlighting in navbar
	$('.nav li').click(function() {
		$('.active').removeClass('active');
		$(this).addClass('active');
	});

	// Food submission handling
	$('#foodSubmit').click(function() {
		$("#foodWaterDataTable").empty();
		$('#ajaxSpinner').css('display', 'block');
		$.get('/food', $('#foodEntry').serialize(), function(data) {
			$('#ajaxSpinner').hide();
			$("#foodWaterDataTable").append('<tr><th class="input">Input</th><th class="gallons">Gallons of Water</th></tr>');
			if (data.success) {
				var outGallons = Math.round(data.gallons * 100) / 100;
				if (data.gallons = 0) {
					outGallons = "0.0";
				}
				$("#foodWaterDataTable").append("<tr><td>" + data.parsed_input + "</td><td class='gallonCell'>" + outGallons + "</td></tr>");
			} else {
				$("#foodWaterDataTable").append("<tr class='error'><td>" + data.parsed_input + "</td><td class='gallonCell'>" + data.error + "</td></tr>");
			}
		});
	});

	$('#recipeSubmit').click(function() {
		$("#foodWaterDataTable").empty();
		$('#ajaxSpinner').css('display', 'block');
		$.post('/recipe', $('#inputRecipe').val(), function(data) {
			$('#ajaxSpinner').hide();
			outputData(data);
		});
	});

	$("#inputFood").autocomplete({
		source: '/list_foods',
		minLength: 2
	});

	var topOfHome = $("#home").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() > topOfHome) {
			$('.active').removeClass('active');
			$("#homeButton").addClass('active');
		}
	});

	var topOfAbout = $("#about").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() > topOfAbout) {
			$('.active').removeClass('active');
			$("#aboutButton").addClass('active');
		}
	});

	var topOfEntry = $("#entry").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() > topOfEntry) {
			$('.active').removeClass('active');
			$("#entryButton").addClass('active');
		}
	});

	var topOfStatistics = $("#statistics").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() > topOfStatistics) {
			$('.active').removeClass('active');
			$("#statisticsButton").addClass('active');
		}
	});


	var outputData = function(data) {
		var total = 0;
		$("#foodWaterDataTable").append('<tr><th class="input">Input</th><th class="gallons">Gallons of Water</th></tr>');
		for (var i = 0; i < data.length; i++) {
			if (data[i].success) {
				var outGallons = Math.round(data[i].gallons * 100) / 100;
				total = total + outGallons;
				if (data[i].gallons = 0) {
					outGallons = "0.0";
				}
				$("#foodWaterDataTable").append("<tr><td>" + data[i].parsed_input + "</td><td class='gallonCell'>" + outGallons + "</td></tr>");
			} else {
				$("#foodWaterDataTable").append("<tr class='error'><td>" + data[i].parsed_input + "</td><td class='gallonCell'>Unknown <a title='" + data[i].error + "'>[?]</a></td></tr>");
			}
		}
		$("#foodWaterDataTable").append('<tr><td class="transparentCell">Total:</td><td class="totalCell">' + total + '</td></tr>');
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