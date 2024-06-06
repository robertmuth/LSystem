import 'dart:math' as Math;

import 'package:lsystem/lsys2d_examples.dart' as lsys2d_examples;
import 'package:lsystem/lsys2d.dart' as lsys2d;
import 'package:lsystem/rule.dart' as rule;

import 'package:vector_math/vector_math.dart' as VM;

void TestMe(VM.Quaternion dir) {
  print("quad: ${rule.qstr(dir)}");
  VM.Vector3 x = VM.Vector3.zero();
  x.setValues(0.0, 1.0, 0.0);
  dir.rotate(x);
  print("Direction from quad: ${rule.str(x)}");
  /*
  VM.Matrix3 rot = VM.Matrix3.identity();
  dir.copyRotationInto(rot);
  x.setValues(0.0, 1.0, 0.0);
  rot.transform(x);
  print("Direction from rot: ${rule.str(x)}");
  */
}

class DebugPlotter extends rule.Plotter {
  @override
  void Init(rule.State s) {
    print("Init: ${s}");
  }

  @override
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, rule.State s) {
    print("Draw ${rule.str(src)} -> ${rule.str(dst)}");
    TestMe(dir);
  }

  @override
  void Fini(rule.State s) {
    print("Fini: ${s}");
  }

  @override
  void PolyStart(rule.State s) {
    print("PolyStart: ${s}");
  }

  @override
  void PolyEnd(rule.State s) {
    print("PolyEnd: ${s}");
  }

  @override
  void PolyPoint(VM.Vector3 dst, rule.State s) {
    print("PolyPoint ${rule.str(dst)}");
  }
}

void main(List<String> args) {
  Math.Random rng = Math.Random(0);
  var desc = lsys2d_examples.kExamples[0];
  List<String> rule_strs = desc["r"]!.split(";");
  Map<String, List<rule.Rule>> rules = lsys2d.ParseRules(rule_strs);
  String name = desc["name"]!;
  print("Lsystem: ${name}");
  for (var rs in rules.values) {
    for (var r in rs) {
      print(r);
    }
  }
  List<rule.SymIndex> pattern_prefix = [];
  pattern_prefix.addAll(lsys2d.InitPrefix(desc, VM.Vector3(0, 0, 0), VM.Quaternion.euler(0, 0, 0)));

  List<rule.SymIndex> pattern = [rule.Sym.Symbol("L")];
  int iterations = int.parse(desc["i"]!);
  for (int i = 0; i < iterations; ++i) {
    pattern = rule.ExpandOneStep(pattern, rules, rng);
  }
  print("${rule.PatternInfo(pattern)}");
  rule.RenderAll(pattern_prefix, pattern, DebugPlotter());
}
