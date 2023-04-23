import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'tree_node.dart';
import 'turtle_option.dart';

class TurtleRenderer {
  CanvasElement canvas;

  RenderingContext gl;

  late Program lineProgram;

  late Buffer vertexData;

  // contains the number of vertices to draw excluding the axis
  int vertexCount = 0;

  double xTranslate = 0;

  double yTranslate = 0;

  double scale = 0.1;

  bool dragging = false;

  int prevX = 0;

  int prevY = 0;

  List<int> resets = [];

  TurtleRenderer(this.canvas) : gl = canvas.getContext3d(stencil: false, antialias: false)! {
    Program program = gl.createProgram();
    Shader vertexShader = gl.createShader(WebGL.VERTEX_SHADER);
    Shader fragmentShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(vertexShader, this.vertexShader());
    gl.shaderSource(fragmentShader, this.fragmentShader());

    gl.compileShader(vertexShader);
    if (!(gl.getShaderParameter(fragmentShader, WebGL.COMPILE_STATUS) as bool)) {
      String? vertexLog = gl.getShaderInfoLog(vertexShader);
      if (vertexLog != null && vertexLog.isNotEmpty) {
        print("failed to compile vertex shader $vertexLog.");
      }
    }

    gl.compileShader(fragmentShader);
    if (!(gl.getShaderParameter(fragmentShader, WebGL.COMPILE_STATUS) as bool)) {
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

    gl.clearColor(1, 1, 1, 0);

    // setup
    gl.useProgram(lineProgram);

    vertexData = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexData);

    int positionAttribIndex = gl.getAttribLocation(lineProgram, "position");
    int colorAttribIndex = gl.getAttribLocation(lineProgram, "color");

    gl.vertexAttribPointer(positionAttribIndex, 3, WebGL.FLOAT, false, 28, 0);
    gl.vertexAttribPointer(colorAttribIndex, 4, WebGL.FLOAT, false, 28, 12);

    gl.enableVertexAttribArray(positionAttribIndex);
    gl.enableVertexAttribArray(colorAttribIndex);
  }

  render(List<TreeNode> data, Map<String, List<TurtleOption>> turtleOptions) {
    List<double> buffer = treeNodesToVertexData(data, turtleOptions);
    vertexCount = buffer.length ~/ 7;

    buffer.addAll([
      // y axis red
      0, 0, 0, 1, 0, 0, 1,
      0, 10, 0, 1, 0, 0, 1,
      // x axis green
      0, 0, 0, 0, 1, 0, 1,
      10, 0, 0, 0, 1, 0, 1,
      // z axis blue
      0, 0, 0, 0, 0, 1, 1,
      0, 0, 10, 0, 0, 1, 1,
    ]);

    gl.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(buffer), WebGL.STATIC_DRAW);

    renderInternal();
  }

  // call this to render, it will use data previously given
  void renderInternal() {
    int actualWidth = canvas.getBoundingClientRect().width.toInt();
    int actualHeight = canvas.getBoundingClientRect().height.toInt();
    // canvas has been changed. Resize to keep 1:1 scaling
    if (canvas.width != actualWidth || canvas.height != actualHeight) {
      canvas.width = actualWidth;
      canvas.height = actualHeight;
      gl.viewport(0, 0, actualWidth, actualHeight);
    }

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    UniformLocation transformMatrixUniformLocation = gl.getUniformLocation(lineProgram, "transformMatrix");

    Matrix4 matrix4 = Matrix4.identity();
    matrix4.translate(xTranslate, -yTranslate);
    matrix4.scale(scale, scale, scale);
    double xRot = double.parse((document.getElementById("xRot") as ParagraphElement).text!);
    double yRot = double.parse((document.getElementById("yRot") as ParagraphElement).text!);
    double zRot = double.parse((document.getElementById("zRot") as ParagraphElement).text!);
    // rotate around the y axis
    matrix4.rotateY(yRot * pi / 180);
    // rotate around the x axis
    matrix4.rotateX(xRot * pi / 180);
    // rotate around the z axis
    matrix4.rotateZ(zRot * pi / 180);

    gl.uniformMatrix4fv(transformMatrixUniformLocation, false, matrix4.storage);

    if (resets.isEmpty) {
      // no push / pops render line in one go
      gl.drawArrays(WebGL.LINE_STRIP, 0, vertexCount);
    } else {
      // render first part
      int first = resets[0];
      gl.drawArrays(WebGL.LINE_STRIP, 0, first);
      for (int i = 0; i < resets.length; i++) {
        // last line
        if (i == resets.length - 1) {
          gl.drawArrays(WebGL.LINE_STRIP, first, vertexCount - first);
        } else {
          int next = resets[i + 1];
          // intermediate lines
          gl.drawArrays(WebGL.LINE_STRIP, first, next - first);
          first = next;
        }
      }
    }

    gl.drawArrays(WebGL.LINES, vertexCount, 6);

    window.requestAnimationFrame((highResTime) {
      // call render to complete render loop or do nothing to render once
    });
  }

  List<double> treeNodesToVertexData(List<TreeNode> data, Map<String, List<TurtleOption>> turtleOptionsMap) {
    Vector3 position = Vector3(0, 0, 0);
    Vector3 rotationVector = Vector3(1, 0, 0);
    var buffer = <double>[];
    buffer.addAll([position[0], position[1], position[2], 1, 1, 1, 1]);
    List<Vector3> positionStateStack = [];
    List<Vector3> rotationVectorStack = [];
    resets.clear();

    for (TreeNode treeNode in data) {
      for (int i = 0; i < treeNode.value.length; i++) {
        String letter = treeNode.value[i];
        List<TurtleOption>? turtleOptions = turtleOptionsMap[letter];

        if (turtleOptions == null) {
          continue;
        }

        for (TurtleOption turtleOption in turtleOptions) {
          switch (turtleOption.command) {
            case 'Forward':
              position[0] += rotationVector[0] * turtleOption.value;
              position[1] += rotationVector[1] * turtleOption.value;
              position[2] += rotationVector[2] * turtleOption.value;
              // white color
              buffer.addAll([position[0], position[1], position[2], 0, 0, 0, 1]);
              break;
            case 'X Rotation':
              Quaternion quaternion = Quaternion.axisAngle(Vector3(1, 0, 0), turtleOption.value * pi / 180);
              quaternion.rotate(rotationVector);
              break;
            case 'Y Rotation':
              Quaternion quaternion = Quaternion.axisAngle(Vector3(0, 1, 0), turtleOption.value * pi / 180);
              quaternion.rotate(rotationVector);
              break;
            case 'Z Rotation':
              Quaternion quaternion = Quaternion.axisAngle(Vector3(0, 0, 1), turtleOption.value * pi / 180);
              quaternion.rotate(rotationVector);
              break;
            case 'Push State':
              positionStateStack.add(Vector3.zero()..setFrom(position));
              rotationVectorStack.add(Vector3.zero()..setFrom(rotationVector));
              break;
            case 'Pop State':
              resets.add(buffer.length ~/ 7);
              position = positionStateStack.removeLast();
              rotationVector = rotationVectorStack.removeLast();
              buffer.addAll([position[0], position[1], position[2], 0, 0, 0, 1]);
              break;
            default:
              throw Exception('Unsupported command');
          }
        }
      }
    }

    return buffer;
  }

  // movement in x is interpreted as rotating around the y axis
  // movement in y axis is interpreted as rotating around the x axis
  onDrag(MouseEvent event) {
    if (!dragging) {
      return;
    }
    int currentX = event.client.x.toInt();
    int currentY = event.client.y.toInt();

    if (currentX != prevX || currentY != prevY) {
      int xDelta = currentX - prevX;
      int yDelta = currentY - prevY;

      xTranslate += xDelta / 1000;
      yTranslate += yDelta / 1000;

      prevX = currentX;
      prevY = currentY;

      renderInternal();
    }
  }

  onMouseWheelEvent(WheelEvent event) {
    if (event.deltaY > 0) {
      scale *= 0.5;
      xTranslate *= 0.5;
      yTranslate *= 0.5;
    } else {
      scale *= 2;
      xTranslate *= 2;
      yTranslate *= 2;
    }
    renderInternal();
  }

  void recenter() {
    xTranslate = 0;
    yTranslate = 0;
    scale = 0.1;
    renderInternal();
  }

  String vertexShader() {
    return """
    precision mediump float;

    attribute vec3 position;
    attribute vec4 color;
    
    varying vec4 outColor;
    
    uniform mat4 transformMatrix;

    void main() {
      gl_Position = transformMatrix * vec4(position, 1.0);
      outColor = color;
    }
    """;
  }

  String fragmentShader() {
    return """
    precision mediump float;
    
    varying vec4 outColor;
    
    void main() {
      gl_FragColor = outColor;
    }
    """;
  }
}
