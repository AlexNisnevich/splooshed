var splooshed = "http://splooshed.herokuapp.com";

var total = 0;

$.fn.exists = function () {
    return this.length !== 0;
}

$('.ingredients h2').css('float', 'left');
$('.ingredients h2').wrap($('<div class="clearfix"></div>'));
$('.ingredients h2').after($('<h2 style="color: #88A2B9; float: right">Water Usage: <span id="totalWaterUsage">0 gallons</span></h2>'));

$('.ingredient').map(function (i, x) { 
  if ($(x).find('strong').exists()) {
    return;
  }
  var recipeText = $(x).text();
  $.post(splooshed + "/recipe_line", recipeText, function (data) {
    console.log(data);
    if (data.success) {
      var roundedGallons = Math.round(data.gallons * 100) / 100;

      if (roundedGallons > 500) {
        var num = 8;
      } else {
        var num = Math.ceil(roundedGallons / 500 * 8);
      }

      var img = $("<img class='waterIcon' src='" + splooshed + "/images/droplet" + num + ".png' title='Water usage: " + roundedGallons + " gallons'>");

      total = Math.round((total + roundedGallons) * 100) / 100 ;
      $('#totalWaterUsage').text(total + " gallons")
    } else {
      var img = $("<img class='waterIcon' src='" + splooshed + "/images/droplet0.png' title='" + data.error + "'>");
    }
    $(x).append(img);
  }); 
});

function addStyleString(str) {
    var node = document.createElement('style');
    node.innerHTML = str;
    document.body.appendChild(node);
}

addStyleString('.ingredients-section li { position: relative; }');
addStyleString('.clearfix:after { content: ""; display: table; clear: both;; }');
addStyleString('.waterIcon { position: absolute; left: -26px; top: 2px; }');