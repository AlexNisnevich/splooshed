USDA_API_KEY = "nkmsGMj3ChXLsbIBy22EwbORKK1BloEzmXFo5UdT"

WEIGHTS_TO_KG = {
  :gram => 0.001,
  :kilogram => 1.0,
  :milligram => 0.000001,
  :ounce => 0.028349,
  :pound => 0.453592
}

VOLUME_TO_CANONICAL_VOLUME = {
  :tablespoon => "tbsp",
  :teaspoon => "tsp"
}

VOLUME_CONVERSIONS = {
  "dash->pinch" => 1.0,
  "cup->tablespoon" => 16.0,
  "cup->tbsp" => 16.0,
  "cup->teaspoon" => 48.0,
  "cup->tsp" => 48.0,
  "tablespoon->teaspoon" => 3.0,
  "tbsp->tsp" => 3.0,
  "tbsp->tsp unpacked" => 3.0,
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
  "about", "and", "fresh", "minced", "peeled", "cut", "chopped", "packed", "shaved", "freshly",
  "squeezed", "Italian", "leaves", "finely", "boneless", "shredded", "sliced", "toasted", "kosher"
]

GALLONS_OF_WATER_FOR_UNITLESS_ITEMS = {
  "cigarette" => 0.352,
  "cigarettes" => 0.352
}

HARDCODED_NDBNOS = {
  "rice" => "20054",
  "canola oil" => "04582",
  "vegetable oil" => "04582",
  "corn starch" => "20027"
}