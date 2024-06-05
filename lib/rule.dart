import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' as VM;

import 'package:sprintf/sprintf.dart';

enum Kind {
  INVALID,
  SET_CONST,
  ADD_CONST,
  MUL_CONST,
  SUB,
  ADD,
  MUL,
  YAW_ADD,
  YAW_SUB,
  YAW_ADD_CONST,
  ROLL_ADD,
  ROLL_SUB,
  ROLL_ADD_CONST,
  PITCH_ADD,
  PITCH_SUB,
  PITCH_ADD_CONST,
  GROW,
  SHRINK,
  // also marks end of parameter
  SYMBOL,
  //
  STACK_PUSH,
  STACK_POP,
  POLY_START,
  POLY_END,
  //
}

class ParamDescriptor {
  static int gNumDescriptors = 0;

  static List<ParamDescriptor> gAllDescriptors = [];

  int num;
  String name;
  dynamic Function() ctor;
  dynamic Function(dynamic) cloner;

  ParamDescriptor(this.num, this.name, this.ctor, this.cloner);

  static int Register(String name, dynamic Function() ctor, dynamic cloner) {
    var d = ParamDescriptor(gNumDescriptors, name, ctor, cloner);
    ++gNumDescriptors;
    gAllDescriptors.add(d);
    return d.num;
  }
}

final int xPos = ParamDescriptor.Register("#pos", () => VM.Vector3.zero(), (x) => x.clone());
final int xDir = ParamDescriptor.Register("#dir", () => VM.Quaternion.identity(), (x) => x.clone());
final int xStepSize = ParamDescriptor.Register("#stepSize", () => 0.0, (x) => x);
final int xWidth = ParamDescriptor.Register("#width", () => 0.0, (x) => x);
final int xBackgroundColor = ParamDescriptor.Register("#bgColor", () => "", (x) => x);
final int xLineColor = ParamDescriptor.Register("#lineColor", () => "", (x) => x);

bool KindIsParameter(Kind k) {
  return (Kind.SET_CONST as int) <= (k as int) && (k as int) <= (Kind.SHRINK as int);
}

typedef SymIndex = int;
List<Sym> GlobalSyms = [];

class Sym {
  Kind kind;
  String text = "";
  int field = -1;
  dynamic parameter = null;

  Sym(this.kind, [this.text = "", this.field = -1, this.parameter = null]);

  static SymIndex GetIndexForSymbo(Sym sym) {
    for (int i = 0; i < GlobalSyms.length; ++i) {
      if (GlobalSyms[i] == sym) return (i << 8) + sym.kind.index;
    }
    GlobalSyms.add(sym);
    return ((GlobalSyms.length - 1) << 8) + sym.kind.index;
  }

  static Sym GetSymbolForIndex(SymIndex i) {
    return GlobalSyms[i >> 8];
  }

  static SymIndex Simple(Kind kind) {
    return GetIndexForSymbo(Sym(kind));
  }

  static SymIndex Symbol(String text) {
    return GetIndexForSymbo(Sym(Kind.SYMBOL, text));
  }

  static SymIndex Param(Kind kind, int name, dynamic parameter) {
    return GetIndexForSymbo(Sym(kind, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  static SymIndex SetParam(int name, dynamic parameter) {
    return GetIndexForSymbo(
        Sym(Kind.SET_CONST, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  static SymIndex AddParam(int name, dynamic parameter) {
    return GetIndexForSymbo(
        Sym(Kind.ADD_CONST, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  @override
  bool operator ==(Object o) {
    Sym other = o as Sym;
    return kind == other.kind && text == other.text && parameter == other.parameter;
  }

  @override
  String toString() {
    switch (kind) {
      case Kind.SET_CONST:
      case Kind.ADD_CONST:
      case Kind.MUL_CONST:
      case Kind.GROW:
      case Kind.SHRINK:
      case Kind.YAW_ADD_CONST:
      case Kind.ROLL_ADD_CONST:
      case Kind.PITCH_ADD_CONST:
        return "${kind.name} ${text} ${parameter}";
      case Kind.SUB:
      case Kind.ADD:
      case Kind.MUL:
      case Kind.YAW_ADD:
      case Kind.YAW_SUB:
      case Kind.ROLL_ADD:
      case Kind.ROLL_SUB:
      case Kind.PITCH_ADD:
      case Kind.PITCH_SUB:
        return "${kind.name} ${text} ${parameter}";
      case Kind.SYMBOL:
        return "[${text}]";
      //
      case Kind.INVALID:
      case Kind.STACK_PUSH:
      case Kind.STACK_POP:
      case Kind.POLY_START:
      case Kind.POLY_END:
        return "${kind.name}";
    }
  }
}

String StringifySymIndexList(List<SymIndex> syms) {
  List<String> rhs = [];
  for (SymIndex i in syms) {
    rhs.add("${Sym.GetSymbolForIndex(i)}");
  }
  return rhs.join(" ");
}

class Rule {
  String head;
  List<SymIndex> expansion;

  Rule(this.head, this.expansion);

  @override
  String toString() {
    return "${head} -> ${StringifySymIndexList(expansion)}";
  }
}

List<SymIndex> ExpandOneStep(List<SymIndex> input, Map<String, List<Rule>> rules, Math.Random rng) {
  final start = DateTime.now();
  List<SymIndex> out = [];
  for (SymIndex i in input) {
    Kind kind = Kind.values[i & 0xff];
    if (kind != Kind.SYMBOL) {
      out.add(i);
      continue;
    }
    Sym s = Sym.GetSymbolForIndex(i);

    var x = rules[s.text];
    if (x == null) {
      // assert(s.text == "F");
      out.add(i);
      continue;
    }
    Rule r = x[rng.nextInt(x.length)];
    out.addAll(r.expansion);
  }
  print("@@ expand ${input.length} -> ${out.length} [${DateTime.now().difference(start)}]");
  return out;
}

class State {
  List<dynamic> _state = [];
  double last_angle_yaw = 0.0;
  VM.Vector3 _axis_x = VM.Vector3(1, 0, 0);
  VM.Vector3 _axis_y = VM.Vector3(0, 1, 0);
  VM.Vector3 _axis_z = VM.Vector3(0, 0, 1);
  VM.Quaternion _tmp_rot = VM.Quaternion.identity();
  dynamic get(int key) {
    return _state[key]!;
  }

  void Init() {
    for (int i = 0; i < ParamDescriptor.gAllDescriptors.length; ++i) {
      ParamDescriptor pd = ParamDescriptor.gAllDescriptors[i];
      _state.add(pd.ctor());
    }
  }

  State Clone() {
    var s = State();
    for (int i = 0; i < ParamDescriptor.gAllDescriptors.length; ++i) {
      ParamDescriptor pd = ParamDescriptor.gAllDescriptors[i];
      s._state.add(pd.cloner(_state[i]));
    }
    return s;
  }

  void set(int key, dynamic val) {
    _state[key] = val;
  }

  void Update(Sym sym) {
    print("@@@@@ UPDATE ${sym}");
    dynamic val;
    switch (sym.kind) {
      case Kind.ADD_CONST:
        val = _state[sym.field]! + sym.parameter;
      case Kind.MUL_CONST:
        val = _state[sym.field]! * sym.parameter;
      case Kind.SET_CONST:
        val = sym.parameter;
      //
      case Kind.SUB:
        val = _state[sym.field]! - _state[sym.parameter]!;
      case Kind.MUL:
        val = _state[sym.field]! * _state[sym.parameter]!;
      case Kind.ADD:
        val = _state[sym.field]! + _state[sym.parameter]!;
      //
      case Kind.GROW:
        val = _state[sym.field]! * (1.0 + _state[sym.parameter]!);
      case Kind.SHRINK:
        val = _state[sym.field]! * (1.0 - _state[sym.parameter]!);
      //
      case Kind.YAW_ADD:
        print("YAW_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_z, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.YAW_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_z, sym.parameter as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.YAW_SUB:
        print("YAW_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_z, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      //
      case Kind.ROLL_ADD:
        print("ROLL_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_y, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.ROLL_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_y, sym.parameter as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.ROLL_SUB:
        print("ROLL_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_y, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      //
      case Kind.PITCH_ADD:
        print("PITCH_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_x, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.PITCH_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_x, sym.parameter as double);
        // _last_axis.setEuler(sym.parameter as double, 0, 0);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.PITCH_SUB:
        print("PITCH_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_x, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      default:
        assert(false);
        val = 0.0;
    }
    _state[sym.field] = val;
  }
}

abstract class Plotter {
  void Init(State s);
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, State s);
  void Fini(State s);
}

String str(VM.Vector3 v) {
  return sprintf("v[%.2f %.2f %.2f]:%.2f", [v.x, v.y, v.z, v.length]);
}

String qstr(VM.Quaternion q) {
  return sprintf("q[%.2f %.2f %.2f %.2f]:%.2f", [q.w, q.x, q.y, q.z, q.length]);
}

void applyQuaternion(VM.Vector3 v, VM.Quaternion q) {
  final vx = v.x;
  final vy = v.y;
  final vz = v.z;
  final qx = q.x;
  final qy = q.y;
  final qz = q.z;
  final qw = q.w;

  final tx = 2 * (qy * vz - qz * vy);
  final ty = 2 * (qz * vx - qx * vz);
  final tz = 2 * (qx * vy - qy * vx);

  v.x = vx + qw * tx + qy * tz - qz * ty;
  v.y = vy + qw * ty + qz * tx - qx * tz;
  v.z = vz + qw * tz + qx * ty - qy * tx;
}

void RenderOne(Sym s, List<State> stack, Plotter plotter) {
  switch (s.kind) {
    case Kind.SET_CONST:
    case Kind.ADD_CONST:
    case Kind.YAW_ADD_CONST:
    case Kind.ROLL_ADD_CONST:
    case Kind.PITCH_ADD_CONST:
    case Kind.MUL_CONST:
    case Kind.SUB:
    case Kind.ADD:
    case Kind.YAW_SUB:
    case Kind.YAW_ADD:
    case Kind.ROLL_SUB:
    case Kind.ROLL_ADD:
    case Kind.PITCH_SUB:
    case Kind.PITCH_ADD:
    case Kind.MUL:
    case Kind.GROW:
    case Kind.SHRINK:
      stack.last.Update(s);
    //
    case Kind.STACK_PUSH:
      print("@@@@@ PUSH");
      stack.add(stack.last.Clone());
    case Kind.STACK_POP:
      print("@@@@@ POP");
      stack.removeLast();
    case Kind.POLY_START:
      assert(false);
    case Kind.POLY_END:
      assert(false);
    case Kind.SYMBOL:
      var state = stack.last;
      VM.Vector3 src = state.get(xPos);
      double step_size = state.get(xStepSize);
      VM.Quaternion dir = state.get(xDir);
      VM.Vector3 dst = VM.Vector3(0, step_size, 0);
      //applyQuaternion(dst, dir);
      dst.applyQuaternion(dir);
      // dir.rotate(dst);
      // print("Rule dir: ${qstr(dir)} ${str(dst)}");
      dst.add(src);
      if (s.text != "f") {
        print("@@@@@ DRAW");
        plotter.Draw(src, dst, dir, stack.last);
      }
      state.set(xPos, dst);
    case Kind.INVALID:
      assert(false);
  }
}

void RenderAll(List<SymIndex> startup, List<SymIndex> main, Plotter plotter) {
  List<State> stack = [State()..Init()];
  for (SymIndex i in startup) {
    Sym s = Sym.GetSymbolForIndex(i);
    RenderOne(s, stack, plotter);
  }

  plotter.Init(stack.last);
  for (SymIndex i in main) {
    Sym s = Sym.GetSymbolForIndex(i);
    RenderOne(s, stack, plotter);
  }
  plotter.Fini(stack.last);
}

// Statistics about a pattern
class PatternInfo {
  int length = 0;
  int nesting_depth = 0;
  int stack_pushes = 0;
  int line_count = 0;

  PatternInfo(List<SymIndex> pattern) {
    length = pattern.length;
    int curr = 0;
    for (SymIndex i in pattern) {
      Sym s = Sym.GetSymbolForIndex(i);
      if (s.kind == Kind.STACK_PUSH) {
        ++stack_pushes;
        ++curr;
        if (curr > nesting_depth) nesting_depth = curr;
      }
      if (s.kind == Kind.STACK_POP) {
        --curr;
      }
      if (s.kind == Kind.SYMBOL && s.text != "f") {
        ++line_count;
      }
    }
  }

  @override
  String toString() {
    return "length:${length} lines:${line_count} pushes:${stack_pushes} depth:${nesting_depth}";
  }
}
