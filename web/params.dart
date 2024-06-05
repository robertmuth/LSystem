import 'dart:html';
import 'dart:math' as Math;
import 'package:lsystem/option.dart';
import 'package:lsystem/logging.dart' as log;

Options gOptions = Options("lsystem");

void OptionsSetup() {
  gOptions
    ..AddOption("pattern", "O", "entaplexity")
    ..AddOption("lineColor", "S", "white")
    ..AddOption("backgroundColor", "S", "black")
    ..AddOption("rotate", "B", "false", true)
    ..AddOption("oscillateSize", "B", "false", true)
    ..AddOption("oscillateAngle", "B", "false", true)
    ..AddOption("randomSeed", "I", "0")
    //..AddOption("minAngle", "D", "88.0")
    //..AddOption("maxAngle", "D", "92.")
    ..AddOption("lineWidth", "D", "0.2")
    ..AddOption("logLevel", "I", "0", true);

  gOptions.AddSetting("Standard", {});

  gOptions.ProcessUrlHash();

  SelectElement presets = querySelector("#preset") as SelectElement;
  for (String name in gOptions.SettingsNames()) {
    OptionElement o = new OptionElement(data: name, value: name);
    presets.append(o);
  }

  log.gLogLevel = gOptions.GetInt("logLevel");
}

// Raw colormap extracted from pollockEFF.gif
List<String> pPollock = [
  "#201F20",
  "#262C2F",
  "#352625",
  "#372B28",
  "#302C2D",
  "#392B2E",
  "#323228",
  "#3F322A",
  "#38322E",
  "#2E333D",
  "#333A3D",
  "#473329",
  "#40392C",
  "#40392E",
  "#47402C",
  "#47402E",
  "#4E402C",
  "#4F402E",
  "#4E4738",
  "#584037",
  "#65472D",
  "#6D5D3D",
  "#745530",
  "#755532",
  "#745D32",
  "#746433",
  "#7C6C36",
  "#523152",
  "#444842",
  "#4C5647",
  "#655D45",
  "#6D5D44",
  "#6C5D4D",
  "#746C44",
  "#7C6C42",
  "#7C6C4B",
  "#6B734B",
  "#73734B",
  "#7B7B4A",
  "#6B6C55",
  "#696D5E",
  "#7B6C5D",
  "#6B7353",
  "#6A745D",
  "#727B52",
  "#7B7B52",
  "#57746E",
  "#687466",
  "#9C542B",
  "#9D5432",
  "#9D5B35",
  "#936B36",
  "#AA7330",
  "#C45A28",
  "#D95222",
  "#D85A20",
  "#DB5A23",
  "#E57036",
  "#836C4C",
  "#8C6B4B",
  "#82735D",
  "#937353",
  "#817B62",
  "#817B6D",
  "#927B62",
  "#D9893B",
  "#E49833",
  "#DFA133",
  "#E5A037",
  "#F0AB3B",
  "#8A8A59",
  "#B29A58",
  "#89826B",
  "#9A8262",
  "#888B7C",
  "#909A7A",
  "#A28262",
  "#A18A69",
  "#A99967",
  "#99A160",
  "#99A168",
  "#CA8148",
  "#EB8D43",
  "#C29160",
  "#C29168",
  "#D1A977",
  "#C9B97F",
  "#F0E27B",
  "#9F928C",
  "#C0B999",
  "#E6B88E",
  "#C8C187",
  "#E0C885",
  "#F2CC85",
  "#F5DA82",
  "#ECDE9D",
  "#F5D294",
  "#F5DA94",
  "#F4E784",
  "#F4E18A",
  "#F4E193",
  "#E7D8A6",
  "#F1D4A4",
  "#F1DCA5",
  "#F4DBAD",
  "#F1DCAE",
  "#F4DBB5",
  "#F5DBBD",
  "#F4E2AD",
  "#F5E9AD",
  "#F4E3BE",
  "#F5EABE",
  "#F7F0B6",
  "#D9D1C1",
  "#E0D0C0",
  "#E7D8C0",
  "#F1DDC5",
  "#E8E1C0",
  "#F3EDC7",
  "#F6ECCE",
  "#F8F2C6",
  "#EFEFD1",
];

List<String> pMondrian = [
  "#FFFEE6",
  "#FFFF00",
  "#FF2600",
  "#0101A3",
  "#1F1A18",
];

Map<String, List<String>> AllPalettes = {
  "Pollock": pPollock,
  "Mondrian": pMondrian,
};

String GetRandomColor(Math.Random rng, List<String> palette) {
  return palette[rng.nextInt(palette.length)];
}
