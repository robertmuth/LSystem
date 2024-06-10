import 'dart:core';
import 'package:lsystem/rule.dart' as rule;
import 'package:vector_math/vector_math.dart' as VM;
import 'dart:math' as Math;

/*
https://github.com/benvan/lsys
*/

/*
 All commands:

   F	         Move forward by line length drawing a line
   f	 xx      Move forward by line length without drawing a line
   +	         Turn left by turning angle
   -	         Turn right by turning angle
   |	         Reverse direction (ie: turn by 180 degrees)
   [	         Push current drawing state onto stack
   ]	         Pop current drawing state from the stack
   #	 xx      Increment the line width by line width increment
   !	  **     Decrement the line width by line width increment
   @	 xx    Draw a dot with line width radius
   {	 xx      Open a polygon
   }	 xx      Close a polygon and fill it with fill colour
   >	         Multiply the line length by the line length scale factor
   <	         Divide the line length by the line length scale factor
   &	  **     Swap the meaning of + and -
   (	         Decrement turning angle by turning angle increment
   )	         Increment turning angle by turning angle increment
*/

// Subset supported
Set<String> kValid = {
  "F", // draw forwards by [size]
  "+", "-", // rotate by +/-[angle]
  ">", "<", // increase/decrease [size] by [size-growth]
  ")", "(", // increase / decrease [angle] by [angle-growth]
  "[", "]", // push / pop state
  "!", // negate [angle]
  "|", // increment [angle] by 180;
};

final int xAngleGrowth = rule.ParamDescriptor.Register("angle_growth", () => 0.0, (x) => x);
final int xStepGrowth = rule.ParamDescriptor.Register("step_growth", () => 0.0, (x) => x);

// Symbols are those that appear on the left side of a rule
// (to the left of the colon)
Set<String> ExtractSymbols(List<String> rules) {
  Set<String> symbols = {};
  for (String r in rules) {
    if (r.startsWith("#")) continue;

    List<String> part = r.split(":");
    if (part.length == 0) continue;
    assert(part.length == 2, "bad rule ${part}");

    String left = part[0].trim();
    symbols.add(left);
  }
  return symbols;
}

List<rule.SymIndex> ExtractAxiom(List<String> rules) {
  for (String r in rules) {
    if (r.startsWith("#")) continue;
    List<String> part = r.split(":");
    if (part.length == 0) continue;
    assert(part.length == 2, "bad rule ${part}");
    var s = part[0].trim();
    if (s.length > 1) {
      return [rule.Sym.Symbol(s)];
    } else {
      return [rule.Sym.ActiveSymbol(s)];
    }
  }
  assert(false);
  return [];
}

rule.SymIndex TranslateToSym(String s) {
  switch (s) {
    case "!":
      return rule.Sym.Param(rule.Kind.MUL_CONST, rule.xAngleStep, -1.0);
    case "|":
      return rule.Sym.Param(rule.Kind.YAW_ADD_CONST, rule.xDir, Math.pi);
    case "+":
      return rule.Sym.Param(rule.Kind.YAW_ADD, rule.xDir, rule.xAngleStep);
    case "-":
      return rule.Sym.Param(rule.Kind.YAW_SUB, rule.xDir, rule.xAngleStep);
    case "^":
      return rule.Sym.Param(rule.Kind.PITCH_ADD, rule.xDir, rule.xAngleStep);
    case "_":
    case "&":
      return rule.Sym.Param(rule.Kind.PITCH_SUB, rule.xDir, rule.xAngleStep);
    case "/":
      return rule.Sym.Param(rule.Kind.ROLL_ADD, rule.xDir, rule.xAngleStep);
    case r"\":
      return rule.Sym.Param(rule.Kind.ROLL_SUB, rule.xDir, rule.xAngleStep);
    case "[":
      return rule.Sym.Simple(rule.Kind.STACK_PUSH);
    case "]":
      return rule.Sym.Simple(rule.Kind.STACK_POP);
    case "{":
      return rule.Sym.Simple(rule.Kind.POLY_START);
    case "}":
      return rule.Sym.Simple(rule.Kind.POLY_END);
    case "'":
      return rule.Sym.Simple(rule.Kind.COLOR_NEXT);
    case '<':
      return rule.Sym.Param(rule.Kind.GROW, rule.xStepSize, xStepGrowth);
    case '>':
      return rule.Sym.Param(rule.Kind.SHRINK, rule.xStepSize, xStepGrowth);
    case '(':
      return rule.Sym.Param(rule.Kind.SHRINK, rule.xAngleStep, xAngleGrowth);
    case ')':
      return rule.Sym.Param(rule.Kind.GROW, rule.xAngleStep, xAngleGrowth);
    default:
      print("unrecognized char [${s}]");
      assert(false);
      //assert("a" <= s && s <= "z");
      return rule.Sym.Symbol(s);
  }
}

bool IsIdChar(String s) {
  if (s == ".") return true;
  if ("a".compareTo(s) <= 0 && s.compareTo("z") <= 0) return true;
  if ("A".compareTo(s) <= 0 && s.compareTo("Z") <= 0) return true;

  return false;
}

enum ParseMode { REGULAR, ID, ESCAPE }

// input looks like: "F[+FF][-FF]F[-F][+F]F"
// where symbols is {L, F}
// output is a partition of the string where each symbol is isolated, e.g.:
// "F", "[+", "F", "F", "][", ...
List<rule.SymIndex> ParseRightSideOfProduction(String s, Set<String> symbols) {
  List<rule.SymIndex> out = [];

  String name = "";
  List<String> escape = [];

  ParseMode mode = ParseMode.REGULAR;

  for (int i = 0; i < s.length; i++) {
    String c = s[i];
    if (mode == ParseMode.ID) {
      if (IsIdChar(c)) {
        name += c;
        continue;
      } else {
        out.add(rule.Sym.Symbol(name));
        mode = ParseMode.REGULAR;
        // falls through
      }
    }
    switch (mode) {
      case ParseMode.REGULAR:
        if (c == " " || c == "\t" || c == "\n") {
          break;
        } else if (c == "\$") {
          mode = ParseMode.ID;
          name = c;
        } else if (c == "@") {
          mode = ParseMode.ESCAPE;
          escape.clear();
          escape.add("");
        } else if (IsIdChar(c)) {
          out.add(rule.Sym.ActiveSymbol(c));
        } else {
          out.add(TranslateToSym(c));
        }
      case ParseMode.ID:
        assert(false);
      case ParseMode.ESCAPE:
        if (c == ")") {
          if (escape[0] == "setrad") {
            int index = rule.ParamDescriptor.GetIndexByName(escape[1]);
            double val = double.parse(escape[2]) / 180.0 * Math.pi;
            out.add(rule.Sym.SetParam(index, val));
          } else if (escape[0] == "setstr") {
            int index = rule.ParamDescriptor.GetIndexByName(escape[1]);
            out.add(rule.Sym.SetParam(index, escape[2]));
          } else if (escape[0] == "setcol") {
            out.add(rule.Sym.SetParam(rule.xLineColor, escape[1]));
          } else {
            assert(false);
          }
          mode = ParseMode.REGULAR;
        } else if (c == "(" || c == ",") {
          escape.add("");
        } else {
          escape.last += c;
        }
    }
  }
  if (mode == ParseMode.ID) {
    out.add(rule.Sym.Symbol(name));
  }
  return out;
}

Map<String, List<rule.Rule>> ParseRules(List<String> rule_strs) {
  Set<String> symbols = ExtractSymbols(rule_strs);

  Map<String, List<rule.Rule>> out = {};
  for (String s in symbols) {
    out[s] = [];
  }
  for (String r in rule_strs) {
    if (r.startsWith("#")) continue;
    List<String> part = r.split(":");
    assert(part.length == 2);
    var head = part[0].trim();
    assert(head.length == 1 || head.startsWith("\$"));
    var expansion = ParseRightSideOfProduction(part[1].trim(), symbols);
    out[head]!.add(rule.Rule(head, expansion));
  }

  return out;
}

// Example config
// cleaned up rules from  https://github.com/benvan/lsys/blob/master/ticker.json
// Keys:
// "i" - number of iterations
// "r" - rules (start pattern is alwyas "L")
// "name" - name of pattenn
// "p.size" - tuple "parameter size" (value, growth)
// "p.angle" - tuple "parameter angle" (value, growth)
// "s.size" - tuple "sensitivity size" (value, growth)
// "s.angle" - tuple "sensitivity angle" (value, growth)
// "offsets" - optional triple "offset" (x, y, rotation)
/*
  {
    "i": "5",
    "r":
        "L:F++F++F++F++F; F: F++F++F|F-F++F",
    "p.size": "5,0.03",
    "p.angle": "36,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "Pentaplexity"
  }
*/

List<rule.SymIndex> InitPrefix(Map<String, String> desc, VM.Vector3 pos, VM.Quaternion dir) {
  List<rule.SymIndex> out = [];
  out.add(rule.Sym.Param(rule.Kind.SET_CONST, rule.xPos, pos));
  out.add(rule.Sym.Param(rule.Kind.SET_CONST, rule.xDir, dir));

  var size = desc["p.size"]!.split(",");
  assert(size.length >= 1, "${size}");
  out.add(rule.Sym.SetParam(rule.xStepSize, double.parse(size[0])));
  double size_growth = size.length > 1 ? double.parse(size[1]) : 0.01;
  out.add(rule.Sym.SetParam(xStepGrowth, size_growth));
  //
  var angle = desc["p.angle"]!.split(",");
  assert(angle.length >= 1);
  out.add(rule.Sym.SetParam(rule.xAngleStep, double.parse(angle[0]) / 180.0 * Math.pi));
  double angle_growth = angle.length > 1 ? double.parse(angle[1]) : 0.05;
  out.add(rule.Sym.SetParam(xAngleGrowth, angle_growth));
  //

  if (desc.containsKey("offsets")) {
    var offsets = desc["offsets"]!.split(",");
    assert(offsets.length == 3);
    out.add(rule.Sym.Param(rule.Kind.ADD_CONST, rule.xPos,
        VM.Vector3(double.parse(offsets[0]), double.parse(offsets[1]), 0.0)));
    out.add(rule.Sym.Param(
        rule.Kind.YAW_ADD_CONST, rule.xDir, double.parse(offsets[2]) / 180.0 * Math.pi));
  }
  return out;
}
