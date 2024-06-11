import 'dart:math' as Math;
import 'dart:html';
import 'dart:core';
import 'package:lsystem/lsys2d_examples.dart' as lsys2d_examples;
import 'package:lsystem/lsys2d.dart' as lsys2d;
import 'package:lsystem/rule.dart' as rule;
import 'package:lsystem/webutil.dart';

import 'package:vector_math/vector_math.dart' as VM;

final Element gFps = querySelector("#fps") as Element;
final CanvasElement gCanvas = querySelector("#area") as CanvasElement;
final SelectElement gPattern = querySelector("#pattern") as SelectElement;

num GetRandom(Math.Random rng, num a, num b) {
  return rng.nextDouble() * (b - a) + a;
}

class Canvas2dPlotter extends rule.Plotter {
  CanvasElement _canvas;
  VM.Vector3 _last = VM.Vector3.zero();
  List<List<VM.Vector3>> _polygons = [];

  Canvas2dPlotter(this._canvas);
  @override
  void Init(rule.State s) {
    var context = _canvas.context2D;
    context
      ..fillStyle = s.get(rule.xBackgroundColor)
      ..fillRect(0, 0, _canvas.width!, _canvas.height!);
    context
      ..lineWidth = s.get(rule.xWidth)
      ..strokeStyle = s.get(rule.xLineColor)
      //..strokeStyle = _ac.Color(2)
      ..beginPath();
  }

  @override
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, rule.State s) {
    var context = _canvas.context2D;
    if (_last != src) {
      context.moveTo(src.x, src.y);
    }
    context.lineTo(dst.x, dst.y);
    dst.copyInto(_last);
  }

  @override
  void Fini(rule.State s) {
    var context = _canvas.context2D;
    context..stroke();
    for (var poly in _polygons) {
      assert(poly.length >= 3);
      context
        ..moveTo(poly[0].x, poly[0].y)
        ..lineWidth = s.get(rule.xWidth)
        ..strokeStyle = s.get(rule.xLineColor)
        ..fillStyle = s.get(rule.xLineColor)
        ..beginPath();
      for (var point in poly) {
        context.lineTo(point.x, point.y);
      }
      context.closePath();
      context..fill();
    }
  }

  @override
  void PolyStart(rule.State s) {
    _polygons.add([]);
  }

  @override
  void PolyEnd(rule.State s) {
    // do nothing
  }

  @override
  void PolyPoint(VM.Vector3 dst, rule.State s) {
    _polygons.last.add(dst);
  }
}

/**

 * This class maintains a list of planetary bodies, knows how to draw its
 * background and the planets, and requests that it be redraw at appropriate
 * intervals using the [Window.requestAnimationFrame] method.
 */
class LSystem {
  CanvasElement _canvas;
  Canvas2dPlotter _plotter;
  int _currentCycle = 0;
  int _width = 0;
  int _height = 0;
  Map<String, List<rule.Rule>> _rules = {};
  List<rule.SymIndex> _pattern_prefix = [];
  List<rule.SymIndex> _pattern = [];
  String _name = "";
  rule.PatternInfo _info = rule.PatternInfo([]);
  Math.Random _rng;

  LSystem(this._canvas, Math.Random rng)
      : _rng = rng,
        _plotter = Canvas2dPlotter(_canvas) {
    _width = _canvas.width!;
    _height = _canvas.height!;

    print("lsystem: ${_width}x${_height} ${_currentCycle}");
  }

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

    _pattern_prefix.addAll(lsys2d.InitPrefix(
        desc, VM.Vector3(_width / 2, _height / 2, 0.0), VM.Quaternion.euler(0, 0, 1.0 * Math.pi)));

    _pattern_prefix.add(rule.Sym.SetParam(rule.xWidth, 1.0));
    _pattern_prefix.add(rule.Sym.SetParam(rule.xLineColor, "#fff"));
    _pattern_prefix.add(rule.Sym.SetParam(rule.xBackgroundColor, "#000"));
    //

    // print(rule.StringifySymIndexList(_pattern_prefix));
    // print(_pattern);
  }

  String Info() {
    return "[${_name}] ${_info}";
  }

  void draw(double t) {
    _currentCycle++;
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
  }
}

int gNumExample = 0;
LSystem? gActiveLSystem = null;

void HandleCommand(String cmd, String param) {
  var examples = lsys2d_examples.kExamples;
  print("HandleCommand: ${cmd} ${param}");
  switch (cmd) {
    case "C":
      Toggle(querySelector(".config")!);
      break;
    case "P":
      Toggle(querySelector(".performance")!);
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
    case "3":
      print("iter-");
      var desc = lsys2d_examples.kExamples[gNumExample];
      int n = int.parse(desc["i"]!);
      desc["i"] = "${n - 1}";
      gActiveLSystem = null;
      break;
    case "4":
      print("iter+");
      var desc = lsys2d_examples.kExamples[gNumExample];
      int n = int.parse(desc["i"]!);
      desc["i"] = "${n + 1}";
      gActiveLSystem = null;
    case "5":
      print("len+");
      var desc = lsys2d_examples.kExamples[gNumExample];
      List<double> vals = List.from(desc["p.size"]!.split(",").map(double.parse));
      vals[0] = vals[0] * (1.0 - vals[1]);
      desc["p.size"] = "${vals[0]},${vals[1]}";
      gActiveLSystem = null;
    case "6":
      print("len+");
      var desc = lsys2d_examples.kExamples[gNumExample];
      List<double> vals = List.from(desc["p.size"]!.split(",").map(double.parse));
      vals[0] = vals[0] * (1.0 + vals[1]);
      desc["p.size"] = "${vals[0]},${vals[1]}";
      gActiveLSystem = null;
    case "F":
      ToggleFullscreen();
      break;
    case "C-":
      Hide(querySelector(".config")!);
      break;
    case "C+":
      Show(querySelector(".config")!);
      break;
  }
}

void animate(num t_num) {
  double t = t_num + 0.0;
  int active = gPattern.selectedIndex!;

  if (gActiveLSystem == null || active != gNumExample) {
    print("index ${active} vs $gNumExample}");
    gNumExample = active;
    final int w = document.body!.clientWidth;
    final int h = document.body!.clientHeight;
    final int w2 = window.innerWidth!;
    final int h2 = window.innerHeight!;
    print("restart ${w}x${h} ${w2}x${h2}");
    //DivElement div = querySelector("#canvasdiv");
    //LogInfo("div dimensions: ${div.clientWidth}x${div.clientHeight}");

    gCanvas.width = w2;
    gCanvas.height = h2;
    print("canvas dimensions: ${gCanvas.width}x${gCanvas.height}");
    int seed = 666;
    if (seed == 0) {
      seed = new DateTime.now().millisecondsSinceEpoch;
    }

    var examples = lsys2d_examples.kExamples;
    gActiveLSystem = LSystem(gCanvas, Math.Random(seed));
    gActiveLSystem!.Init(examples[gNumExample % examples.length]);
  } else {
    LSystem s = gActiveLSystem!;

    String extra = s.Info();

    UpdateFrameCount(t, gFps, extra);

    s.draw(t / 10);
    /*
    if (s.Cycles() > gOptions.GetInt("maxCycles")) {
      gActiveSubstrate = null;
    }
    */
  }
  window.requestAnimationFrame(animate);
}

void main() {
  rule.RegisterStandardParams();

  SelectElement patterns = querySelector("#pattern") as SelectElement;
  int count = 0;
  for (var desc in lsys2d_examples.kExamples) {
    OptionElement o = new OptionElement(data: desc["name"]!, value: "${count}");
    patterns.append(o);
    ++count;
  }

  final int w = document.body!.clientWidth;
  final int h = document.body!.clientHeight;
  final int w2 = window.innerWidth!;
  final int h2 = window.innerHeight!;

  for (var example in lsys2d_examples.kExamples) {
    print(example["name"]!);
    // just confirm we can parse it
    lsys2d.ParseRules(example["r"]!.split(";"));
  }
  print("main: ${w}x${h} ${w2}x${h2}");

  document.body!.onKeyDown.listen((KeyboardEvent e) {
    print("key pressed ${e.keyCode} ${e.target.runtimeType}");
    if (e.target.runtimeType == InputElement) {
      return;
    }

    String cmd = new String.fromCharCodes([e.keyCode]);
    HandleCommand(cmd, "");
  });

  document.body!.onClick.listen((MouseEvent ev) {
    if (ev.target.runtimeType != CanvasElement) return;
    print("click ${ev.target.runtimeType}");
    HandleCommand("C", "");
  });

  ElementList<Element> buttons = document.body!.querySelectorAll("button");
  print("found ${buttons.length} buttons");
  buttons.onClick.listen((Event ev) {
    String cmd = (ev.target as Element).dataset['cmd']!;
    String param = (ev.target as Element).dataset['param']!;
    HandleCommand(cmd, param);
  });
  var rot = VM.Quaternion.euler(0.0, 0.0, -0.5 * Math.pi);
  rot = rot * rot * rot;
  var vec = rot.rotated(VM.Vector3(1, 0, 0));
  print("####### ${vec}");
  window.requestAnimationFrame(animate);
}
