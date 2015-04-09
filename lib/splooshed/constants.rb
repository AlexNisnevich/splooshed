USDA_API_KEY = "nkmsGMj3ChXLsbIBy22EwbORKK1BloEzmXFo5UdT"

WEIGHTS_TO_KG = {
  :gram => 0.001,
  :kilogram => 1.0,
  :milligram => 0.000001,
  :ounce => 0.028349,
  :pound => 0.453592
}

VOLUME_CONVERSIONS = {
  "dash->pinch" => 1.0,
  "cup->fl oz" => 8.0,
  "cup->tbsp" => 16.0,
  "cup->tsp" => 48.0,
  "fl oz->tbsp" => 2.0,
  "fl oz->tsp" => 6.0,
  "tbsp->tsp" => 3.0,
  "servings->medium" => 1.0,
  "servings->med" => 1.0,
  "medium->fruit" => 1.0,
  "medium->clove" => 1.0,
  "large->pepper" => 1.0,
  "small->pepper" => 0.7,
  "large->cup chopped" => 1.0,
  "quart->cup" => 4.0
}

IGNORED_FOOD_GROUPS = [
  "Baked Products",
  "Baby Foods",
  "Snacks",
  "Fast Foods"
]

DUMMY_WORDS = [
  "about", "and",  # connecting words
  "freshly", "finely",  # adverbs
  "minced", "peeled", "cut", "chopped", "packed", "shaved", "squeezed", "shredded", "sliced", "toasted", "roasted", "unpacked", # verbal adjectives
  "fresh", "boneless", "skinless", "lowfat", "low-fat", "low-sodium",  # misc adjectives
  "Italian", "kosher",  # cultural adjectives
  "leaves", "tops", "bottoms"  # parts of food
]

GALLONS_OF_WATER_FOR_UNITLESS_ITEMS = {
  "cigarette" => 0.352,
  "cigarettes" => 0.352
}

HARDCODED_NDBNOS = {
  "rice" => "20054",
  "canola oil" => "04582",
  "vegetable oil" => "04582",
  "corn starch" => "20027",
  "chinese rice vinegar" => "02068"
}