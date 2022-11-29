import 'dart:html';
import 'dart:js_util';
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

  int vertexCount = 0;

  double xRot = 0;

  double yRot = 0;

  double scale = 0.1;

  bool dragging = false;

  int prevX = 0;

  int prevY = 0;

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
    vertexCount = buffer.length ~/ 7;

    buffer.addAll([
      // y axis
      0, 0, 0, 1, 0, 0, 1,
      0, 10, 0, 1, 0, 0, 1,
      // x axis
      0, 0, 0, 0, 1, 0, 1,
      10, 0, 0, 0, 1, 0, 1,
      // z axis
      0, 0, 0, 0, 0, 1, 1,
      0, 0, 10, 0, 0, 1, 1,
    ]);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexData);
    gl.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(buffer), WebGL.STATIC_DRAW);

    renderInternal();
  }

  // call this to render, it will use data previously given
  renderInternal() {
    int actualWidth = canvas.getBoundingClientRect().width.toInt();
    int actualHeight = canvas.getBoundingClientRect().height.toInt();
    // canvas has been changed. Resize to keep 1:1 scaling
    if (canvas.width != actualWidth || canvas.height != actualHeight) {
      canvas.width = actualWidth;
      canvas.height = actualHeight;
      gl.viewport(0, 0, actualWidth, actualHeight);
    }

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    int positionAttribIndex = gl.getAttribLocation(lineProgram, "position");
    int colorAttribIndex = gl.getAttribLocation(lineProgram, "color");
    UniformLocation transformMatrixUniformLocation = gl.getUniformLocation(lineProgram, "transformMatrix");

    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexData);
    gl.vertexAttribPointer(positionAttribIndex, 3, WebGL.FLOAT, false, 28, 0);
    gl.vertexAttribPointer(colorAttribIndex, 4, WebGL.FLOAT, false, 28, 12);

    gl.useProgram(lineProgram);
    Matrix4 matrix4 = Matrix4.identity();
    matrix4.scale(scale, scale, scale);
    // rotate around the y axis
    matrix4.rotateY(xRot * pi / 180);
    // rotate around the x axis
    matrix4.rotateX(yRot * pi / 180);
    gl.uniformMatrix4fv(transformMatrixUniformLocation, false, matrix4.storage);

    gl.enableVertexAttribArray(positionAttribIndex);
    gl.enableVertexAttribArray(colorAttribIndex);

    gl.drawArrays(WebGL.LINE_STRIP, 0, vertexCount);

    gl.drawArrays(WebGL.LINES, vertexCount, vertexCount + 2);

    gl.disableVertexAttribArray(positionAttribIndex);
    gl.useProgram(null);

    window.requestAnimationFrame((highResTime) {
      // call render to complete render loop or do nothing to render once
    });
  }

  List<double> treeNodesToVertexData(List<TreeNode> data, Map<String, TurtleOption> turtleOptions) {
    Vector3 position = Vector3(0, 0, 0);
    Vector3 rotationVector = Vector3(1, 0, 0);
    var buffer = <double>[];
    buffer.addAll([position[0], position[1], position[2], 1, 1, 1, 1]);

    for (TreeNode treeNode in data) {
      for (int i = 0; i < treeNode.value.length; i++) {
        String letter = treeNode.value[i];
        TurtleOption? turtleOption = turtleOptions[letter];

        if (turtleOption == null) {
          continue;
        }

        switch (turtleOption.command) {
          case 'Forward':
            position.add(rotationVector);
            // white color
            buffer.addAll([position[0], position[1], position[2], 1, 1, 1, 1]);
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
          default:
            throw Exception('Unsupported command');
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

      xRot += xDelta;
      yRot += yDelta;

      prevX = currentX;
      prevY = currentY;

      renderInternal();
    }
  }

  onMouseWheelEvent(WheelEvent event) {
    if (event.deltaY > 0) {
      scale -= 0.01;
    } else {
      scale += 0.01;
    }
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
