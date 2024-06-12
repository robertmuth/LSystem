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

final HTML.CanvasElement gCanvas = HTML.querySelector("#area") as HTML.CanvasElement;
final HTML.SelectElement gPattern = HTML.querySelector("#pattern") as HTML.SelectElement;

final gExamples = lsys_examples.kExamples3d;

abstract class AnimationCallback {
  String name;
  AnimationCallback(this.name);
  List<AnimationCallback> Update(double nowMs, double elapsedMs);
}

const String aCurrentPosition = "aCurrentPosition";
const String aNoise = "aNoise";
const int DEFLATE_START = 1;
const int DEFLATE_END = 2;
const int INFLATE_START = 3;
const int INFLATE_END = 4;
const int PERIOD = INFLATE_END;

List<AnimationCallback> gAnimationCallbacks = [];
final ShaderObject dustVertexShader = ShaderObject("dustV")
  ..AddAttributeVars([aPosition, aCurrentPosition, aNoise, aNormal])
  ..AddVaryingVars([vColor])
  ..AddTransformVars([tPosition])
  ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix, uTime, uPointSize])
  ..SetBody([
    """

const float bottom = -150.0;
const vec3 gray = vec3(0.5);
const vec3 SPREAD_VOL = vec3(500.0, 2.0, 100.0);

float ip(float start, float end, float x) {
  //return smoothstep(start, end, x);

  if (x <= start) return 0.0;
  if (x >= end) return 1.0;
  return (x - start) / (end - start);
}

// deterministic rng: result is between vec3(-.5) and vec3(.5)
vec3 GetNoise(float seed) {
  return vec3(fract(${aNoise} * seed),
              fract(${aNoise} * seed * 100.0),
              fract(${aNoise} * seed * 10000.0)) - vec3(0.5);
}
vec3 GetVertexNoise(vec3 noise, float x) {
  return vec3(2.0 + 500.0 * x, 5.0 + 500.0 * x , 10.0 + 500.0 * x) * noise;
}
void main() {

    vec3 curr_pos = ${aCurrentPosition};

    vec3 orig_pos = ${aPosition};
    vec3 orig_col = abs(${aNormal}.xyz);

   vec3 noise = GetNoise(1.1);

    vec3 color_noise =  0.4 * noise ;
    float time_noise =  0.3 * length(noise);
    // time_noise = 0.0;
    float t = mod(${uTime} - time_noise, float(${PERIOD}));

    vec3 new_pos;
    vec3 new_col;

    if (t <= float(${DEFLATE_START})) {
      new_pos = orig_pos;
      new_col = orig_col;
    } else if (t < float(${DEFLATE_END})) {
      float x =  ip(float(${DEFLATE_START}), float(${DEFLATE_END}), t);
      new_pos = mix(orig_pos,
                    vec3(curr_pos.x, bottom, curr_pos.z) + GetVertexNoise(noise, 1.0 - x), x);
      new_col = mix(orig_col, gray + color_noise, x);


    } else if (t < float(${INFLATE_START})) {
       new_pos = curr_pos;
       new_col = gray + color_noise;
    } else {
      float x =  ip(float(${INFLATE_START}), float(${INFLATE_END}), t);
      new_pos =  mix(vec3(curr_pos.x, bottom, curr_pos.z) + GetVertexNoise(noise, x),
                     orig_pos, x);
      new_col = mix(gray + color_noise, orig_col, x);
    }

/*
    float t = mod(${uTime}, float(${PERIOD}));

    vec3 noise0 = GetNoise(1.1);

    // https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform

    vec3 noise1 = GetNoise(2.2);
    vec3 noise2 = GetNoise(3.3);
    vec3 noise3 = GetNoise(4.4);

    vec3 noiseT = GetNoise(t);

    vec3 color_noise =  0.4 * noise0;
    float time_noise =  0.3 * length(noise0);



    vec3 pile_col = gray + color_noise;
    vec3 pile_pos = SPREAD_VOL * (noise0 + noise1 + noise2 + noise3);
    pile_pos.y = abs(pile_pos.y) + bottom;

    vec3 new_pos;
    vec3 new_col;

    if (t <= float(${DEFLATE_START})) {
      new_pos = orig_pos;
      new_col = orig_col;
    } else if (t < float(${DEFLATE_END})) {
      float x =  ip(float(${DEFLATE_START}), float(${DEFLATE_END}), t);
      //vec3 noisy_pile_pos =  pile_pos + noiseT * SPREAD_VOL * 0.1 * (1.0 - x);
      vec3 noisy_pile_pos =  pile_pos;

      new_pos = mix(curr_pos, noisy_pile_pos, x);
      new_col = mix(orig_col, pile_col, x);
    } else if (t < float(${INFLATE_START})) {
       new_pos = curr_pos;
       new_col = pile_col;
    } else {
      float x =  ip(float(${INFLATE_START}), float(${INFLATE_END}), t);
      new_pos =  mix(curr_pos + noiseT * SPREAD_VOL * 0.1, orig_pos, x);
      new_col = mix(pile_col, orig_col, x);
    }
*/

    // will become aCurrentPosition int the next run
    ${tPosition} = new_pos;
    ${vColor}.rgb  = new_col;
    gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(new_pos, 1.0);
    gl_PointSize = ${uPointSize} / gl_Position.z;
}
"""
  ]);

final ShaderObject dustFragmentShader = ShaderObject("dustF")
  ..AddVaryingVars([vColor])
  ..SetBody([
    """
void main() {
    ${oFragColor}.rgb = ${vColor};
}
    """
  ]);

num GetRandom(Math.Random rng, num a, num b) {
  return rng.nextDouble() * (b - a) + a;
}

double HexDigitToColorComponent(String s) {
  return int.parse(s, radix: 16) * 1.0 / 15.0;
}

//
class AnimatedPointCloud {
  ChronosGL _cgl;
  RenderProgram _prog;
  late MeshData _points;
  late MeshData _out;

  AnimatedPointCloud(this._cgl, this._prog, MeshData mesh, int num_points) {
    _points = ExtractPointCloud(_prog, mesh, num_points);
    // clone _points[aPosition] to _points[aCurrentPosition]
    _points.AddAttribute(aCurrentPosition, _points.GetAttribute(aPosition), 3);
    _out = _prog.MakeMeshData("out", GL_POINTS)
      ..AddVertices(_points.GetAttribute(aPosition) as Float32List);
    // make sure the vertex shader when writing to tPosition is
    // writing to _out[aPosition]
    final int bindingIndex = _prog.GetTransformBindingIndex(tPosition);
    _cgl.bindBuffer(GL_ARRAY_BUFFER, null);
    _cgl.bindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, null);
    _cgl.bindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, _out.GetBuffer(aPosition));
  }

  MeshData points() {
    return _points;
  }

  // copies from out[aPosition] -> points[aCurrentPosition]
  void CopyData() {
    // use vertex shader output as aCurrentPositions for next round
    _cgl.bindBuffer(GL_ARRAY_BUFFER, _points.GetBuffer(aCurrentPosition));
    _cgl.bindBuffer(GL_TRANSFORM_FEEDBACK_BUFFER, _out.GetBuffer(aPosition));
    _cgl.copyBufferSubData(
        GL_TRANSFORM_FEEDBACK_BUFFER, GL_ARRAY_BUFFER, 0, 0, _points.GetNumItems() * 3 * 4);
  }
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

class MaybeSwitchLSystem extends AnimationCallback {
  Scene _scene;
  Scene _scenePoints;

  MaybeSwitchLSystem(this._scene, this._scenePoints) : super("MaybeSwitchLSystem") {}

  List<AnimationCallback> Update(double nowMs, double elapsedMs) {
    int active = gPattern.selectedIndex!;

    if (gActiveLSystem == null || active != gNumExample) {
      // print("current pattern index ${active} vs $gNumExample}");
      gNumExample = active;

      int seed = 666;
      if (seed == 0) {
        seed = new DateTime.now().millisecondsSinceEpoch;
      }
      var start = DateTime.now();

      gActiveLSystem = LSystem(Math.Random(seed));
      gActiveLSystem!.Init(gExamples[gNumExample % gExamples.length]);
      var stop = DateTime.now();
      print("lsystem expansion took ${stop.difference(start)}");
      start = DateTime.now();
      GeometryBuilder gb = gActiveLSystem!.render(nowMs);
      stop = DateTime.now();
      print("lsystem rendering took ${stop.difference(start)}");
      Material mat = Material("dummy");
      _scene.removeAll();
      var ground = CubeGeometry(x: 40.0, y: 0.5, z: 40.0);
      ground.EnableAttribute(aColor);
      ground.AddAttributesVector3TakeOwnership(
          aColor, List.filled(ground.vertices.length, ColorRed));
      _scene.add(Node("cube", GeometryBuilderToMeshData("ground", _scene.program, ground), mat)
        ..setPos(0.0, -10.0, 0.0));
      _scene.add(Node("tree", GeometryBuilderToMeshData("tree", _scene.program, gb), mat));
    }
    return [this];
  }
}

void main() {
  print("Startup");
  IntroduceNewShaderVar(aCurrentPosition, const ShaderVarDesc(VarTypeVec3, ""));
  IntroduceNewShaderVar(aNoise, const ShaderVarDesc(VarTypeFloat, ""));

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
  final RenderProgram progFireworks =
      RenderProgram("animatedColoredPoints", cgl, dustVertexShader, dustFragmentShader);

  RenderProgram prog =
      RenderProgram("coloredVertices", cgl, multiColorVertexShader, multiColorFragmentShader);

  Material mat = Material("timer");
  Perspective perspective = Perspective(orbit, 0.1, 5000.0);
  RenderPhase phasePerspective = RenderPhase("perspective", cgl);
  phasePerspective.clearColorBuffer = false;

  Scene scenePerspective = Scene("objects", prog, [perspective]);
  phasePerspective.add(scenePerspective);

  Scene scenePoints = Scene("objects", progFireworks, [perspective]);
  phasePerspective.add(scenePoints);

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
    MaybeSwitchLSystem(scenePerspective, scenePoints),
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
