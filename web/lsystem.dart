import 'dart:math' as Math;
import 'dart:html' as HTML;
import 'dart:core';

import 'params.dart';

import 'package:lsystem/lsys2d_examples.dart' as lsys2d_examples;
import 'package:lsystem/lsys2d.dart' as lsys2d;
import 'package:lsystem/rule.dart' as rule;
import 'package:lsystem/logging.dart' as log;
import 'package:lsystem/option.dart';
import 'package:lsystem/webutil.dart';

import 'package:vector_math/vector_math.dart' as VM;

import 'package:chronosgl/chronosgl.dart';

final HTML.Element gFps = HTML.querySelector("#fps") as HTML.Element;
final HTML.CanvasElement gCanvas = HTML.querySelector("#area") as HTML.CanvasElement;
final HTML.SelectElement gPattern = HTML.querySelector("#pattern") as HTML.SelectElement;

num GetRandom(Math.Random rng, num a, num b) {
  return rng.nextDouble() * (b - a) + a;
}

class ModelExtractor extends rule.Plotter {
  //VM.Vector3 _last = VM.Vector3.zero();

  //final Material _mat1 = Material("mat1")..SetUniform(uColor, ColorBlue);
  final Material _mat2 = Material("mat2")..SetUniform(uColor, ColorRed);
  //final Material _mat3 = Material("mat3")..SetUniform(uColor, ColorGreen);
  final Material _mat4 = Material("mat4")..SetUniform(uColor, ColorCyan);
  final Material _mat5 = Material("plane")..SetUniform(uColor, ColorGray8);
  GeometryBuilder _gb = GeometryBuilder();
  List<VM.Vector3> _polygon = [];

  ModelExtractor();
  @override
  void Init(rule.State s) {}

  @override
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, rule.State s) {
    double len = (dst - src).length;
    VM.Vector3 offset = VM.Vector3.zero();
    VM.Vector3.mix(src, dst, 0.5, offset);
    print("add cylinder: ${rule.str(src)} -> ${rule.str(dst)}  dir: ${rule.str(dst - src)}");
    GeometryBuilder cylinder = CylinderGeometry(1.0, 1.0, len, 10, true);

    _gb.MergeAndTakeOwnership2(cylinder, dir, offset);
    //
    VM.Quaternion no_rot = VM.Quaternion.identity();
    GeometryBuilder cube = CubeGeometry(x: 2.0, y: 2.0, z: 2.0);
    _gb.MergeAndTakeOwnership2(cube, no_rot, dst);
    //
    GeometryBuilder cube2 = CubeGeometry(x: 1.5, y: 1.5, z: 1.5);
    _gb.MergeAndTakeOwnership2(cube2, no_rot, offset);
  }

  @override
  void Fini(rule.State s) {
    //
  }

  @override
  void PolyStart(rule.State s) {
    _polygon.clear();
  }

  @override
  void PolyEnd(rule.State s) {
    assert(_polygon.length >= 3);
    int offset = _gb.AddVerticesTakeOwnership(_polygon);
    for (int i = 1; i < _polygon.length - 1; ++i) {
      _gb.AddFace3(offset + 0, offset + i, offset + i + 1);
    }
  }

  @override
  void PolyPoint(VM.Vector3 dst, rule.State s) {
    _polygon.add(dst);
  }

  void UpdateScene(Scene scene, RenderProgram prog) {
    var start = DateTime.now();
    scene.removeAll();
    scene.add(
        Node("cube", ShapeCube(prog, x: 20.0, y: 0.1, z: 20.0), _mat5)..setPos(0.0, -10.0, 0.0));
    scene.add(Node("tree", GeometryBuilderToMeshData("tree", prog, _gb), _mat2));
    var stop = DateTime.now();
    print("3d mesh creation took ${stop.difference(start)}");
  }
}

/**

 * This class maintains a list of planetary bodies, knows how to draw its
 * background and the planets, and requests that it be redraw at appropriate
 * intervals using the [Window.requestAnimationFrame] method.
 */
class LSystem {
  ModelExtractor _plotter;

  Map<String, List<rule.Rule>> _rules = {};
  List<rule.SymIndex> _pattern_prefix = [];
  List<rule.SymIndex> _pattern = [];
  String _name = "";
  rule.PatternInfo _info = rule.PatternInfo([]);
  Math.Random _rng;
  final Options _options;

  LSystem(this._options, Math.Random rng)
      : _rng = rng,
        _plotter = ModelExtractor() {}

  void Init(Map<String, String> desc) {
    _name = desc["name"]!;
    List<String> rule_strs = desc["r"]!.split(";");

    _rules = lsys2d.ParseRules(rule_strs);
    print("Lsystem: ${_name}");
    for (var rs in _rules.values) {
      for (var r in rs) {
        print(r);
      }
    }
    _pattern = lsys2d.ExtractAxiom(rule_strs);
    int iterations = int.parse(desc["i"]!);
    for (int i = 0; i < iterations; ++i) {
      _pattern = rule.ExpandOneStep(_pattern, _rules, _rng);
    }

    _info = rule.PatternInfo(_pattern);

    //

    _pattern_prefix.addAll(
        lsys2d.InitPrefix(desc, VM.Vector3(0.0, 0.0, 0.0), VM.Quaternion.euler(0.0, 0.0, 0.0)));

    /*
    _pattern_prefix.add(rule.Sym.SetParam(rule.pWidth, _options.GetDouble("lineWidth")));
    _pattern_prefix.add(rule.Sym.SetParam(rule.pLineColor, _options.Get("lineColor")));
    _pattern_prefix.add(rule.Sym.SetParam(rule.pBackgroundColor, _options.Get("backgroundColor")));
   */
    //

    print(rule.StringifySymIndexList(_pattern_prefix));
    // print(_pattern);
  }

  String Info() {
    return "[${_name}] ${_info}";
  }

  void draw(double t, Scene scene, RenderProgram prog) {
    List<rule.SymIndex> time_based = [];
/*
    if (gOptions.GetBool("rotate")) {
      time_based.add(rule.Sym.Param(rule.Kind.YAW_ADD_CONST, rule.pDir, t / 100 * 360));
    }
    if (gOptions.GetBool("oscillateSize")) {
      time_based
          .add(rule.Sym.Param(rule.Kind.MUL, rule.pStepSize, 0.5 * (1.0 + Math.sin(t * 0.01))));
    }
    if (gOptions.GetBool("oscillateAngle")) {
      time_based.add(rule.Sym.Param(rule.Kind.YAW_ADD_CONST, rule.pDir, t * 0.001));
    }
    */

    rule.RenderAll(_pattern_prefix + time_based, _pattern, _plotter);
    _plotter.UpdateScene(scene, prog);
  }
}

int gNumExample = 0;
LSystem? gActiveLSystem = null;

void HandleCommand(String cmd, String param) {
  var examples = lsys2d_examples.kExamples;
  log.LogInfo("HandleCommand: ${cmd} ${param}");
  switch (cmd) {
    case "A":
      Toggle(HTML.querySelector(".about")!);
      break;
    case "C":
      Toggle(HTML.querySelector(".config")!);
      break;
    case "P":
      Toggle(HTML.querySelector(".performance")!);
      break;
    case "R":
      gActiveLSystem = null;
      break;
    case "1":
      print("prev");
      gPattern.selectedIndex = (gNumExample - 1) % examples.length;
      gActiveLSystem = null;
      break;
    case "2":
      print("next");
      gPattern.selectedIndex = (gNumExample + 1) % examples.length;
      gActiveLSystem = null;
      break;
    case "A+":
      Show(HTML.querySelector(".about")!);
      break;
    case "A-":
      Hide(HTML.querySelector(".about")!);
      break;
    case "F":
      ToggleFullscreen();
      break;
    case "C-":
      Hide(HTML.querySelector(".config")!);
      break;
    case "C+":
      Show(HTML.querySelector(".config")!);
      break;
    case "X":
      String preset = (HTML.querySelector("#preset") as HTML.SelectElement).value!;
      gOptions.SetNewSettings(preset);

      gActiveLSystem = null;
      break;
  }
}

void animateLSystem(double t, Scene scene, RenderProgram prog) {
  int active = gPattern.selectedIndex!;

  if (gActiveLSystem == null || active != gNumExample) {
    print("index ${active} vs $gNumExample}");
    gNumExample = active;

    int seed = gOptions.GetInt("randomSeed");
    if (seed == 0) {
      seed = new DateTime.now().millisecondsSinceEpoch;
    }

    var examples = lsys2d_examples.kExamples;
    gOptions.SaveToLocalStorage();
    gActiveLSystem = LSystem(gOptions, Math.Random(seed));
    gActiveLSystem!.Init(examples[gNumExample % examples.length]);
    gActiveLSystem!.draw(t, scene, prog);
  }
}

void main() {
  OptionsSetup();
  HTML.SelectElement patterns = HTML.querySelector("#pattern") as HTML.SelectElement;
  int count = 0;
  for (var desc in lsys2d_examples.kExamples) {
    HTML.OptionElement o = new HTML.OptionElement(data: desc["name"]!, value: "${count}");
    patterns.append(o);
    ++count;
  }

  final int w = HTML.document.body!.clientWidth;
  final int h = HTML.document.body!.clientHeight;
  final int w2 = HTML.window.innerWidth!;
  final int h2 = HTML.window.innerHeight!;
/*
  for (var example in lsys2d_examples.kExamples) {
    print(example["name"]!);
    // just confirm we can parse it
    lsys2d.ParseRules(example["r"]!);
  }
  log.LogInfo("main: ${w}x${h} ${w2}x${h2}");
*/
  HTML.document.body!.onKeyDown.listen((HTML.KeyboardEvent e) {
    log.LogInfo("key pressed ${e.keyCode} ${e.target.runtimeType}");
    if (e.target.runtimeType == HTML.InputElement) {
      return;
    }

    String cmd = new String.fromCharCodes([e.keyCode]);
    HandleCommand(cmd, "");
  });

  HTML.document.body!.onClick.listen((HTML.MouseEvent ev) {
    if (ev.target.runtimeType != HTML.CanvasElement) return;
    log.LogInfo("click ${ev.target.runtimeType}");
    HandleCommand("C", "");
  });

  HTML.ElementList<HTML.Element> buttons = HTML.document.body!.querySelectorAll("button");
  log.LogInfo("found ${buttons.length} buttons");
  buttons.onClick.listen((HTML.Event ev) {
    String cmd = (ev.target as HTML.Element).dataset['cmd']!;
    String param = (ev.target as HTML.Element).dataset['param']!;
    HandleCommand(cmd, param);
  });

  ChronosGL cgl = ChronosGL(gCanvas);

  OrbitCamera orbit = OrbitCamera(700.0, 10.0, 0.0, gCanvas);

  RenderProgram prog =
      RenderProgram("textured", cgl, solidColorVertexShader, solidColorFragmentShader);

  Perspective perspective = Perspective(orbit, 0.1, 1000.0);
  RenderPhase phasePerspective = RenderPhase("perspective", cgl);
  phasePerspective.clearColorBuffer = false;
  Scene scenePerspective = Scene("objects", prog, [perspective]);
  phasePerspective.add(scenePerspective);

  // This sets the viewports among other things
  void resolutionChange(HTML.Event? ev) {
    print(
        "@@@@@@@@@@@@ ${gCanvas.clientWidth}x${gCanvas.clientHeight} ${gCanvas.width}x${gCanvas.height} ");
    int w = gCanvas.clientWidth;
    int h = gCanvas.clientHeight;
    gCanvas.width = w;
    gCanvas.height = h;
    print("size change $w $h");
    perspective.AdjustAspect(w, h);
    phasePerspective.viewPortW = w;
    phasePerspective.viewPortH = h;
  }

  resolutionChange(null);
  HTML.window.onResize.listen(resolutionChange);

  double _lastTimeMs = 0.0;
  void animate(num timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs + 0.0;
    //orbit.azimuth += 0.001;
    animateLSystem(elapsed, scenePerspective, prog);
    orbit.animate(elapsed);
    phasePerspective.Draw();

    HTML.window.animationFrame.then(animate);
    // fps.UpdateFrameCount(_lastTimeMs);
  }

  animate(0.0);
  //HTML.window.requestAnimationFrame(animate);
}
