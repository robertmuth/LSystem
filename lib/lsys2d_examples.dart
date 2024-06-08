// cleaned up rules from  https://github.com/benvan/lsys/blob/master/ticker.json
// Keys:
// "i" - number of iterations
// "r" - rules (start pattern is alwyas "L")
// "name" - name of pattenn
// "p.size" - tuple "parameter size" (value, growth)
// "p.angle" - tuple "parameter angle" (value, growth)
// "s.size" - tuple "sensitivity ize" (value, growth)
// "s.angle" - tuple "sensitivity angle" (value, growth)
// "offsets" - optional triple "offset" (x, y, rotation)
List<Map<String, String>> kExamples = [
  {
    "i": "2",
    "r": r"""
$start: FF $flower;
$flower: {./[-F]/[--F]/[-F]/[--F]/[-F]/[--F]/[-F]/[--F]/[-F]/[--F]/[-F]}
""",
    "p.size": "10,0.01",
    "p.angle": "36,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "cone-flower-10leaves"
  },
  {
    "i": "3",
// flower from page 27
    "r": r"""
$start: FF $flower;
$flower: / $wedge //// $wedge //// $wedge //// $wedge //// $wedge;
$wedge: [' ^ F] [{ &&&& -f+f | -f+f }]
""",
    "p.size": "5,0.01",
    "p.angle": "18.0,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "plant-with-flowers"
  },
  {
    "i": "5",
// page 27
    "r": r"""
$plant: $internode + [$plant + $flower] -- // [-- $leaf] $internode [++ $leaf] - [$plant $flower] ++ $plant $flower;
$internode: F $seg [// & & $leaf] [// ^^ $leaf] F $seg;
$seg: $seg F $seg;
$leaf: [' { +f-ff-f+ | +f-ff-f } ];
$flower: [&&& $pedicel ' / $wedge //// $wedge //// $wedge //// $wedge //// $wedge];
$pedicel: FF;
$wedge: [' ^ F] [{ &&&& -f+f | -f+f }]
""",
    "p.size": "5,0.01",
    "p.angle": "18.0,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "plant-with-flowers"
  },
  {
    "i": "5",
    "r": r"""
A: [&FL!A]/////'[&FL!A]///////'[&FL!A];
F: S ///// F;
S: F L;
L: ['''^^{-f+f+f-|-f+f+f}]
""",
    "p.size": "10,0.01",
    "p.angle": "22.5,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "bush-with-leaves"
  },
  {
    "i": "1",
    "r": r"""
L: {-F+F+F-|-F+F+F}
""",
    "p.size": "10,0.01",
    "p.angle": "22.5,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "leaf"
  },
  {
    "i": "12",
    "r": r"""
L: EEEA;
A: [++++++++++++++EC]B^+B[--------------ED]B+BA;
C: [---------EE][+++++++++EE]B__+C;
D: [---------EE][+++++++++EE]B__-D
""",
    "p.size": "10,0.01",
    "p.angle": "4,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "fern"
  },
  {
    "i": "4",
    "r": r"""
A: /A[++A]-\A[--A]+//A
""",
    "p.size": "5,0.01",
    "p.angle": "18,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "vines"
  },
  {
    "i": "3",
    "r": """
L: [S]^[S]+[S];
S: [FFFFFF^F^F^F^F];
F: F
""",
    "p.size": "10,0.01",
    "p.angle": "90,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "axes"
  },
  {
    "i": "3",
    "r": r"""
A: ^\AB^\ABA-B^//ABA_B+//ABA-B/A-/
""",
    "p.size": "10,0.01",
    "p.angle": "90,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "hilbert3d"
  },
  {
    "i": "4",
    "r": """
L : BBBBBA;
A : [++BB[--C][++C][__C][^^C]A]/////+BBB[--C][++C][__C][^^C]A;
B: B;
B : \\\\B;
C :""",
    "p.size": "20,0.01",
    "p.angle": "18,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "tree"
  },
  {
    "i": "4",
    "r": r"""
L : B[+L]\\\\\\\\[+L]\\\\\\\\[+L]\\\\\\\\BL;
B : B\B;
B : L/B""",
    "p.size": "10,0.01",
    "p.angle": "30,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "plant"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S)s",
    "p.size": "7.55,0.01",
    "p.angle": "-2923010.4,0.05",
    "s.size": "8.8,7.6",
    "s.angle": "6.5,0",
    "offsets": "0,0,0",
    "name": "dandelion"
  },
  {
    "i": "30",
    "r": "L : S; S : F>+[F-Y[S]]F)G; Y :--[|F-F--FY]-; G: FGF[+F]+Y",
    "p.size": "4",
    "p.angle": "-3832.29,0.081453",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "re-coil"
  },
  {
    "i": "5", // was 5
    "r": "L:F++F++F++F++F; F: F++F++F|F-F++F",
    "p.size": "5,0.03",
    "p.angle": "36,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "Pentaplexity"
  },
  {
    "i": "6",
    "r": "L: F+XF+F+XF; X: XF-F+F-XF+F+XF-F+F-X",
    "p.size": "5,0.03",
    "p.angle": "90,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "Square Sierpinski"
  },
  {
    "i": "4",
    "r":
        "L: -YF; X: XFX-YF-YF+FX+FX-YF-YFFX+YF+FXFXYF-FX+YF+FXFX+YF-FXYF-YF-FX+FX+YFYF-; Y: +FXFX-YF-YF+FX+FXYF+FX-YFYF-FX-YF+FXYFYF-FX-YFFX+FX+YF-YF-FX+FX+YFY",
    "p.size": "5,0.03",
    "p.angle": "90,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "quadratic-gosper"
  },
  /*
    {
    "i": "6",
    "r": "L: F; F: F[+FF][-FF]F[-F][+F]F",
    "p.size": "5,0.03",
    "p.angle": "20,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "Saupe"
  },
  */
  {
    "i": "6",
    "r": "L: F; F: F[+FF][-FF]F[-F][+F]F",
    "p.size": "5,0.03",
    "p.angle": "35,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "burke"
  },
  {
    "i": "5",
    "r": "L: F; F: F+[+F-F-F]-[-F+F+F]",
    "p.size": "50,0.03",
    "p.angle": "22.5,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "burke2"
  },
  {
    "i": "6",
    "r": "L: XF; X: X+YF++YF-FX--FXFX-YF+; Y: -FX+YFYF++YF+FX--FX-Y",
    "p.size": "5,0.03",
    "p.angle": "60,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "hexagonal-gosper"
  },
  {
    "i": "6",
    "r": "L:  LFX[+L][-L];  X: X[-FFF][+FFF]FX",
    "p.size": "5,0.03",
    "p.angle": "25,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "hairy-bush"
  },
  /*
  {
    "i": "10",
    "r": "L: F[+x]Fb; F: >F<; b: F[-y]FL; x: L; y: b",
    "p.size": "20,0.36",
    "p.angle": "45,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "snowflake-bush"
  },
  */
  {
    "i": "6",
    "r": "L: F+F+F+F; F: FF+F-F+F+FF",
    "p.size": "3,0.05",
    "p.angle": "90,0.0",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "bush2"
  },
  {
    "i": "6",
    "r": "L: F[[L]+L]+F[+FL]-L; F: FF",
    "p.size": "2,0.05",
    "p.angle": "22.5,0.09",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "bush"
  },
  {
    "i": "5",
    "r": "L : F+F+F+F; F : F+F-F-FF+F+F-F",
    "p.size": "1,0.01",
    "p.angle": "90.0,0.09",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    //  "offsets": "0,105,90",
    "name": "text book"
  },
  {
    "i": "11",
    "r": "L : SSS; S : [F>[FF-YS]F)G]+; Y :--[F-)F-FG]-; G: FGF[Y+F]+Y",
    "p.size": "10.3943,0.010104",
    "p.angle": "-3731.69,0.052446",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "offsets": "18,23,0",
    "name": "the triffids"
  },
  {
    "i": "12",
    "r": "L : |-S!L!Y; S : [F[FF-YS]F)G]+; Y :--[F-)<F-FG]-; G: FGF[Y+>F]+Y",
    "p.size": "14.11,-1.359672",
    "p.angle": "-3963.7485,-0.138235",
    "s.size": "8.7,7.4",
    "s.angle": "7.7,4",
    "offsets": "0,105,90",
    "name": "tree horse"
  },
  {
    "i": "30",
    "r": "L : S; S : F+[F>-Y[S]]F)G; Y :--[|F-F--FY]-; G: FGF[+F]+Y",
    "p.size": "4",
    "p.angle": "-3869.97,0.115409",
    "s.size": "8.7,7.53",
    "s.angle": "7.7,4",
    "name": "flyweight"
  },
  {
    "i": "11",
    "r": "L : SYS; S : F-[F-Y[S]]; Y : [|FF[-((>S]+Y]",
    "p.size": "18.65,0.143333",
    "p.angle": "-3787.3,0.05",
    "s.size": "7.7,7.53",
    "s.angle": "7.7,4",
    "name": "ordered chaos"
  },
  {
    "i": "11",
    "r": "L : SSS; S : [F[FF-YS]F)G]+; Y :--[F-)<F-FG]-; G: FGF[Y+>F]+Y",
    "p.size": "10.8073435055357,-1.583229333333331",
    "p.angle": "-3479.67,-0.120579",
    "s.size": "8.7,7.4",
    "s.angle": "7.7,4",
    "offsets": "18,23,0",
    "name": "try force"
  },
  {
    "i": "40",
    "r": "L : [B]L; B : !A>FB)!A-; A : -AF+",
    "p.size": "4",
    "p.angle": "-2361.3,0.05",
    "s.size": "9,7",
    "s.angle": "7.31,2",
    "offsets": "0,100,0",
    "name": "metamorphosis"
  },
  {
    "i": "40",
    "r": "L : [B]VFL; B : A!B; A : F+A|-; V : XVY; X : <X; Y : >Y",
    "p.size": "11.61",
    "p.angle": "810,0.05",
    "s.size": "9,6.2",
    "s.angle": "7.6,4",
    "name": "pulse engine"
  },
  {
    "i": "30",
    "r": "L : S; S : F+>[F-Y[S]]F)G; Y :--[|F-F-FY]; G: FGY[+F]+Y",
    "p.size": "9,0.0001",
    "p.angle": "-3669.39,-0.055313",
    "s.size": "8.8,7.5",
    "s.angle": "7.6,4",
    "name": "pollenate"
  },
  {
    "i": "12",
    "r": "L : -|S!L!Y; S : [F[FF-YS]F)G]+; Y :--[F-)<F-FG]-; G: FGF[Y+>F]+Y",
    "p.size": "35.36,-1.339577",
    "p.angle": "-3783.1476,-0.506196",
    "s.size": "8.7,7.4",
    "s.angle": "7.7,4",
    "offsets": "-5,127,90",
    "name": "the park at night"
  },
  {
    "i": "33",
    "r": "L : S!|VFFL; S : F!++[F-YAS]; A : F->|A!; V : XVY; X : -; Y : !-",
    "p.size": "6.19,0",
    "p.angle": "-4055.8,0.05",
    "s.size": "8.3,6",
    "s.angle": "7.6,4",
    "name": "leviathon"
  },
  {
    "i": "30",
    "r": "L : CCC; C : !<[)B|VFC]; B : A|BF!; A : F|-A|+F; V : +",
    "p.size": "2.23,0.01",
    "p.angle": "-3197.02,0.0599906133",
    "s.size": "7.7,6.53",
    "s.angle": "7.7,0",
    "name": "spindlethrift"
  },
  {
    "i": "30",
    "r": "L : B|FL; B : A!<B; A : F---A|+",
    "p.size": "16.08,0",
    "p.angle": "-660,0.05",
    "s.size": "8.7,5",
    "s.angle": "7.6,4",
    "offsets": "37,65,0",
    "name": "the DNA dance"
  },
  {
    "i": "33",
    "r": "L : S!|VFFL; S : F!+(+[F-Y>AS]; A : F-|A!; V : XVY; X : -; Y : !-",
    "p.size": "6.19,0",
    "p.angle": "-3965.57,0.037884",
    "s.size": "7.7,6.7",
    "s.angle": "7.5,3",
    "name": "synchronised swarming"
  },
  {
    "i": "30",
    "r": "L : B|>FL; B : A!B; A : F+++|A|+F",
    "p.size": "6.27,0.01876",
    "p.angle": "-1442.6,0.05",
    "s.size": "8.8,7",
    "s.angle": "7.6,4",
    "name": "snake charmer"
  },
  {
    "i": "40",
    "r": "L : [B]F|L; B : !AB)!A-F; A : -A>F+",
    "p.size": "8.15,0",
    "p.angle": "-1255.5,0.05",
    "s.size": "8.7,6.5",
    "s.angle": "7.6,4",
    "name": "dance for me"
  },
  {
    "i": "40",
    "r": "L : [B]FL; B : !A>)BA; A : AF-",
    "p.size": "6.6",
    "p.angle": "285.22,0.050965",
    "s.size": "8.3,6",
    "s.angle": "7.6,4",
    "name": "bubble trouble"
  },
  {
    "i": "44",
    "r": "L : B|VFL; B : A!BF!; A : F|-A|+F; V : !<<-",
    "p.size": "1,0.01",
    "p.angle": "-1429.08,0.055765",
    "s.size": "7.7,6",
    "s.angle": "7.6,4",
    "name": "wormly"
  },
  {
    "i": "100",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [|F-F+(+FY]+<",
    "p.size": "11.97,0.01",
    "p.angle": "659.72,0.050257",
    "s.size": "8.7,6",
    "s.angle": "7.6,4",
    "name": "slamurai"
  },
  {
    "i": "31",
    "r": "L : SYS; S : >-|[F>-Y[>S]]!; Y : [|F>FF-F+)Y]",
    "p.size": "71.19,0.01",
    "p.angle": "13,0.05",
    "s.size": "9.4,6",
    "s.angle": "7.6,4",
    "name": "crystal orchid"
  },
  {
    "i": "200",
    "r": "L : SSSSSS; S : >|+[F[S]]|",
    "p.size": "188.94,0.01",
    "p.angle": "-3179.7,0.05",
    "s.size": "9.8,5.6",
    "s.angle": "7.6,4",
    "name": "platterstar"
  },
  {
    "i": "30",
    "r": "L : CCC; C : ![B>|VFC]; B : A|BF!; A : F|-A|+F; V : +",
    "p.size": "2.23,0",
    "p.angle": "-3079.65,0.046089",
    "s.size": "7.7,6",
    "s.angle": "7.7,4",
    "name": "close encounters"
  },
  {
    "i": "12",
    "r": "L : F-[F-Y[L]]; Y : L|[|F>-F+)Y]",
    "p.size": "14.46,0",
    "p.angle": "-3259.1,0.05",
    "s.size": "9,7.53",
    "s.angle": "7.6,4",
    "name": "heisenberg"
  },
  {
    "i": "12",
    "r": "L : SS; S : F-[F-Y[S>(L]]; Y : [-|F-F+)Y]",
    "p.size": "16.37,0.01",
    "p.angle": "9840.1,0.05",
    "s.size": "9,7.53",
    "s.angle": "7.6,4",
    "name": "trigon"
  },
  {
    "i": "40",
    "r": "L : LB; B : !A[F>B]!A-; A : -AF+",
    "p.size": "5.31,0",
    "p.angle": "-1972.4,0.05",
    "s.size": "8.4,6.4",
    "s.angle": "7.6,4",
    "name": "spirocopter"
  },
  {
    "i": "33",
    "r": "L : S!|VFFL; S : F!+>+[F-YS]; Y : [F-FA+Y]; A : F->--A|+; V : XVY; X : -; Y : !",
    "p.size": "23.82,0.01",
    "p.angle": "-2040,0.05",
    "s.size": "9,7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "kinetica"
  },
  {
    "i": "30",
    "r": "L : S; S : F|+[F-Y[S]]FG; Y :--[|F-F+|+FY]+; G: FGF>[+F]Y",
    "p.size": "6.03,0.01",
    "p.angle": "-1705.7,0.05",
    "s.size": "8.5,6.5",
    "s.angle": "7.6,4",
    "name": "johnny lee"
  },
  {
    "i": "44",
    "r": "L : B|VFL; B : A!BF; A : F|-A|+F; V : <<<<+",
    "p.size": "2.46,0.01",
    "p.angle": "-3224.9,0.05",
    "s.size": "8.2,6",
    "s.angle": "7.6,4",
    "name": "angel flight"
  },
  {
    "i": "44",
    "r": "L : B|VFL; B : ABF; A : F|-A|+F; V : <<<<<+",
    "p.size": "2.23,0.01",
    "p.angle": "-3275.2,0.05",
    "s.size": "8,5.5",
    "s.angle": "7.6,4",
    "offsets": "0,86,0",
    "name": "stargaze"
  },
  {
    "i": "44",
    "r": "L : B|VFL; B : A!BF; A : F|-A|+F; V : >",
    "p.size": "4",
    "p.angle": "-1793.1,0.05",
    "s.size": "8,6.5",
    "s.angle": "7.6,4",
    "offsets": "0,134,0",
    "name": "mortal coil"
  },
  {
    "i": "30",
    "r": "L : C|CC|C; C : ![>(B|VFC]; B : A|BF!; A : F|-A|+F; V : +",
    "p.size": "2.23,0.01",
    "p.angle": "-5535.03,0.2526636383",
    "s.size": "7.9,6.3",
    "s.angle": "7.7,4",
    "name": "house rules"
  },
  {
    "i": "80",
    "r": "L : SSS; S : >F|+[F)Y[S]]; Y : F[-F--|FY]+!",
    "p.size": "7.21",
    "p.angle": "-1746.6,0.000347",
    "s.size": "8.4,6",
    "s.angle": "7.6,4",
    "name": "flagella"
  },
  {
    "i": "33",
    "r": "L : S!|VFFL; S : F!+>+[F-YAS]; A : F-A|+; V : XVY; X : -; Y : !-",
    "p.size": "6.39,0.01",
    "p.angle": "-2340.6,0.05",
    "s.size": "8.8,7.5",
    "s.angle": "7.6,4",
    "name": "jamiroquai | rippletwist"
  },
  {
    "i": "200",
    "r": "L : SSSSS; S : >|+[F[S]]",
    "p.size": "199.9,0.01",
    "p.angle": "-3276.3,0.05",
    "s.size": "9.9,5.5",
    "s.angle": "7.6,4",
    "name": "coalescence"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F-[F->Y[S]]; Y : [|F-F+)Y]",
    "p.size": "16.34,0.01",
    "p.angle": "-3243.4,0.05",
    "s.size": "8.8,7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "3d tusk / gearspin"
  },
  {
    "i": "31",
    "r": "L : S; S : F<+[F-Y[S]]; Y : [|F-F+)Y]",
    "p.size": "5.62,0.01",
    "p.angle": "-2519.1,0.05",
    "s.size": "8.6,7.53",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "single 3d blade"
  },
  {
    "i": "20",
    "r": "L : S; S : >F|+[F-Y[S]]; Y : [|F-F)+Y]",
    "p.size": "91.21,0.01",
    "p.angle": "-137.8,0.05",
    "s.size": "9.8,6.8",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "3d rollers 2"
  },
  {
    "i": "31",
    "r": "L : S)S)S)S)S; S : F+[F-Y[+S]]; Y : [|F<-F+)Y]",
    "p.size": "11.61,0.01",
    "p.angle": "-901.4,0.05",
    "s.size": "8.7,7.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "battling dragon tails"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [|F-F+)F>Y]+",
    "p.size": "11.74,0.01",
    "p.angle": "-1251.1,0.05",
    "s.size": "8.8,7.2",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "snapdragon"
  },
  {
    "i": "100",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [-F-F+)FY]>+",
    "p.size": "7.66,0",
    "p.angle": "-2107.9,0.05",
    "s.size": "9,6",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "dragon spirograph"
  },
  {
    "i": "15",
    "r":
        "L : +S.T.A.R.T.>>L; S : [4-2-4+2+4]; T : [2-4[-2][+2]]; A : [-4+4+2[+4]2]; R : [-4+4+2+F[-2]3]; . : 4F2; 4 : FFFF; 3 : FFF; 2 : FF",
    "p.size": "5,0.071",
    "p.angle": "-270,0.00644",
    "s.size": "8.4,6.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "S.T.A.R.T"
  },
  {
    "i": "100",
    "r": "L : SYS; S : F|+[F->Y[S]]; Y : [--((F-F+)FY]+",
    "p.size": "2.28,0",
    "p.angle": "-2341.8,0.05",
    "s.size": "8,6.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "gemini"
  },
  {
    "i": "40",
    "r": "L : [B]<F|L; B : !AB!A-F; A : -AF+",
    "p.size": "9.86,0.01",
    "p.angle": "-192.8,0.05",
    "s.size": "8.4,6.8",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "clockwork coil"
  },
  {
    "i": "31",
    "r": "L : SYS; S : -|[F<-Y[S]]+; Y : [|FFF-F>+)Y]",
    "p.size": "20.38,0.01",
    "p.angle": "95.4,0.05",
    "s.size": "8.9,6.8",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "number 8"
  },
  {
    "i": "31",
    "r": "L : SYS; S : >-|[F>-Y[>S]]!; Y : [|F>!FF-F+)Y]",
    "p.size": "9.44,0.01",
    "p.angle": "88.4,0.05",
    "s.size": "8.8,7.7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "wigglesaur"
  },
  {
    "i": "70",
    "r": "L : SYS; S : >-|[+F>-Y[>S]]!; Y : [|F>!FF-F+)Y]",
    "p.size": "16.12,0.01",
    "p.angle": "907.4,0.05",
    "s.size": "8.9,6.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "I mustache you a question"
  },
  {
    "i": "50",
    "r": "L : SYS; S : >-|[+F>-Y>[>S]]!; Y : [|F>!F)F-F+)Y]",
    "p.size": "9.5,0.01",
    "p.angle": "3052.7,0.05",
    "s.size": "8.9,6.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "twizzlestache"
  },
  {
    "i": "41",
    "r": "L : SYSYSYS; S : F-[F-Y[S++F>FF[+F+F]]; Y : F[|F!F>+Y]-F",
    "p.size": "3.22,0.01",
    "p.angle": "-2399.6,0.05",
    "s.size": "8.7,7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "samurai"
  },
  {
    "i": "41",
    "r": "L : SYL; S : F->[F-Y[S++FFF[+F+F]]; Y : F[|F!F+<Y]-F",
    "p.size": "3.28,0",
    "p.angle": "-2756.2,0.05",
    "s.size": "8,5.7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "dragonfish"
  },
  {
    "i": "32",
    "r": "L : SLY; S : F-[F!Y[S++FF<F[+F+F]]; Y : F[|F!<F+Y]-F",
    "p.size": "4,0.01",
    "p.angle": "-1342.1,0.05",
    "s.size": "8,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "3d pyramids"
  },
  {
    "i": "100",
    "r": "L : SYS; S : F|+[F->Y[S]]; Y : [|F-F++FY]+)",
    "p.size": "10.28,0",
    "p.angle": "179.3,0.05",
    "s.size": "8.5,6.6",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "holy shit!"
  },
  {
    "i": "80",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [|F->F++FY]+(!",
    "p.size": "13.81,0",
    "p.angle": "-87.1,0.05",
    "s.size": "8.6,6.4",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "the bomb"
  },
  {
    "i": "80",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [|F->F--FY]+(!",
    "p.size": "5.4,0",
    "p.angle": "-1563.3,0.05",
    "s.size": "9,6",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "ornate clock"
  },
  {
    "i": "80",
    "r": "L : S; S : >F|+[F-Y[S]]; Y : [|F-F--|FY]+!",
    "p.size": "4,0.01",
    "p.angle": "-2279.4,0.05",
    "s.size": "8.3,6.8",
    "s.angle": "7.6,4",
    "offsets": "-80,100,0",
    "name": "manta ray"
  },
  {
    "i": "80",
    "r": "L : SSS; S : >F|+[F-Y[S]]; Y : F[-F--|FY]+!",
    "p.size": "1.47,0.01",
    "p.angle": "-2819.5,0.05",
    "s.size": "8,6.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "biohazard angel"
  },
  {
    "i": "40",
    "r": "L : [B]F<L; B : !A>BA; A : -AF-",
    "p.size": "6.6,0.01",
    "p.angle": "-480.2,0.05",
    "s.size": "8.7,7.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "twistmas tree"
  },
  {
    "i": "80",
    "r": "L : SSS; S : >F|+[FY[S]]; Y : F[-F--|FY]+!",
    "p.size": "7.21,0.01",
    "p.angle": "-3185.1,0.05",
    "s.size": "8.5,6",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "choose your tunnel"
  },
  {
    "i": "80",
    "r": "L : SSSS; S : >F|+[FY[S]]; Y : F[-F--|Y]+",
    "p.size": "9.03,0.01",
    "p.angle": "-3686.8,0.05",
    "s.size": "8.4,6.2",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "clover"
  },
  {
    "i": "60",
    "r": "L : SSS; S : >F|)+[FY[S]]; Y : F[-F--FY]+!F",
    "p.size": "14.49,0.01",
    "p.angle": "56.6,0.05",
    "s.size": "8.8,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "trifecta"
  },
  {
    "i": "14",
    "r": "L : S; S : >F|+[FYS]; Y : F[-F-FY]+!Y",
    "p.size": "6.96,0.01",
    "p.angle": "-180,0.05",
    "s.size": "9,7.53",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "fire!"
  },
  {
    "i": "14",
    "r": "L : S; S : >)F|+[FYS]; Y : F[-F-FY]+!Y",
    "p.size": "8.51,0.01",
    "p.angle": "1203.5,0.05",
    "s.size": "8.7,7.53",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "birds"
  },
  {
    "i": "14",
    "r": "L : S; S : <T-F|+[YS]; Y : F[-|Y]+!Y; T : ))))))+++((((((",
    "name": "brainchild",
    "p.size": "14.62",
    "s.size": "8.80",
    "p.angle": "901.5"
  },
  {
    "i": "8",
    "r": "L : FFFS[+L][-L]FL; S : >S)",
    "p.size": "9.31,0.01",
    "p.angle": "-289.8,0.05",
    "s.size": "9,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "rorschach test"
  },
  {
    "i": "9",
    "r": "L : FFFS[+L][-L]FL; S : >S)",
    "p.size": "10.11,0.01",
    "p.angle": "-652.6,0.05",
    "s.size": "9,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "beating heart (wiggle mouse)"
  },
  {
    "i": "9",
    "r": "L : FFFS[+L][-L]FL; S : >S)",
    "p.size": "10.94,0.01",
    "p.angle": "-1305.4,0.05",
    "s.size": "8.8,7.7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "needle in a haystack"
  },
  {
    "i": "9",
    "r": "L : FFFS[+L][-L]FL; S : >S)S",
    "p.size": "6.6,0.01",
    "p.angle": "-3164.2,0.05",
    "s.size": "9,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "king of the jungle"
  },
  {
    "i": "9",
    "r": "L : FFFS[+L][-L]L; S : >S)S",
    "p.size": "9.99,0.01",
    "p.angle": "-3241.5,0.05",
    "s.size": "8.6,6.3",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "amoeba"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S))",
    "p.size": "9.74,0.01",
    "p.angle": "-1194.6,0.05",
    "s.size": "9,6.2",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "the grinch in a christmas hat..."
  },
  {
    "i": "9",
    "r": "L : FFFS[+L][-L]FL; S : >>>S))))",
    "p.size": "8.93,0.01",
    "p.angle": "-1243.2,0.05",
    "s.size": "8.8,5.7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "cthulu's daughter"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S))))",
    "p.size": "29.68,0.058",
    "p.angle": "-1345.1,0.05",
    "s.size": "9.4,6.3",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "trippy"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S))))",
    "p.size": "29.62,0.058",
    "p.angle": "-1346.6,0.05",
    "s.size": "9.4,6.3",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "mandelbutt"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S))))",
    "p.size": "29.24,0.058",
    "p.angle": "-1358,0.05",
    "s.size": "9.4,6.6",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "tree!"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >>>>>>S))))",
    "name": "freaky face",
    "p.size": "29.3",
    "s.size": "9.40",
    "p.angle": "-1373.3"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S))))",
    "p.size": "30,0.058",
    "p.angle": "-1406.9,0.05",
    "s.size": "9,6.2",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "stardust"
  },
  {
    "i": "8",
    "r": "L : FFFS[+L][-L]FL; S : >L))))",
    "p.size": "1.58,0.01",
    "p.angle": "-1817.5,0.05",
    "s.size": "8,6.88",
    "s.angle": "7.6,4",
    "offsets": "0,100,0",
    "name": "clockwork"
  },
  {
    "i": "8",
    "r": "L : FFFS[+L][-L]FLM; S : >L|>; M: )))))+(((((",
    "p.size": "5.56,0.01",
    "p.angle": "-1441.2,0.05",
    "s.size": "8.6,6",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "helicopter plant (drag left)"
  },
  {
    "i": "10",
    "r": "L : FFFS[+L][-L]FL; S : >S)",
    "p.size": "5.66,0.01",
    "p.angle": "-926.5,0.05",
    "s.size": "8.3,6.2",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "shaman face"
  },
  {
    "i": "100",
    "r": "L : SYS; S : F|+[F-Y[S]]; Y : [|F-F++FY]+<",
    "name": "wormhole",
    "p.size": "26.87",
    "s.size": "9.40",
    "p.angle": "283.4"
  },
  {
    "i": "18",
    "r": "L : S; S : F|+[F->Y[S]]FG; Y :--[|F-FFF+|+Y]+; G: FG+F+|L+",
    "p.size": "2.5,0.01",
    "p.angle": "-3082.2,0.05",
    "s.size": "8,7.53",
    "s.angle": "7.6,4",
    "offsets": "100,-50,0",
    "name": "coral"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F<|+[F-Y)[-S]]Y-!Y; Y : [|F>-F+)Y]",
    "p.size": "8.26,0.01",
    "p.angle": "2156.5,0.05",
    "s.size": "9,7.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,-90",
    "name": "I will crush you (and various other critters)"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+>[F-Y)[-S]]Y-!Y; Y : [<|F-F+(Y]",
    "p.size": "16.67,0.01",
    "p.angle": "124.72,0.05",
    "s.size": "9,7.4",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "the indomitable moustachio"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+[F-Y)[-(S]]Y-!Y; Y : [|>F-(F+Y]",
    "p.size": "11.79,0.01",
    "p.angle": "-859.18,0.05",
    "s.size": "8.8,7.5",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "seahorse .. moustache"
  },
  {
    "i": "30",
    "r": "L : SYS; S : F>|+[F-Y)[-(S]]Y-Y; Y : [|F-(F+!<Y]",
    "p.size": "2.5,0.01",
    "p.angle": "-523.08,0.05",
    "s.size": "8.6,6.8",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "the slug"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+[F-Y)[->S]]Y-!Y; Y : [|F-<F++Y]",
    "p.size": "13.79,0.01",
    "p.angle": "-138.18,0.05",
    "s.size": "8.7,7.1",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "gears"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+[F<-Y)[-S]]Y-!Y; Y : [|>F-F)++(Y]",
    "p.size": "7.01,0.01",
    "p.angle": "-1856.68,0.05",
    "s.size": "9,7.2",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "jelly-crab"
  },
  {
    "i": "31",
    "r": "L : SYS; S : F|+[F->Y)[-S]]Y-!Y; Y : [|>F-F)++(Y]",
    "p.size": "15.2,0.01",
    "p.angle": "-169.08,0.05",
    "s.size": "8.8,7.3",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "octosquid"
  },
  {
    "i": "30",
    "r": "L : S; S : F+[F-Y[S]]F)G; Y :--[|F-F-)-F>Y]-; G: FGF[+F]+<Y",
    "p.size": "4,0.01",
    "p.angle": "-3769.7,0.05",
    "s.size": "8.6,6.7",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "dream catcher"
  },
  {
    "i": "20",
    "r": "L : SSSL; S : F([F-Y[(F>FFFFFS]]; Y : [|<F-F+(Y]",
    "p.size": "2.79,0.01",
    "p.angle": "-117,0.05",
    "s.size": "8.4,6.8",
    "s.angle": "7.6,4",
    "offsets": "0,50,0",
    "name": "tornado"
  },
  {
    "i": "25",
    "r": "L : SSFL; S : F[F-Y[(-FS]]; Y : [!F>-F+)Y]",
    "p.size": "4,0.01",
    "p.angle": "-13.6,0.05",
    "s.size": "8.5,7.3",
    "s.angle": "7.6,4",
    "offsets": "0,50,0",
    "name": "politic"
  },
  {
    "i": "20",
    "r": "L : SFFSFFL; S : F[F->Y[(-FS]]; Y : <F+Y|",
    "p.size": "5.94,0",
    "p.angle": "378.5,0.05",
    "s.size": "8.5,6.9",
    "s.angle": "7.6,4",
    "offsets": "0,0,0",
    "name": "spin engine"
  },
];
