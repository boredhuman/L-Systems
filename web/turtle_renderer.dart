import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl';

import 'tree_node.dart';
import 'turtle_option.dart';

class TurtleRenderer {
  CanvasElement canvas;

  RenderingContext gl;

  late Program lineProgram;

  late Buffer vertexData;

  TurtleRenderer(this.canvas) : gl = canvas.getContext3d(stencil: false, antialias: false)! {
    Program program = gl.createProgram();
    Shader vertexShader = gl.createShader(WebGL.VERTEX_SHADER);
    Shader fragmentShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(vertexShader, this.vertexShader());
    gl.shaderSource(fragmentShader, this.fragmentShader());

    gl.compileShader(vertexShader);
    if(!(gl.getShaderParameter(fragmentShader, WebGL.COMPILE_STATUS) as bool)) {
      String? vertexLog = gl.getShaderInfoLog(vertexShader);
      if (vertexLog != null && vertexLog.isNotEmpty) {
        print("failed to compile vertex shader $vertexLog.");
      }
    }

    gl.compileShader(fragmentShader);
    if(!(gl.getShaderParameter(fragmentShader, WebGL.COMPILE_STATUS) as bool)) {
      String? fragmentLog = gl.getShaderInfoLog(fragmentShader);
      if (fragmentLog != null && fragmentLog.isNotEmpty) {
        print("failed to compile fragment shader $fragmentLog.");
      }
    }

    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    if (!(gl.getProgramParameter(program, WebGL.LINK_STATUS) as bool)) {
      print("Unable to initialize the shader program: ${gl.getProgramInfoLog(program)}");
    }

    lineProgram = program;

    gl.clearColor(0, 0, 0, 0);

    vertexData = gl.createBuffer();
  }

  render(List<TreeNode> data, Map<String, TurtleOption> turtleOptions) {
    List<double> buffer = treeNodesToVertexData(data, turtleOptions);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    int positionAttribIndex = gl.getAttribLocation(lineProgram, "position");

    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexData);
    gl.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(buffer), WebGL.STATIC_DRAW);
    gl.vertexAttribPointer(positionAttribIndex, 3, WebGL.FLOAT, false, 12, 0);

    gl.useProgram(lineProgram);
    gl.enableVertexAttribArray(positionAttribIndex);

    gl.drawArrays(WebGL.LINE_STRIP, 0, buffer.length ~/ 3);

    gl.disableVertexAttribArray(positionAttribIndex);
    gl.useProgram(null);

    window.requestAnimationFrame((highResTime) {
      // call render to complete render loop or do nothing to render once
    });
  }

  List<double> treeNodesToVertexData(List<TreeNode> data, Map<String, TurtleOption> turtleOptions) {
    var position = <double>[0, 0, 0];
    var zero = <double>[0, 0, 0];
    var rotationVec = <double>[1, 0, 0];
    var buffer = <double>[];
    buffer.addAll([position[0], position[1], position[2]]);

    for (TreeNode treeNode in data) {
      for (int i = 0; i < treeNode.value.length; i++) {
        String letter = treeNode.value[i];
        TurtleOption? turtleOption = turtleOptions[letter];

        if (turtleOption == null) {
          continue;
        }

        print("letter $letter");

        switch (turtleOption.command) {
          case 'Forward':
            position[0] += rotationVec[0];
            position[1] += rotationVec[1];
            position[2] += rotationVec[2];
            buffer.addAll([position[0], position[1], position[2]]);
            break;
          case 'X Rotation':
            rotateX(rotationVec, rotationVec, zero, turtleOption.value * pi / 180);
            break;
          case 'Y Rotation':
            rotateY(rotationVec, rotationVec, zero, turtleOption.value * pi / 180);
            break;
          case 'Z Rotation':
            rotateZ(rotationVec, rotationVec, zero, turtleOption.value * pi / 180);
            break;
          default:
            throw Exception('Unsupported command');
        }
      }
    }

    return buffer;
  }

  List<double> rotateX(List<double> out, List<double> a, List<double> b, double rad) {
    final p = <double>[0, 0, 0], r = <double>[0, 0, 0];
    //Translate point to the origin
    p[0] = a[0] - b[0];
    p[1] = a[1] - b[1];
    p[2] = a[2] - b[2];

    //perform rotation
    r[0] = p[0];
    r[1] = p[1] * cos(rad) - p[2] * sin(rad);
    r[2] = p[1] * sin(rad) + p[2] * cos(rad);

    //translate to correct position
    out[0] = r[0] + b[0];
    out[1] = r[1] + b[1];
    out[2] = r[2] + b[2];

    return out;
  }

  List<double> rotateY(List<double> out, List<double> a, List<double> b, double rad) {
    final p = <double>[0, 0, 0], r = <double>[0, 0, 0];
    //Translate point to the origin
    p[0] = a[0] - b[0];
    p[1] = a[1] - b[1];
    p[2] = a[2] - b[2];

    //perform rotation
    r[0] = p[2] * sin(rad) + p[0] * cos(rad);
    r[1] = p[1];
    r[2] = p[2] * cos(rad) - p[0] * sin(rad);

    //translate to correct position
    out[0] = r[0] + b[0];
    out[1] = r[1] + b[1];
    out[2] = r[2] + b[2];

    return out;
  }

  List<double> rotateZ(List<double> out, List<double> a, List<double> b, double rad) {
    final p = <double>[0, 0, 0], r = <double>[0, 0, 0];
    //Translate point to the origin
    p[0] = a[0] - b[0];
    p[1] = a[1] - b[1];
    p[2] = a[2] - b[2];

    //perform rotation
    r[0] = p[0] * cos(rad) - p[1] * sin(rad);
    r[1] = p[0] * sin(rad) + p[1] * cos(rad);
    r[2] = p[2];

    //translate to correct position
    out[0] = r[0] + b[0];
    out[1] = r[1] + b[1];
    out[2] = r[2] + b[2];

    return out;
  }

  String vertexShader() {
    return """
    precision mediump float;

    attribute vec3 position;

    void main() {
      gl_Position = vec4(position / 10.0, 1.0);
      gl_PointSize = 5.0;
    }
    """;
  }

  String fragmentShader() {
    return """
    precision mediump float;
    
    void main() {
      gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
    }
    """;
  }
}
