var wordsK = ["soybean", "soy bean", "korean", "fish sauce", "kimchi", "bulgogi"]; // KOREAN WORDS THAT PLAY SONGS

$(document).ready(function() {
	// Change of active highlighting in navbar
//	$('.nav li').click(function() {
//		$('.active').removeClass('active');
//		$(this).addClass('active');
//	});

	// Food submission handling
	$('#foodSubmit').click(function() {
		$("#foodWaterDataTable").empty();
		$('#ajaxSpinner').css('display', 'block');
		$.get('/food', $('#foodEntry').serialize(), function(data) {
			$('#ajaxSpinner').hide();
			$("#foodWaterDataTable").append('<tr><th class="input">Input</th><th class="gallons">Gallons of Water</th></tr>');
			if (data.success) {
				var outGallons = Math.round(data.gallons * 100) / 100;
				if (data.gallons == 0) {
					outGallons = "0.0";
				}
				$("#foodWaterDataTable").append("<tr><td>" + data.parsed_input + "</td><td class='gallonCell'>" + outGallons + "</td></tr>");
			} else {
				$("#foodWaterDataTable").append("<tr class='error'><td>" + data.parsed_input + "</td><td class='gallonCell'>" + data.error + "</td></tr>");
			}
		});

		for (var i in wordsK) {
			if ($('#inputFood').val().indexOf(wordsK[i]) > -1) {
				playK();	
				document.body.style.backgroundImage = "url('http://www.paulnoll.com/Korea/History/South-Korean-flag.jpg')";
			}
		}
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
		if( $(window).scrollTop() + 10 > topOfHome) {
			$('.active').removeClass('active');
			$("#homeButton").addClass('active');
		}
	});

	var topOfAbout = $("#about").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() + 10 > topOfAbout) {
			$('.active').removeClass('active');
			$("#aboutButton").addClass('active');
		}
	});

	var topOfEntry = $("#entry").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() + 10 > topOfEntry) {
			$('.active').removeClass('active');
			$("#entryButton").addClass('active');
		}
	});

	var topOfChrome = $("#chromeExtension").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() + 10 > topOfChrome) {
			$('.active').removeClass('active');
			$("#chromeButton").addClass('active');
		}
	});

	var topOfAPI = $("#api").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() + 10 > topOfAPI) {
			$('.active').removeClass('active');
			$("#apiButton").addClass('active');
		}
	});

	var topOfStatistics = $("#statistics").offset().top;
	$(window).scroll(function() {
		if( $(window).scrollTop() + 10 > topOfStatistics) {
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
				if (data[i].gallons == 0) {
					outGallons = "0.0";
				}

				if (data[i].gallons > 500) {
	        var imgNum = 8;
	      } else {
	        var imgNum = Math.ceil((data[i].gallons + 1) / 500 * 8);
	      }

				$("#foodWaterDataTable").append("<tr><td>" + data[i].parsed_input + "</td><td class='gallonCell'>" + outGallons + " <img class='waterIcon' src='/images/droplet" + imgNum + ".png' title='Water impact: " + outGallons + " gallons'</td></tr>");
			} else {
				$("#foodWaterDataTable").append("<tr class='error'><td>" + data[i].parsed_input + "</td><td class='gallonCell'>Unknown <img title='" + data[i].error + "' class='waterIcon' src='/images/droplet0.png'></img></td></tr>");
			}
		}
		$("#foodWaterDataTable").append('<tr><td class="transparentCell">Total:</td><td class="totalCell">' + (Math.round(total * 100) / 100) + '</td></tr>');
	}

	var worstFoodsOptions = { 
		rotateLabels: 45,
		scaleFontColor: "#EEE", 
		scaleFontSize: 16,
		scaleGridLineColor: "#AAA",
		graphTitle: "Least Water-Efficient Foods",
		graphTitleFontFamily : "'Roboto'",
		graphTitleFontSize : 18,
		graphTitleFontStyle : "bold",
		graphTitleFontColor : "#EEE",
		yAxisLabel : "Gallons of Water per Lb of Food",
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
		labels: ["Sesame Oil", "Roasted Coffee", "Chocolate", "Almonds", "Cashews", "Beef", "Pistachios", "Hazelnuts", "Sesame Seeds", "Walnuts"],
		datasets: [
			{
				label: "Least Water-Efficient Foods",
				fillColor: "rgba(220,220,220,0.5)",
				strokeColor: "rgba(220,220,220,0.8)",
				highlightFill: "rgba(220,220,220,0.75)",
				highlightStroke: "rgba(220,220,220,1)",
				data: [2884.599688181818, 2504.980915909091, 2276.124271363636, 2130.39196, 1881.945504090909, 1850.8787, 1504.047458181818, 1391.8031349999999, 1240.3791895454544, 1217.26803018	]
			}
		]
	};
	var worstFoodsChart = new Chart(worstFoodsctx).Bar(worstFoodsData, worstFoodsOptions);


	var bestFoodsOptions = { 
		rotateLabels: 45,
		scaleFontColor: "#EEE", 
		scaleFontSize: 16,
		scaleGridLineColor: "#AAA",
		graphTitle: "Most Water-Efficient Foods",
		graphTitleFontFamily : "'Roboto'",
		graphTitleFontSize : 18,
		graphTitleFontStyle : "bold",
		graphTitleFontColor : "#EEE",
		yAxisLabel : "Gallons of Water per Lb of Food",
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
		labels: ["Carrots & Turnips", "Tomatoes", "Watermelon", "Lettuce", "Pineapples", "Tomato Juice", "Onions", "Cranberries", "Cabbage", "Cauliflower & Broccoli"],
		datasets: [
			{
				label: "Most Water-Efficient Foods",
				fillColor: "rgba(220,220,220,0.5)",
				strokeColor: "rgba(220,220,220,0.8)",
				highlightFill: "rgba(220,220,220,0.75)",
				highlightStroke: "rgba(220,220,220,1)",
				data: [25.810899795454542, 28.32580798181818, 31.10544334090909, 31.370170518181816, 33.75271511818182, 35.341078181818176, 36.002896122727265, 36.53235047727272, 37.06180483181818, 37.72362277727272]
			}
		]
	};
	var bestFoodsChart = new Chart(bestFoodsctx).Bar(bestFoodsData, bestFoodsOptions);
});



var loadK = function()
{

	k1 = new Howl({
		urls: ['../songs/kpop1.mp3', '../songs/kpop1.mp3'],
		volume: 0.5
	
	});

}
