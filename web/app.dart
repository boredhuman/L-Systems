import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:svg';

import 'production_rule.dart';
import 'tree_node.dart';
import 'tree_renderer.dart';
import 'turtle_option.dart';
import 'turtle_renderer.dart';

class App {
  late Element svgContainer;
  late TreeRenderer treeRenderer;
  TreeNode root = TreeNode("");
  int iterations = 0;
  CanvasElement canvas = CanvasElement();
  late TurtleRenderer turtleRenderer = TurtleRenderer(canvas);

  App() {
    int prevMouseX = 0;
    int prevMouseY = 0;
    bool dragging = false;

    document.body!
      ..style.setProperty("display", "flex")
      ..children.addAll([
        // l system configurations
        DivElement()
          ..classes.addAll(["leftBar"])
          ..children.addAll([
            DivElement()
              ..style.setProperty("width", "100%")
              ..style.setProperty("overflow", "hidden")
              ..children.addAll([
                InputElement()
                  ..id = "axiom"
                  ..value = "A"
                  ..placeholder = "axiom"
                  ..style.setProperty("margin", "auto")
                  ..style.setProperty("text-align", "center"),
                createProductionRule("A", "AB", null),
                createProductionRule("B", "A", null),
                ParagraphElement()
                  ..text = "Add Production Rule"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    Element clicked = event.target as Element;

                    clicked.parent!.insertBefore(createProductionRule(null, null, null), clicked);
                  }),
                DivElement()
                  ..style.setProperty("display", "flex")
                  ..style.setProperty("justify-content", "space-between")
                  ..style.setProperty("align-items", "center")
                  ..children.addAll([
                    ParagraphElement()
                      ..text = "Render Mode"
                      ..style.setProperty("margin", "0"),
                    SelectElement()
                      ..id = "renderMode"
                      ..style.setProperty("height", "30px")
                      ..children.addAll([
                        OptionElement()
                          ..setAttribute("value", "Tree")
                          ..text = "Tree",
                        OptionElement()
                          ..setAttribute("value", "Turtle")
                          ..text = "Turtle"
                      ])
                      ..onChange.listen((event) {
                        String? value = (event.target as SelectElement).value;

                        if (value == "Turtle") {
                          (document.getElementById("turtle config") as DivElement).style.removeProperty("display");
                          (document.getElementById("svgRenderer") as Element).style.setProperty("display", "none");
                          (document.getElementById("canvasRenderer") as Element).style.removeProperty("display");
                        } else {
                          (document.getElementById("turtle config") as DivElement).style.setProperty("display", "none");
                          (document.getElementById("canvasRenderer") as Element).style.setProperty("display", "none");
                          (document.getElementById("svgRenderer") as Element).style.removeProperty("display");
                        }

                        reset(event);
                      })
                  ]),
                DivElement()
                  ..style.setProperty("display", "none")
                  ..text = "Turtle Symbol Map"
                  ..id = "turtle config"
                  ..children.addAll([
                    createTurtleConfigRow("Forward", "F", 1),
                    createTurtleConfigRow("Z Rotation", "-", -90),
                    createTurtleConfigRow("Z Rotation", "+", 90),
                    ParagraphElement()
                      ..text = "Add Symbol Row"
                      ..classes.addAll(["btn"])
                      ..onClick.listen((event) {
                        (event.currentTarget! as Element)
                            .parent!
                            .insertBefore(createTurtleConfigRow("Forward", "F", 1), event.currentTarget as Element);
                      }),
                    createSlider("X Rot:", "xRot"),
                    createSlider("Y Rot:", "yRot"),
                    createSlider("Z Rot:", "zRot")
                  ]),
                // current generation display and step size configuration
                DivElement()
                  ..style.setProperty("display", "flex")
                  ..style.setProperty("align-items", "center")
                  ..style.setProperty("justify-content", "space-between")
                  ..style.setProperty("height", "30px")
                  ..children.addAll([
                    ParagraphElement()
                      ..style.setProperty("margin", "0")
                      ..text = "Current Generation :"
                      ..style.setProperty("white-space", "nowrap"),
                    ParagraphElement()
                      ..id = "currentGeneration"
                      ..text = "0"
                      ..style.setProperty("margin", "0 1px"),
                  ]),
                DivElement()
                  ..style.setProperty("display", "flex")
                  ..style.setProperty("justify-content", "space-between")
                  ..style.setProperty("align-items", "center")
                  ..style.setProperty("height", "30px")
                  ..children.addAll([
                    ParagraphElement()
                      ..style.setProperty("margin", "0")
                      ..text = "Step Size:"
                      ..style.setProperty("white-space", "nowrap"),
                    InputElement()
                      ..id = "stepSize"
                      ..setAttribute("type", "number")
                      ..setAttribute("min", "1")
                      ..style.setProperty("width", "40px")
                      ..style.setProperty("margin", "0 1px")
                      ..value = "1"
                  ]),
                // step button
                ParagraphElement()
                  ..text = "Step"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    Map<String, ProductionRule> productionRulesMap = getProductionRulesMap();

                    String? axiom = getAxiom();

                    if (axiom == null || axiom.isEmpty) {
                      return;
                    }

                    // axiom has been changed
                    if (axiom != root.value) {
                      root = TreeNode(axiom);
                      iterations = 0;
                      setCurrentGeneration(iterations);
                    }

                    // so we go over each node and convert each symbol in the value using the production rules
                    // we then set the next level to the first child of the current tree node
                    if (iterations == 0) {
                      root.value = axiom;
                    }

                    int stepSize = getStepSize();
                    for (int i = 0; i < stepSize; i += 1) {
                      List<TreeNode> nodes = getElementsAtDepth(root, iterations, 0);

                      for (var node in nodes) {
                        applyProductionRulesToNode(productionRulesMap, node);
                      }

                      iterations += 1;
                      setCurrentGeneration(iterations);
                    }
                    // fill TreeNode
                    String renderMode = (document.getElementById("renderMode") as SelectElement).value!;
                    if (renderMode == "Turtle") {
                      // do turtle rendering
                      turtleRenderer.render(getElementsAtDepth(root, iterations, 0), getTurtleConfig());
                    } else {
                      // render tree
                      // svgContainer.children.clear();
                      treeRenderer.layoutTreeNodeInit(TreeNode("")..children.add(root), 50);
                    }
                  }),
                ParagraphElement()
                  ..text = "Reset"
                  ..classes.addAll(["btn"])
                  ..onClick.listen(reset),
                ParagraphElement()
                  ..text = "Save Project"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    Map<String, dynamic> saveData = {};
                    saveData["axiom"] = getAxiom();
                    saveData["productionRules"] = getProductionRulesMap().map((key, value) => MapEntry(key, {
                          "pairs": value.pairs.map((e) => {"key": e.key, "value": e.value}).toList()
                        }));
                    saveData["turtleData"] = getTurtleConfig()
                        .map((key, value) => MapEntry(key, {"value": value.value, "command": value.command, "symbol": value.symbol}));
                    String saveDataText = JsonEncoder().convert(saveData);

                    Element tempElement = document.createElement('a');
                    tempElement.setAttribute('href', "data:text/plain;charset=utf-8,${Uri.encodeComponent(saveDataText)}");
                    tempElement.setAttribute('download', "l-system.json");

                    tempElement.style.display = 'none';
                    document.body!.children.add(tempElement);

                    tempElement.click();

                    tempElement.remove();
                  }),
                InputElement(type: "file")
                  ..style.setProperty("width", "100%")
                  ..onChange.listen((event) {
                    InputElement self = event.target as InputElement;
                    if (self.files != null && self.files!.isNotEmpty) {
                      File file = self.files![0];
                      Blob blob = file.slice(0, file.size);
                      FileReader()
                        ..readAsText(blob)
                        ..onLoadEnd.listen((event) {
                          String jsonData = (event.target as FileReader).result as String;

                          Map<String, dynamic> json = jsonDecode(jsonData);

                          // symbol then field and value for turtleOption
                          Map<dynamic, dynamic> turtleData = json["turtleData"];
                          Map<dynamic, dynamic> productionRulesMap = json["productionRules"];

                          InputElement axiomElement = document.getElementById("axiom") as InputElement;

                          axiomElement.value = json["axiom"];

                          for (MapEntry<dynamic, dynamic> rule in productionRulesMap.entries) {
                            String lhs = rule.key;
                            List<dynamic> pairs = rule.value["pairs"];
                            for (dynamic pair in pairs) {
                              String rhs = pair["key"];
                              dynamic probability = pair["value"].toString();
                              axiomElement.parent!.insertBefore(createProductionRule(lhs, rhs, probability), axiomElement.nextNode!);
                            }
                          }

                          Element turtleConfigElement = document.getElementById("turtle config")!;

                          for (MapEntry<dynamic, dynamic> turtleConfigEntry in turtleData.entries) {
                            Map<dynamic, dynamic> turtleConfig = turtleConfigEntry.value;
                            turtleConfigElement.children
                                .add(createTurtleConfigRow(turtleConfig["command"]!, turtleConfig["symbol"]!, turtleConfig["value"]!));
                          }
                        });
                    }
                  }),
              ])
          ]),
        // l system rendering
        DivElement()
          ..style.setProperty("width", "100%")
          ..style.setProperty("height", "100%")
          ..onMouseDown.listen((event) {
            if (event.target.hashCode == svgContainer.parent!.parent.hashCode || event.target.hashCode == svgContainer.parent.hashCode) {
              dragging = true;
              prevMouseX = event.client.x.toInt();
              prevMouseY = event.client.y.toInt();
              disableTextHighlight();
            }
          })
          ..onMouseMove.listen((event) {
            // dont let svg get dragging when we are in turtle mode
            if ((document.getElementById("renderMode") as SelectElement).value == "Turtle") {
              turtleRenderer.onDrag(event);
              return;
            }
            if (dragging) {
              int xDelta = event.client.x.toInt() - prevMouseX;
              int yDelta = event.client.y.toInt() - prevMouseY;

              if (xDelta != 0 || yDelta != 0) {
                var transform = svgContainer.getAttribute("transform");
                int xTranslate = 0;
                int yTranslate = 0;
                if (transform != null) {
                  var transformPair = transform.substring(transform.indexOf('(') + 1, transform.length - 1);
                  xTranslate = int.parse(transformPair.split(' ')[0]);
                  yTranslate = int.parse(transformPair.split(' ')[1]);
                }
                xTranslate += xDelta;
                yTranslate += yDelta;
                // var val = "translate(${xTranslate}px,${yTranslate}px)";
                var val = "translate($xTranslate $yTranslate)";
                svgContainer.setAttribute("transform", val);

                prevMouseX = event.client.x.toInt();
                prevMouseY = event.client.y.toInt();

                treeRenderer.layoutTreeNodeInit(TreeNode("")..children.add(root), 50, true);
              }
            }
          })
          ..children.addAll([
            // svg tree renderer
            SvgSvgElement()
              ..id = "svgRenderer"
              ..style.setProperty("width", "100%")
              ..style.setProperty("height", "100%")
              ..children.add(svgContainer = GElement()
                ..id = "svgContainer"
                ..style.setProperty("width", "100%")
                ..style.setProperty("height", "100%")),
            // canvas renderer
            canvas
              ..id = "canvasRenderer"
              ..style.setProperty("display", "none")
              ..style.setProperty("width", "100%")
              ..style.setProperty("height", "100%")
              ..onMouseWheel.listen(turtleRenderer.onMouseWheelEvent)
              ..onMouseDown.listen((event) {
                turtleRenderer.dragging = true;
                turtleRenderer.prevX = event.client.x.toInt();
                turtleRenderer.prevY = event.client.y.toInt();
              })
          ])
      ])
      ..style.setProperty("background-color", "#111111")
      ..style.setProperty("overflow", "hidden")
      ..style.setProperty("margin-bottom", "200px");

    document.body!.onMouseUp.listen((event) {
      dragging = false;
      turtleRenderer.dragging = false;
      enableTextHighlight();
    });

    treeRenderer = TreeRenderer(svgContainer);
  }

  Map<String, TurtleOption> getTurtleConfig() {
    List<Node> turtleOptions = document.getElementsByClassName("turtleOption");
    Map<String, TurtleOption> turtleOptionsMap = {};

    for (Node turtleOptionElement in turtleOptions) {
      if (turtleOptionElement is Element) {
        // command such as move forward, turn left, turn right
        String command = (turtleOptionElement.children[0] as SelectElement).value!;
        // the lhs of the production rule
        String symbol = (turtleOptionElement.children[1] as InputElement).value!;
        // the rhs of the production rule
        String value = (turtleOptionElement.children[2] as InputElement).value!;

        TurtleOption turtleOption = TurtleOption(command, symbol, double.parse(value));

        turtleOptionsMap[symbol] = turtleOption;
      }
    }

    return turtleOptionsMap;
  }

  void reset(event) {
    String renderMode = (document.getElementById("renderMode") as SelectElement).value!;
    InputElement axiomElement = document.getElementById("axiom") as InputElement;
    root = TreeNode(axiomElement.value!);
    iterations = 0;
    setCurrentGeneration(iterations);

    if (renderMode == "Turtle") {
      turtleRenderer.render(getElementsAtDepth(root, iterations, 0), getTurtleConfig());
    } else {
      svgContainer.children.clear();
      treeRenderer.layoutTreeNodeInit(TreeNode("")..children.add(root), 50);
    }
  }

  // for creating a row for the turtle configuration
  Element createTurtleConfigRow([String? command, String? symbol, int? amount]) {
    return DivElement()
      ..style.setProperty("display", "flex")
      ..classes.addAll(["turtleOption"])
      ..children.addAll([
        SelectElement()
          ..children.addAll([
            OptionElement()
              ..value = "Forward"
              ..text = "Forward",
            OptionElement()
              ..value = "X Rotation"
              ..text = "X Rotation",
            OptionElement()
              ..value = "Y Rotation"
              ..text = "Y Rotation",
            OptionElement()
              ..value = "Z Rotation"
              ..text = "Z Rotation"
          ])
          ..value = command ?? "",
        InputElement()
          ..placeholder = "symbol"
          ..style.setProperty("width", "100%")
          ..style.setProperty("margin", "0 5px")
          ..value = symbol ?? "",
        InputElement()
          ..placeholder = "amount"
          ..style.setProperty("width", "100%")
          ..value = amount != null ? amount.toString() : "",
        SpanElement()
          ..classes.addAll(["material-symbols-outlined"])
          ..text = "close"
          ..onClick.listen((event) {
            (event.currentTarget as Element).parent!.remove();
          })
      ]);
  }

  // recursively gets all the element at a given depth
  // todo probably needs optimizing
  List<TreeNode> getElementsAtDepth(TreeNode node, int depth, int currentDepth) {
    if (depth == 0) {
      return [node];
    } else if (depth == 1) {
      return node.children;
    }
    if (currentDepth == depth) {
      return [node];
    } else {
      List<TreeNode> nodes = [];
      for (var childNode in node.children) {
        nodes.addAll(getElementsAtDepth(childNode, depth, currentDepth + 1));
      }
      return nodes;
    }
  }

  void applyProductionRulesToNode(Map<String, ProductionRule> productionRulesMap, TreeNode node) {
    String string = node.value;
    // iterate over each character cna check if there is production rule for it
    // todo potentially add support for production rules longer than a single character
    for (int i = 0; i < string.length; i++) {
      ProductionRule? rhs = productionRulesMap[string[i]];

      if (rhs != null) {
        node.addNode(TreeNode(rhs.getRhs()));
      } else {
        // symbol does not have a production rule so assume its a terminal and keep it
        node.addNode(TreeNode(string[i]));
      }
    }
  }

  void setCurrentGeneration(int generation) {
    Element currentGenerationElement = document.getElementById("currentGeneration") as Element;
    currentGenerationElement.text = generation.toString();
  }

  int getStepSize() {
    InputElement stepSizeElement = document.getElementById("stepSize") as InputElement;
    return stepSizeElement.valueAsNumber!.toInt();
  }

  DivElement createProductionRule(String? lhs, String? rhs, String? probability) {
    return DivElement()
      // pr = production rule
      ..classes.addAll(["pr"])
      ..style.setProperty("padding-top", "5px")
      ..style.setProperty("display", "flex")
      ..style.setProperty("height", "25px")
      ..children.addAll([
        // lhs
        InputElement()
          ..classes.addAll(["lhs"])
          ..style.setProperty("width", "30px")
          // max length as all productions rules must be context free
          ..setAttribute("maxlength", "1")
          ..style.setProperty("text-align", "center")
          ..value = lhs,
        ParagraphElement()
          ..text = "->"
          ..style.setProperty("margin", "0"),
        // rhs
        InputElement()
          ..classes.addAll(["rhs"])
          ..style.setProperty("width", "10px")
          ..style.setProperty("flex", "1")
          ..value = rhs,
        // probability
        InputElement()
          ..classes.addAll(["prob"])
          ..style.setProperty("width", "50px")
          ..style.setProperty("margin", "0 5px")
          ..style.setProperty("text-align", "center")
          ..value = probability ?? "100",
        SpanElement()
          ..classes.addAll(["material-symbols-outlined"])
          ..text = "close"
          ..onClick.listen((event) {
            (event.currentTarget as Element).parent!.remove();
          })
      ]);
  }

  Map<String, ProductionRule> getProductionRulesMap() {
    List<Node> productionRules = document.getElementsByClassName("pr");
    Map<String, ProductionRule> productionRulesMap = {};

    for (Node node in productionRules) {
      if (node is Element) {
        Node lhs = node.getElementsByClassName("lhs").first;
        Node rhs = node.getElementsByClassName("rhs").first;
        Node prob = node.getElementsByClassName("prob").first;

        if (lhs is InputElement && rhs is InputElement && prob is InputElement) {
          String? lhsText = lhs.value;
          String rhsText = rhs.value ?? "";
          double probability = prob.value != null ? double.parse(prob.value!) : 0;

          if (lhsText != null) {
            ProductionRule? productionRule = productionRulesMap[lhsText];
            if (productionRule == null) {
              productionRule = ProductionRule();
              productionRulesMap[lhsText] = productionRule;
            }
            productionRule.addRHS(rhsText, probability);
          }
        }
      }
    }

    for (ProductionRule productionRule in productionRulesMap.values) {
      productionRule.done();
    }

    return productionRulesMap;
  }

  Element createSlider(String prefix, String id) {
    bool dragging = false;
    late DivElement filler;
    late DivElement background;
    late ParagraphElement text;

    document
      ..onMouseUp.listen((event) {
        if (dragging) {
          enableTextHighlight();
        }
        dragging = false;
      })
      ..onMouseMove.listen((event) {
        if (dragging) {
          int x = event.client.x.toInt();

          Rectangle<num> rect = background.getBoundingClientRect();
          int left = rect.left.toInt() + 10;
          int width = rect.width.toInt() - 20;
          double offset = min(max((x - left) / width, 0), 1) * 100;
          filler.style.setProperty("transform", "translate($offset%, 0)");
          double xRot = -180 + (180 - -180) * (offset / 100);
          text.text = xRot.toStringAsFixed(1);
          turtleRenderer.renderInternal();
        }
      });

    // top div for padding
    return DivElement()
      ..style.setProperty("margin", "10px 0")
      // background of slider
      ..children.add(background = DivElement()
        ..style.setProperty("background-color", "#333333")
        ..style.setProperty("border-radius", "5px")
        ..onMouseDown.listen((event) {
          dragging = true;
          disableTextHighlight();
        })
        ..children.add(DivElement()
          ..style.setProperty("position", "relative")
          ..style.setProperty("width", "100%")
          ..style.setProperty("height", "0")
          ..style.setProperty("display", "flex")
          ..style.setProperty("justify-content", "center")
          ..children.addAll([
            ParagraphElement()
              ..text = prefix
              ..style.setProperty("margin", "0"),
            text = ParagraphElement()
              ..id = id
              ..text = "0"
              ..style.setProperty("margin", "0")
              ..style.setProperty("text-align", "center")
          ])
          ..style.setProperty("z-index", "100"))
        // filler div for translation
        ..children.add(DivElement()
          ..children.add(filler = DivElement()
            ..style.setProperty("transform", "translate(50%, 0)")
            ..style.setProperty("margin", "0 10px")
            ..children.add(DivElement()
              ..style.setProperty("width", "20px")
              ..style.setProperty("height", "20px")
              ..style.setProperty("transform", "translate(-50%, 0)")
              ..style.setProperty("background-color", "#444444")
              ..style.setProperty("border-radius", "5px")))));
  }

  void disableTextHighlight() {
    document.body?.style.setProperty("user-select", "none");
  }

  void enableTextHighlight() {
    document.body?.style.removeProperty("user-select");
  }

  String? getAxiom() {
    return (document.getElementById("axiom") as InputElement).value;
  }
}
