/*
Copyright Robert Muth <robert@muth.org>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 3
of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

library webutil;

import 'dart:html';
import 'dart:core';
import 'dart:math';
import 'dart:js';
import 'dart:web_gl';

List<int> GetColorRGB(String colorName) {
  SpanElement e = document.createElement('span') as SpanElement;
  e.style.color = colorName;
  document.body!.append(e);
  String color = e.getComputedStyle().color;
  e.remove();
  // color looks like: "rgb(1, 2, 3)"
  List<String> t = color.split(RegExp(r"[^0-9]+"));
  return [int.parse(t[1]), int.parse(t[2]), int.parse(t[3])];
}

List<double> MakeColorWithNoise(Random rng, String colorName, double noisePercent) {
  double addNoise(Random rng, int base, double noisePercent) {
    return base / 255.0 * (1.0 - noisePercent) + rng.nextDouble() * noisePercent;
  }

  List<int> rgb = GetColorRGB(colorName);
  return [
    addNoise(rng, rgb[0], noisePercent),
    addNoise(rng, rgb[1], noisePercent),
    addNoise(rng, rgb[2], noisePercent)
  ];
}

void Toggle(Element e) {
  e.hidden = !e.hidden;
}

void ToggleFullscreen() {
  if (document.fullscreenElement == null) {
    document.documentElement!.requestFullscreen();
  } else {
    document.exitFullscreen();
  }
}

void Show(Element e) {
  e.hidden = false;
}

void Hide(Element e) {
  e.hidden = true;
}

const double SAMPLE_RATE_MS = 1000.0;
int gFrames = 0;
double gLastSample = 0.0;
double gAverageFps = 1.0;

void UpdateFrameCount(double now, Element e, String extra) {
  gFrames++;
  if ((now - gLastSample) < SAMPLE_RATE_MS) return;
  double currentFps = gFrames * 1000.0 / SAMPLE_RATE_MS;
  gAverageFps = gAverageFps * 0.1 + 0.9 * currentFps;
  e.text = gAverageFps.toStringAsFixed(2) + "\n" + extra;
  gFrames = 0;
  gLastSample = now;
}

bool HasWebGLSupport() {
  CanvasElement canvas = CanvasElement();
  RenderingContext2 gl = canvas.getContext("webgl2", <String, Object>{}) as RenderingContext2;
  // if (gl == null) return false;

  void log(String s, int param) {
    Object val = gl.getParameter(param)!;
    window.console.info(s + "${val}");
  }

  log("max texture units:          ", WebGL.MAX_TEXTURE_IMAGE_UNITS);
  log("max vertex texture units:   ", WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
  log("max texture size:           ", WebGL.MAX_TEXTURE_SIZE);
  log("max cube map texture size:  ", WebGL.MAX_CUBE_MAP_TEXTURE_SIZE);
  //log("max texture max anisotrphy: ",
  //    WebGL.ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
  log("compressed texture formats: ", WebGL.COMPRESSED_TEXTURE_FORMATS);

  void logp(String s, int param) {
    ShaderPrecisionFormat fh = gl.getShaderPrecisionFormat(param, WebGL.HIGH_FLOAT);
    ShaderPrecisionFormat fm = gl.getShaderPrecisionFormat(param, WebGL.MEDIUM_FLOAT);
    ShaderPrecisionFormat fl = gl.getShaderPrecisionFormat(param, WebGL.LOW_FLOAT);

    window.console.info(s + "[fp] ${fh.precision}  ${fm.precision} ${fl.precision}");
    ShaderPrecisionFormat ih = gl.getShaderPrecisionFormat(param, WebGL.HIGH_INT);
    ShaderPrecisionFormat im = gl.getShaderPrecisionFormat(param, WebGL.MEDIUM_INT);
    ShaderPrecisionFormat il = gl.getShaderPrecisionFormat(param, WebGL.LOW_INT);
    window.console.info(s + "[int] ${ih.rangeMax}  ${im.rangeMax} ${il.rangeMax}");
  }

  logp("vertex shader precision:   ", WebGL.VERTEX_SHADER);
  logp("fragment shader precision: ", WebGL.FRAGMENT_SHADER);

  List<String> exts = gl.getSupportedExtensions()!;
  for (String e in exts) {
    window.console.info("Extension $e");
  }

  return true;
}

/*
bool CanWriteToFloatTexture() {
  CanvasElement canvas = new CanvasElement();
  WebGL.RenderingContext gl = canvas.getContext3d();
  var ext = gl.getExtension("OES_texture_float");
  if (ext == null) {
    return false;
  }
  WebGL.Texture texture = gl.createTexture();
  gl.bindTexture(WebGL.TEXTURE_2D, texture);
  gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGB, 128, 128, 0, WebGL.RGB,
      WebGL.FLOAT, null);
  gl.bindTexture(WebGL.TEXTURE_2D, null);
  WebGL.Framebuffer framebuffer = gl.createFramebuffer();
  gl.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);
  gl.framebufferTexture2D(
      WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, texture, 0);
  //gl.bindTexture(WEBGL.TEXTURE_2D, null);
  int err = gl.checkFramebufferStatus(WebGL.FRAMEBUFFER);
  gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  return err == WebGL.FRAMEBUFFER_COMPLETE;
}
*/

class ProgressReporter {
  ProgressReporter(this._element);

  Element _element;

  void Start() {
    Show(_element);
  }

  void End() {
    Hide(_element);
  }

  void SetTask(String s) {
    _element.text = s;
    window.console.info("progress: $s");
  }
}

void fullscreenWorkaround(CanvasElement canvas) {
  var canv = JsObject.fromBrowserObject(canvas);

  if (canv.hasProperty("requestFullscreen")) {
    canv.callMethod("requestFullscreen");
  } else {
    List<String> vendors = ['moz', 'webkit', 'ms', 'o'];
    for (String vendor in vendors) {
      String vendorFullscreen = "${vendor}RequestFullscreen";
      if (vendor == 'moz') {
        vendorFullscreen = "${vendor}RequestFullScreen";
      }
      if (canv.hasProperty(vendorFullscreen)) {
        canv.callMethod(vendorFullscreen);
        return;
      }
    }
  }
}
