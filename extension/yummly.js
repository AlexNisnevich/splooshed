var splooshed = "http://splooshed.herokuapp.com";

var total = 0;

$('.recipe-data').append('<li><span class="hd">Water Usage</span><span class="bd" id="totalWaterUsage" style="color: rgb(0, 146, 194);">0</span><span class="ft">Gallons</span></li>');

$("[itemprop=ingredients]").map(function (i, x) { 
  var recipeText = $(x).find(".amount").text() + " " + $(x).find(".name").text();
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

      total = Math.round(total + roundedGallons);
      $('#totalWaterUsage').text(total)
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

addStyleString('.recipe-data { width: 640px !important }');
addStyleString('.recipe-data li { width: 25% !important }');
addStyleString('.waterIcon { position: absolute; left: -1px; top: 15px; }');