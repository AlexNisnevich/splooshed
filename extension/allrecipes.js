var splooshed = "http://splooshed.herokuapp.com";

var total = 0;

$('h3:first').before($('<h3 style="color: #88A2B9">Water Usage: <span id="totalWaterUsage">0 gallons</span></h3>'));

$('[itemprop="ingredients"]').map(function (i, x) {
  var recipeText = $(x).find('.ingredient-amount').text() + " " + $(x).find('.ingredient-name').text();
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

addStyleString('.waterIcon { position: absolute; right: 10px }');
addStyleString('#liIngredient { position: relative; }')
addStyleString('.rec-detail-wrapper ul.ingredient-wrap { width: 250px; }')
addStyleString('.rec-detail-wrapper ul.ingredient-wrap li { width: 250px; }')