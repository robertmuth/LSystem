import 'package:chronosgl/chronosgl.dart';

const String aNoise = "aNoise";

const int DEFLATE_START = 1;
const int DEFLATE_END = 2;
const int INFLATE_START = 3;
const int INFLATE_END = 4;
const int PERIOD = INFLATE_END;

final ShaderObject multiColorVertexShader = ShaderObject("MultiColorVertexColorV")
  ..AddAttributeVars([aPosition, aColor])
  ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix])
  ..AddVaryingVars([vColor])
  ..SetBody([
    """
void main() {
    gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(${aPosition}, 1.0);
    ${vColor} = ${aColor};
}
    """,
  ]);

final ShaderObject multiColorVertexShaderInstanced = ShaderObject("MultiColorVertexColorV")
  ..AddAttributeVars([aPosition, aColor])
  ..AddAttributeVars([iaRotation, iaTranslation])
  ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix])
  ..AddVaryingVars([vColor])
  ..SetBody([
    """
vec3 rotate_vertex_position(vec3 pos, vec4 rot) {
    return pos + 2.0 * cross(rot.xyz, cross(rot.xyz, pos) + rot.w * pos);
}

void main() {
    vec3 P = rotate_vertex_position(${aPosition}, ${iaRotation}) +
             ${iaTranslation};
    gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(P, 1.0);
    ${vColor} = ${aColor};
}
    """,
  ]);

final ShaderObject multiColorFragmentShader = ShaderObject("MultiColorVertexColorF")
  ..AddVaryingVars([vColor])
  ..SetBody([
    """
  void main() {
     ${oFragColor} = vec4( ${vColor}, 1.0 );
  }
"""
  ]);

final ShaderObject animatedPointsVertexShader = ShaderObject("dustV")
  ..AddAttributeVars([aPosition, aNoise, aColor])
  ..AddVaryingVars([vColor])
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

    vec3 curr_pos = ${aPosition};

    vec3 orig_pos = ${aPosition};
    vec3 orig_col = ${aColor};

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
    ${vColor}.rgb  = new_col;
    gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(new_pos, 1.0);
    gl_PointSize = ${uPointSize} / gl_Position.z;
}
"""
  ]);

final ShaderObject animatedPointsFragmentShader = ShaderObject("dustF")
  ..AddVaryingVars([vColor])
  ..SetBody([
    """
void main() {
    ${oFragColor}.rgb = ${vColor};
}
    """
  ]);

final ShaderObject coloredPointsVertexShaderInstanced = ShaderObject("coloredPointsVertexShader")
  ..AddAttributeVars([aPosition, aColor])
  ..AddAttributeVars([iaRotation, iaTranslation])
  ..AddVaryingVars([vColor])
  ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix, uPointSize])
  ..SetBody([
    """
vec3 rotate_vertex_position(vec3 pos, vec4 rot) {
    return pos + 2.0 * cross(rot.xyz, cross(rot.xyz, pos) + rot.w * pos);
}

void main() {
  ${vColor} = ${aColor};
 vec3 P = rotate_vertex_position(${aPosition}, ${iaRotation}) +
             ${iaTranslation};
  gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(P, 1.0);
  gl_PointSize = ${uPointSize}/gl_Position.z;
}
  """
  ]);

final ShaderObject coloredPointsVertexShader = ShaderObject("coloredPointsVertexShader")
  ..AddAttributeVars([aPosition, aColor])
  ..AddVaryingVars([vColor])
  ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix, uPointSize])
  ..SetBody([
    """void main() {
  ${vColor} = ${aColor};
  gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(${aPosition}, 1.0);
  gl_PointSize = ${uPointSize}/gl_Position.z;
}
  """
  ]);

final ShaderObject coloredPointsFragmentShader = ShaderObject("coloredPointsFragmentShader")
  ..AddVaryingVars([vColor])
  ..SetBodyWithMain(["${oFragColor}.rgb = ${vColor};"]);
