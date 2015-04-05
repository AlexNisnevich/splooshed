var splooshed = "http://splooshed.herokuapp.com";

var total = 0;

$('.summary_data span:last').after('<br><br><div style="color: #88A2B9">WATER USAGE: <span id="totalWaterUsage">0 gallons</span></div>');

$('.ingredient').map(function (i, x) { 
  var recipeText = $(x).text();
  $.post(splooshed + "/recipe_line", recipeText, function (data) {
    console.log(data);
    if (data.success) {
      var roundedGallons = Math.round(data.gallons * 100) / 100;

      if (roundedGallons > 500) {
        var num = 8;
      } else {
        var num = Math.ceil((roundedGallons + 1) / 500 * 8);
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

addStyleString('.waterIcon { position: absolute; left: -26px; top: 5px; }');