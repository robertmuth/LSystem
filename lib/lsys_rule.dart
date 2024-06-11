// L-System engine code
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' as VM;

import 'package:sprintf/sprintf.dart';

enum Kind {
  INVALID,
  // operations with an immediate value
  SET_CONST,
  ADD_CONST,
  MUL_CONST,
  // operations with a stored value
  SUB,
  ADD,
  MUL,
  //  apply gravity to current direction, i.e. pull it down a little
  GRAVITY_CONST,
  //
  YAW_ADD,
  YAW_SUB,
  YAW_ADD_CONST,
  //
  ROLL_ADD,
  ROLL_SUB,
  ROLL_ADD_CONST,
  //
  PITCH_ADD,
  PITCH_SUB,
  PITCH_ADD_CONST,
  //
  GROW,
  SHRINK,
  // move forward without side-effect
  SYMBOL,
  // move forward and either draw a line or record a vertex on a surface
  ACTIVE_SYMBOL,
  // push current state on stack
  STACK_PUSH,
  STACK_POP,
  // Start a surface
  POLY_START,
  POLY_END,
  //
  COLOR_NEXT,
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
    print("Register parameter [${name}]");
    var d = ParamDescriptor(gNumDescriptors, name, ctor, cloner);
    ++gNumDescriptors;
    gAllDescriptors.add(d);
    return d.num;
  }

  static GetIndexByName(String name) {
    for (int i = 0; i < gAllDescriptors.length; ++i) {
      if (name == gAllDescriptors[i].name) {
        return i;
      }
    }
    print(">>>>>>>>>>>>>>>>> [${name}]");
    assert(false, "unknown parameter [${name}]");
    return -1;
  }
}

int xPos = -1;
int xDir = -1;
int xStepSize = -1;
int xAngleStep = -1;
int xWidth = -1;
int xBackgroundColor = -1;
int xLineColor = -1;

// Must be called at startup
void RegisterStandardParams() {
  print("RegisterStandardParams");
  xPos = ParamDescriptor.Register("#pos", () => VM.Vector3.zero(), (x) => x.clone());
  xDir = ParamDescriptor.Register("#dir", () => VM.Quaternion.identity(), (x) => x.clone());
  xStepSize = ParamDescriptor.Register("#stepSize", () => 0.0, (x) => x);
  xAngleStep = ParamDescriptor.Register("#angleStep", () => 0.0, (x) => x);
  xWidth = ParamDescriptor.Register("#width", () => 0.0, (x) => x);
  xBackgroundColor = ParamDescriptor.Register("#bgColor", () => "", (x) => x);
  xLineColor = ParamDescriptor.Register("#lineColor", () => "", (x) => x);
}

bool KindIsParameter(Kind k) {
  return (Kind.SET_CONST as int) <= (k as int) && (k as int) <= (Kind.SHRINK as int);
}

// Since there are only very few unique tokens we intern them and use
// this index to refer to them
typedef TokenIndex = int;
List<Token> gTokenPool = [];

// Represents on component of a L-System rule
class Token {
  Kind kind;
  String text = "";
  int field = -1;
  dynamic parameter = null;

  Token(this.kind, [this.text = "", this.field = -1, this.parameter = null]);

  static TokenIndex GetIndexForSymbo(Token sym) {
    for (int i = 0; i < gTokenPool.length; ++i) {
      if (gTokenPool[i] == sym) return (i << 8) + sym.kind.index;
    }
    gTokenPool.add(sym);
    return ((gTokenPool.length - 1) << 8) + sym.kind.index;
  }

  static Token GetSymbolForIndex(TokenIndex i) {
    return gTokenPool[i >> 8];
  }

  static TokenIndex Simple(Kind kind) {
    return GetIndexForSymbo(Token(kind));
  }

  static TokenIndex Symbol(String text) {
    return GetIndexForSymbo(Token(Kind.SYMBOL, text));
  }

  static TokenIndex ActiveSymbol(String text) {
    return GetIndexForSymbo(Token(Kind.ACTIVE_SYMBOL, text));
  }

  static TokenIndex Param(Kind kind, int name, dynamic parameter) {
    return GetIndexForSymbo(
        Token(kind, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  static TokenIndex SetParam(int name, dynamic parameter) {
    return GetIndexForSymbo(
        Token(Kind.SET_CONST, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  static TokenIndex AddParam(int name, dynamic parameter) {
    return GetIndexForSymbo(
        Token(Kind.ADD_CONST, ParamDescriptor.gAllDescriptors[name].name, name, parameter));
  }

  @override
  bool operator ==(Object o) {
    Token other = o as Token;
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
      case Kind.GRAVITY_CONST:
      case Kind.YAW_ADD_CONST:
      case Kind.ROLL_ADD_CONST:
      case Kind.PITCH_ADD_CONST:
        return "(${kind.name} ${text} ${parameter})";
      case Kind.SUB:
      case Kind.ADD:
      case Kind.MUL:
      case Kind.YAW_ADD:
      case Kind.YAW_SUB:
      case Kind.ROLL_ADD:
      case Kind.ROLL_SUB:
      case Kind.PITCH_ADD:
      case Kind.PITCH_SUB:
        return "(${kind.name} ${text} ${parameter})";
      case Kind.SYMBOL:
        return "[${text}]";
      case Kind.ACTIVE_SYMBOL:
        return "[!${text}]";
      //
      case Kind.INVALID:
      case Kind.COLOR_NEXT:
      case Kind.STACK_PUSH:
      case Kind.STACK_POP:
      case Kind.POLY_START:
      case Kind.POLY_END:
        return "${kind.name}";
    }
  }
}

String StringifySymIndexList(List<TokenIndex> syms) {
  List<String> rhs = [];
  for (TokenIndex i in syms) {
    rhs.add("${Token.GetSymbolForIndex(i)}");
  }
  return rhs.join(" ");
}

class Rule {
  String head;
  List<TokenIndex> expansion;

  Rule(this.head, this.expansion);

  @override
  String toString() {
    return "${head} -> ${StringifySymIndexList(expansion)}";
  }
}

List<TokenIndex> ExpandOneStep(
    List<TokenIndex> input, Map<String, List<Rule>> rules, Math.Random rng) {
  final start = DateTime.now();
  List<TokenIndex> out = [];
  for (TokenIndex i in input) {
    Kind kind = Kind.values[i & 0xff];
    if (kind != Kind.SYMBOL && kind != Kind.ACTIVE_SYMBOL) {
      out.add(i);
      continue;
    }
    Token s = Token.GetSymbolForIndex(i);

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

/*
void EulerFromQuaternion(VM.Quaternion q, VM.Vector3 euler) {
  double t0 = 2.0 * (q.w * q.x + q.y * q.z);
  double t1 = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
  double roll_x = Math.atan2(t0, t1);

  double t2 = 2.0 * (q.w * q.y - q.z * q.x);
  t2 = (t2 > 1.0) ? 1.0 : t2;
  t2 = (t2 < -1.0) ? -1.0 : t2;
  double pitch_y = Math.asin(t2);

  double t3 = 2.0 * (q.w * q.z + q.x * q.y);
  double t4 = 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
  double yaw_z = Math.atan2(t3, t4);

  euler.setValues(roll_x, pitch_y, yaw_z);
}
*/

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
      _state.add(Null);
    }
  }

  // Shallow copy! Relies on Update() to be copy on write.
  State Clone() {
    return State().._state = List.from(_state);
  }

  void set(int key, dynamic val) {
    _state[key] = val;
  }

  void Update(Token sym) {
    // print("@@@@@ UPDATE ${sym}");
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
      case Kind.GRAVITY_CONST:
        _tmp_rot.setAxisAngle(_axis_x, sym.parameter);
        val = _tmp_rot * (_state[sym.field]! as VM.Quaternion);
      //
      case Kind.YAW_ADD:
        // print("YAW_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_z, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.YAW_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_z, sym.parameter as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.YAW_SUB:
        // print("YAW_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_z, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      //
      case Kind.ROLL_ADD:
        // print("ROLL_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_y, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.ROLL_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_y, sym.parameter as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.ROLL_SUB:
        // print("ROLL_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_y, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      //
      case Kind.PITCH_ADD:
        // print("PITCH_ADD ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_x, _state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.PITCH_ADD_CONST:
        _tmp_rot.setAxisAngle(_axis_x, sym.parameter as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      case Kind.PITCH_SUB:
        // print("PITCH_SUB ${_state[sym.parameter]!}");
        _tmp_rot.setAxisAngle(_axis_x, -_state[sym.parameter]! as double);
        val = (_state[sym.field]! as VM.Quaternion) * _tmp_rot;
      default:
        assert(false);
        val = 0.0;
    }
    _state[sym.field] = val;
  }
}

// Interface to render a Symbol String
// Protocol is:
// Init [Draw | [PolyStart PolyPoint+ PolyEnd]]+ Fini
abstract class Plotter {
  void Init(State s);
  // Draw a line
  void Draw(VM.Vector3 src, VM.Vector3 dst, VM.Quaternion dir, State s);
  // Start of a surface
  void PolyStart(State s);
  // Point of a surface
  void PolyPoint(VM.Vector3 dst, State s);
  // End of a surface
  void PolyEnd(State s);
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

// Render a Symbol String (derived from an L-System) using the Plotter
void RenderAll(List<TokenIndex> startup, List<TokenIndex> main, Plotter plotter) {
  List<State> stack = [State()..Init()];
  for (TokenIndex i in startup) {
    Token s = Token.GetSymbolForIndex(i);
    stack.last.Update(s);
  }

  bool in_polygon = false;
  plotter.Init(stack.last);
  for (TokenIndex i in main) {
    Token s = Token.GetSymbolForIndex(i);
    switch (s.kind) {
      case Kind.SYMBOL:
        break;
      case Kind.ACTIVE_SYMBOL:
        var state = stack.last;
        VM.Vector3 src = state.get(xPos);
        if (s.text == ".") {
          assert(in_polygon);
          plotter.PolyPoint(src, state);
          continue;
        }

        double step_size = state.get(xStepSize);
        VM.Quaternion dir = state.get(xDir);
        VM.Vector3 dst = VM.Vector3(0, step_size, 0);
        //applyQuaternion(dst, dir);
        dst.applyQuaternion(dir);
        // dir.rotate(dst);
        // print("Rule dir: ${qstr(dir)} ${str(dst)}");
        dst.add(src);
        if (in_polygon) {
          if (s.text != "f") {
            plotter.PolyPoint(dst, stack.last);
          }
        } else {
          if (s.text != "f") {
            // print("@@@@@ DRAW");
            plotter.Draw(src, dst, dir, stack.last);
          }
        }
        state.set(xPos, dst);
      case Kind.POLY_START:
        // print("@@@@@ POLY-START");
        assert(!in_polygon);
        in_polygon = true;
        plotter.PolyStart(stack.last);
      case Kind.POLY_END:
        // print("@@@@@ POLY-END");
        assert(in_polygon);
        in_polygon = false;
        plotter.PolyEnd(stack.last);
      case Kind.STACK_PUSH:
        // print("@@@@@ PUSH");
        stack.add(stack.last.Clone());
      case Kind.STACK_POP:
        // print("@@@@@ POP");
        stack.removeLast();
      case Kind.INVALID:
        assert(false);
      case Kind.COLOR_NEXT:
        break;
      case Kind.SET_CONST:
      case Kind.ADD_CONST:
      case Kind.GRAVITY_CONST:
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
    }
  }
  plotter.Fini(stack.last);
}

// Statistics about a pattern
class PatternInfo {
  int length = 0;
  int nesting_depth = 0;
  int stack_pushes = 0;
  int line_count = 0;

  PatternInfo(List<TokenIndex> pattern) {
    length = pattern.length;
    int curr = 0;
    for (TokenIndex i in pattern) {
      Token s = Token.GetSymbolForIndex(i);
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
