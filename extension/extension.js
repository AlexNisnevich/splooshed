var splooshed = "http://splooshed.herokuapp.com";

var total = 0;

$('.info_bar_item.second_slot').after($('<div class="info_bar_item second_slot" style="margin-left: 30px; background: rgb(0, 146, 194); width: 334px;">Water Usage: <span id="totalWaterUsage" class="proxima-bold">0 gallons</span></div>'));

$('[itemtype="http://schema.org/RecipeIngredient"]').map(function (i, x) { 
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

addStyleString('.waterIcon { position: absolute; left: 7px }');
addStyleString('.sidebar_scroll_locked .waterIcon, .sidebar_scroll_bottomed .waterIcon { left: -21px }');