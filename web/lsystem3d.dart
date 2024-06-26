import 'dart:math' as Math;
import 'dart:html' as HTML;
import 'dart:core';
import 'dart:typed_data';

import 'package:lsystem/lsys_examples.dart' as lsys_examples;
import 'package:lsystem/lsys_parse.dart' as parse;
import 'package:lsystem/lsys_rule.dart' as rule;
import 'package:lsystem/webutil.dart' as webutil;

import 'package:vector_math/vector_math.dart' as VM;

import 'package:chronosgl/chronosgl.dart';
import 'shaders.dart' as shaders;

final HTML.CanvasElement gCanvas = HTML.querySelector("#area") as HTML.CanvasElement;
final HTML.SelectElement gPattern = HTML.querySelector("#pattern") as HTML.SelectElement;
final HTML.SelectElement gMode = HTML.querySelector("#mode") as HTML.SelectElement;

final gExamples = lsys_examples.kExamples3d;
final int gRngSeed = 666666666;
//  seed = new DateTime.now().millisecondsSinceEpoch;

List<AnimationCallback> gAnimationCallbacks = [];

abstract class AnimationCallback {
  String name;
  AnimationCallback(this.name);
  List<AnimationCallback> Update(double nowMs, double elapsedMs);
}

num GetRandom(Math.Random rng, num a, num b) {
  return rng.nextDouble() * (b - a) + a;
}

double HexDigitToColorComponent(String s) {
  return int.parse(s, radix: 16) * 1.0 / 15.0;
}

class ModelExtractor extends rule.Plotter {
  //VM.Vector3 _last = VM.Vector3.zero();

  GeometryBuilder _gb = GeometryBuilder();
  List<VM.Vector3> _polygon = [];
  List<VM.Vector3> _polygon_color = [];
  String _color_name = "#fff";
  VM.Vector3 _color_vec = VM.Vector3(1.0, 1.0, 1.0);

  VM.Vector3 GetCurrentColor(rule.State s) {
    String name = s.get(rule.xLineColor);

    if (name != _color_name) {
      if (name[0] == "#") {
        if (name.length == 4) {
          _color_name = name;
          _color_vec = VM.Vector3(HexDigitToColorComponent(name[1]),
              HexDigitToColorComponent(name[2]), HexDigitToColorComponent(name[3]));
        } else {
          assert(false);
        }
      } else {
        assert(false);
      }
    }

    return _color_vec;
  }

  ModelExtractor() {
    _gb.EnableAttribute(aColor);
  }

  @override
  void Init(rule.State s) {}

  @override
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, rule.State s) {
    double len = (dst - src).length;
    VM.Vector3 offset = VM.Vector3.zero();
    VM.Vector3.mix(src, dst, 0.5, offset);
    double width = s.get(rule.xWidth);
    // print("add cylinder: ${rule.str(src)} -> ${rule.str(dst)}  dir: ${rule.str(dst - src)}");
    GeometryBuilder cylinder = CylinderGeometry(width, width, len, 10, true);
    cylinder.EnableAttribute(aColor);

    cylinder.AddAttributesVector3TakeOwnership(
        aColor, List.filled(cylinder.vertices.length, GetCurrentColor(s)));
    _gb.MergeAndTakeOwnership2(cylinder, dir, offset);
    // cube at the end
    /*
    VM.Quaternion no_rot = VM.Quaternion.identity();
    if (false) {
      GeometryBuilder cube = CubeGeometry(x: 2.0, y: 2.0, z: 2.0);
      _gb.MergeAndTakeOwnership2(cube, no_rot, dst);
    }
    // smaller cube in the middle of the cylinder
    if (false) {
      GeometryBuilder cube2 = CubeGeometry(x: 1.5, y: 1.5, z: 1.5);
      _gb.MergeAndTakeOwnership2(cube2, no_rot, offset);
    }
    */
  }

  @override
  void Fini(rule.State s) {
    //
  }

  @override
  void PolyStart(rule.State s) {
    _polygon.clear();
    _polygon_color.clear();
  }

  @override
  void PolyEnd(rule.State s) {
    assert(_polygon.length >= 3, "too few verices: ${_polygon.length}");
    int offset = _gb.AddVerticesTakeOwnership(_polygon);
    _gb.AddAttributesVector3TakeOwnership(aColor, _polygon_color);
    for (int i = 1; i < _polygon.length - 1; ++i) {
      _gb.AddFace3(offset + 0, offset + i, offset + i + 1);
    }
  }

  @override
  void PolyPoint(VM.Vector3 dst, rule.State s) {
    _polygon.add(dst);
    _polygon_color.add(GetCurrentColor(s));
  }

  GeometryBuilder GetGeometryBuilder() {
    return _gb;
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
  List<rule.TokenIndex> _pattern_prefix = [];
  List<rule.TokenIndex> _pattern = [];
  rule.PatternInfo _info = rule.PatternInfo([]);
  Math.Random _rng;
  Map<String, String> _desc = {};

  LSystem(Math.Random rng)
      : _rng = rng,
        _plotter = ModelExtractor() {}

  void Init(Map<String, String> desc) {
    print("Lsystem: ${lsys_examples.Info(desc)}");
    _desc = desc;
    List<String> rule_strs = desc["r"]!.split(";");

    _rules = parse.ParseRules(rule_strs);
    for (var rs in _rules.values) {
      for (var r in rs) {
        print(r);
      }
    }
    _pattern = parse.ExtractAxiom(rule_strs);
    int iterations = int.parse(desc["i"]!);
    for (int i = 0; i < iterations; ++i) {
      _pattern = rule.ExpandOneStep(_pattern, _rules, _rng);
    }

    _info = rule.PatternInfo(_pattern);
    print(_info);
    //

    _pattern_prefix.addAll(
        parse.InitPrefix(desc, VM.Vector3(0.0, 0.0, 0.0), VM.Quaternion.euler(0.0, 0.0, 0.0)));

    _pattern_prefix.add(rule.Token.SetParam(rule.xWidth, 1.0));
    _pattern_prefix.add(rule.Token.SetParam(rule.xLineColor, "#fff"));
    _pattern_prefix.add(rule.Token.SetParam(rule.xBackgroundColor, "#000"));

    // print(rule.StringifySymIndexList(_pattern_prefix));
    print(rule.StringifySymIndexList(_pattern));
  }

  String Info() {
    return "${lsys_examples.Info(_desc)} ${_info}";
  }

  GeometryBuilder render(double t) {
    List<rule.TokenIndex> time_based = [];
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
    return _plotter.GetGeometryBuilder();
  }
}

int gNumExample = 0;
LSystem? gActiveLSystem = null;

void HandleCommand(String cmd, String param) {
  print("HandleCommand: ${cmd} ${param}");
  switch (cmd) {
    case "C":
      webutil.Toggle(HTML.querySelector(".config")!);
      break;
    case "P":
      webutil.Toggle(HTML.querySelector(".performance")!);
      break;
    case "R":
      gActiveLSystem = null;
      break;
    case "1":
      gPattern.selectedIndex = (gNumExample - 1) % gExamples.length;
      gActiveLSystem = null;
      break;
    case "2":
      gPattern.selectedIndex = (gNumExample + 1) % gExamples.length;
      gActiveLSystem = null;
      break;
    case "3":
      lsys_examples.IterationAdd(gExamples[gNumExample], -1);
      gActiveLSystem = null;
      break;
    case "4":
      lsys_examples.IterationAdd(gExamples[gNumExample], 1);
      gActiveLSystem = null;
    case "5":
      lsys_examples.LengthShrink(gExamples[gNumExample]);
      gActiveLSystem = null;
    case "6":
      lsys_examples.LengthGrow(gExamples[gNumExample]);
      gActiveLSystem = null;
    case "7":
      lsys_examples.AngleShrink(gExamples[gNumExample]);
      gActiveLSystem = null;
    case "8":
      lsys_examples.AngleGrow(gExamples[gNumExample]);
      gActiveLSystem = null;
    case "F":
      webutil.ToggleFullscreen();
      break;
    case "C-":
      webutil.Hide(HTML.querySelector(".config")!);
      break;
    case "C+":
      webutil.Show(HTML.querySelector(".config")!);
      break;
  }
}

class UpdateUI extends AnimationCallback {
  final HTML.Element _fps = HTML.querySelector("#fps") as HTML.Element;

  UpdateUI() : super("UpdateUI");

  List<AnimationCallback> Update(double nowMs, double elapsedMs) {
    String extra = gActiveLSystem!.Info();
    webutil.UpdateFrameCount(nowMs, _fps, extra);
    return [this];
  }
}

class DrawRenderPhase extends AnimationCallback {
  RenderPhase _phase;
  Material _mat;

  DrawRenderPhase(this._phase, this._mat) : super("phase:" + _phase.name);

  List<AnimationCallback> Update(double nowMs, double elapsedMs) {
    _mat.ForceUniform(uTime, nowMs / 1000.0);
    _phase.Draw();
    return [this];
  }
}

class CameraAnimation extends AnimationCallback {
  OrbitCamera _camera;
  CameraAnimation(this._camera) : super("CameraAnimation");

  List<AnimationCallback> Update(double nowMs, double elapsedMs) {
    _camera.animate(elapsedMs);
    return [this];
  }
}

void AddInstanceData(MeshData md, Math.Random rng) {
  final int N = 5;
  int count = N * N * N * 8;
  Float32List translations = Float32List(count * 3);
  Float32List rotations = Float32List(count * 4);

  Spatial spatial = Spatial("dummy");
  int pos = 0;
  for (int x = -N; x < N; x++) {
    for (int y = -N; y < N; y++) {
      for (int z = -N; z < N; z++) {
        spatial.setPos(x * 400.0 + rng.nextDouble() * 200.0, y * 400.0 + rng.nextDouble() * 200.0,
            z * 400.0 + rng.nextDouble() * 200.0);
        translations.setAll(pos * 3, spatial.getPos().storage);
        // VM.Quaternion q = VM.Quaternion.fromRotation(spatial.transform.getRotation());
        VM.Quaternion q = VM.Quaternion.random(rng);
        rotations.setAll(pos * 4, q.storage);
        pos++;
      }
    }
  }
  assert(pos == count);

  md.AddAttribute(iaRotation, rotations, 4);
  md.AddAttribute(iaTranslation, translations, 3);
}

class MaybeSwitchLSystem extends AnimationCallback {
  Scene _sceneNormal;
  Scene _sceneNormalInstanced;
  Scene _scenePoints;
  Scene _scenePointsInstanced;
  Scene _sceneAnimatedPoints;
  Material _mat;

  MaybeSwitchLSystem(this._sceneNormal, this._sceneNormalInstanced, this._scenePoints,
      this._scenePointsInstanced, this._sceneAnimatedPoints, this._mat)
      : super("MaybeSwitchLSystem") {}

  List<AnimationCallback> Update(double nowMs, double elapsedMs) {
    int active = gPattern.selectedIndex!;

    if (gActiveLSystem == null || active != gNumExample) {
      // print("current pattern index ${active} vs $gNumExample}");
      gNumExample = active;

      var start = DateTime.now();

      gActiveLSystem = LSystem(Math.Random(gRngSeed));
      gActiveLSystem!.Init(gExamples[gNumExample % gExamples.length]);
      var stop = DateTime.now();
      print("lsystem expansion took ${stop.difference(start)}");
      start = DateTime.now();
      GeometryBuilder gb = gActiveLSystem!.render(nowMs);
      stop = DateTime.now();
      print("lsystem rendering took ${stop.difference(start)}");
      //
      print(">>>>>>>>>>>> ${gMode.value}");
      //
      _sceneNormal.removeAll();
      _sceneNormalInstanced.removeAll();

      _scenePoints.removeAll();
      _scenePointsInstanced.removeAll();

      _sceneAnimatedPoints.removeAll();

      switch (gMode.value as String) {
        case "Normal":
          var ground = CubeGeometry(x: 40.0, y: 0.5, z: 40.0);
          ground.EnableAttribute(aColor);
          ground.AddAttributesVector3TakeOwnership(
              aColor, List.filled(ground.vertices.length, ColorRed));
          _sceneNormal.add(
              Node("cube", GeometryBuilderToMeshData("ground", _sceneNormal.program, ground), _mat)
                ..setPos(0.0, -10.0, 0.0));
          _sceneNormal
              .add(Node("tree", GeometryBuilderToMeshData("tree", _sceneNormal.program, gb), _mat));
        case "NormalInstanced":
          MeshData md = GeometryBuilderToMeshData("tree", _sceneNormalInstanced.program, gb);
          AddInstanceData(md, Math.Random(gRngSeed));
          _sceneNormalInstanced.add(Node("tree", md, _mat));
        case "Points":
          MeshData mesh = GeometryBuilderToMeshData("tree", _sceneNormal.program, gb);
          final double area = GetMeshFaceArea(mesh);
          print("area is ${area}");
          MeshData points = ExtractPointCloud(_scenePoints.program, mesh, (area * 10.0).toInt(),
              extract_color: true, extract_normal: false);
          _scenePoints.add(Node("tree", points, _mat));
        case "PointsInstanced":
          MeshData mesh = GeometryBuilderToMeshData("tree", _sceneNormal.program, gb);
          MeshData points = ExtractPointCloud(_scenePointsInstanced.program, mesh, 200000,
              extract_color: true, extract_normal: false);
          AddInstanceData(points, Math.Random(gRngSeed));
          _scenePointsInstanced.add(Node("tree", points, _mat));
        case "AnimatedPoints":
          MeshData mesh = GeometryBuilderToMeshData("tree", _sceneNormal.program, gb);
          MeshData points = ExtractPointCloud(_sceneAnimatedPoints.program, mesh, 200000,
              extract_color: true, extract_normal: false);
          points.AddAttribute(shaders.aNoise, Float32List(points.GetNumItems()), 1);

          //AnimatedPointCloud apc =
          //    AnimatedPointCloud(_scene.program.getContext(), _scenePoints.program, mesh, 50000);
          _sceneAnimatedPoints.add(Node("tree", points, _mat));
        default:
          print("Unknown mode [${gMode.value}]");
      }
    }
    return [this];
  }
}

void main() {
  print("Startup");
  IntroduceNewShaderVar(shaders.aNoise, const ShaderVarDesc(VarTypeFloat, ""));

  rule.RegisterStandardParams();
  HTML.SelectElement patterns = HTML.querySelector("#pattern") as HTML.SelectElement;
  int count = 0;
  for (var desc in gExamples) {
    HTML.OptionElement o = new HTML.OptionElement(data: desc["name"]!, value: "${count}");
    patterns.append(o);
    ++count;
  }

/*
  final int w = HTML.document.body!.clientWidth;
  final int h = HTML.document.body!.clientHeight;
  final int w2 = HTML.window.innerWidth!;
  final int h2 = HTML.window.innerHeight!;
  */
/*
  for (var example in lsys2d_examples.kExamples) {
    print(example["name"]!);
    // just confirm we can parse it
    lsys2d.ParseRules(example["r"]!);
  }
  log.LogInfo("main: ${w}x${h} ${w2}x${h2}");
*/
  HTML.document.body!.onKeyDown.listen((HTML.KeyboardEvent e) {
    print("key pressed ${e.keyCode} ${e.target.runtimeType}");
    if (e.target.runtimeType == HTML.InputElement) {
      return;
    }

    String cmd = new String.fromCharCodes([e.keyCode]);
    HandleCommand(cmd, "");
  });

  HTML.document.body!.onClick.listen((HTML.MouseEvent ev) {
    if (ev.target.runtimeType != HTML.CanvasElement) return;
    print("click ${ev.target.runtimeType}");
    HandleCommand("C", "");
  });

  HTML.ElementList<HTML.Element> buttons = HTML.document.body!.querySelectorAll("button");
  print("found ${buttons.length} buttons");
  buttons.onClick.listen((HTML.Event ev) {
    String cmd = (ev.target as HTML.Element).dataset['cmd']!;
    String param = (ev.target as HTML.Element).dataset['param']!;
    HandleCommand(cmd, param);
  });

  ChronosGL cgl = ChronosGL(gCanvas);

  OrbitCamera orbit = OrbitCamera(700.0, 10.0, 0.0, gCanvas);
  final RenderProgram progPoints = RenderProgram(
      "coloredPoints", cgl, shaders.coloredPointsVertexShader, shaders.coloredPointsFragmentShader);

  final RenderProgram progPointsInstanced = RenderProgram("coloredPoints", cgl,
      shaders.coloredPointsVertexShaderInstanced, shaders.coloredPointsFragmentShader);

  final RenderProgram progAnimatedPoints = RenderProgram("animatedColoredPoints", cgl,
      shaders.animatedPointsVertexShader, shaders.animatedPointsFragmentShader);

  final RenderProgram progNormal = RenderProgram(
      "coloredVertices", cgl, shaders.multiColorVertexShader, shaders.multiColorFragmentShader);

  final RenderProgram progNormalInstanced = RenderProgram("coloredVertices", cgl,
      shaders.multiColorVertexShaderInstanced, shaders.multiColorFragmentShader);

  Material mat = Material("timer")..SetUniform(uPointSize, 10.0);
  Perspective perspective = Perspective(orbit, 0.1, 5000.0);
  RenderPhase phasePerspective = RenderPhase("perspective", cgl);
  phasePerspective.clearColorBuffer = false;

  Scene sceneNormal = Scene("normal", progNormal, [perspective]);
  phasePerspective.add(sceneNormal);

  Scene sceneAnimatedPoints = Scene("animatedPoints", progAnimatedPoints, [perspective]);
  phasePerspective.add(sceneAnimatedPoints);

  Scene scenePoints = Scene("points", progPoints, [perspective]);
  phasePerspective.add(scenePoints);

  Scene scenePointsInstanced = Scene("points", progPointsInstanced, [perspective]);
  phasePerspective.add(scenePointsInstanced);

  Scene sceneNormalInstanced = Scene("normal", progNormalInstanced, [perspective]);
  phasePerspective.add(sceneNormalInstanced);

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

  gAnimationCallbacks = [
    MaybeSwitchLSystem(sceneNormal, sceneNormalInstanced, scenePoints, scenePointsInstanced,
        sceneAnimatedPoints, mat),
    UpdateUI(),
    DrawRenderPhase(phasePerspective, mat),
    CameraAnimation(orbit),
  ];

  void animate(num timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs + 0.0;
    //
    List<AnimationCallback> new_callbacks = [];
    for (var cb in gAnimationCallbacks) {
      new_callbacks.addAll(cb.Update(_lastTimeMs, elapsed));
    }
    gAnimationCallbacks = new_callbacks;
    HTML.window.animationFrame.then(animate);
  }

  animate(0.0);
}
