import 'dart:html';
import 'dart:math';
import 'dart:svg';

import 'production_rule.dart';
import 'save_load.dart';
import 'string_view.dart';
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
  int nodeCount = 0;

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
              ..children.addAll([
                InputElement()
                  ..id = "axiom"
                  ..value = ""
                  ..placeholder = "axiom"
                  ..style.setProperty("margin", "10px auto")
                  ..style.setProperty("text-align", "center")
                  ..style.setProperty("border-radius", "5px"),
                // createProductionRule("A", "AB", null),
                // createProductionRule("B", "A", null),
                ParagraphElement()
                  ..text = "Add Production Rule"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    Element clicked = event.target as Element;

                    clicked.parent!.insertBefore(createProductionRule(null, null, null), clicked);
                  }),
                ParagraphElement()
                  ..text = "Clear Production Rules"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    List<Node> productionRules = document.getElementsByClassName("pr");

                    for (int i = productionRules.length - 1; i > -1; i--) {
                      productionRules[i].remove();
                    }
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
                    // createTurtleConfigRow("Forward", "F", 1),
                    // createTurtleConfigRow("Z Rotation", "-", -90),
                    // createTurtleConfigRow("Z Rotation", "+", 90),
                    ParagraphElement()
                      ..id = "addSymbolRow"
                      ..text = "Add Symbol Row"
                      ..classes.addAll(["btn"])
                      ..onClick.listen((event) {
                        (event.currentTarget! as Element)
                            .parent!
                            .insertBefore(createTurtleConfigRow("Forward", "F", 1), event.currentTarget as Element);
                      }),
                    ParagraphElement()
                      ..text = "Clear Turtle Map"
                      ..classes.addAll(["btn"])
                      ..onClick.listen((event) {
                        List<Node> productionRules = document.getElementsByClassName("turtleConfigRow");

                        for (int i = productionRules.length - 1; i > -1; i--) {
                          productionRules[i].remove();
                        }
                      }),
                    createSlider("X Rot:", "xRot"),
                    createSlider("Y Rot:", "yRot"),
                    createSlider("Z Rot:", "zRot")
                  ]),
                // current generation display and step size configuration
                DivElement()
                  ..classes.add("spacedRow")
                  ..children.addAll([
                    ParagraphElement()
                      ..style.setProperty("margin", "0")
                      ..text = "Current Generation"
                      ..style.setProperty("white-space", "nowrap"),
                    ParagraphElement()
                      ..id = "currentGeneration"
                      ..text = "0"
                      ..style.setProperty("margin", "0 1px"),
                  ]),
                // step size
                DivElement()
                  ..classes.add("spacedRow")
                  ..children.addAll([
                    ParagraphElement()
                      ..style.setProperty("margin", "0")
                      ..text = "Step Size"
                      ..style.setProperty("white-space", "nowrap"),
                    InputElement()
                      ..id = "stepSize"
                      ..setAttribute("type", "number")
                      ..setAttribute("min", "1")
                      ..style.setProperty("width", "40px")
                      ..style.setProperty("margin", "0 1px")
                      ..style.setProperty("text-align", "center")
                      ..value = "1"
                  ]),
                DivElement()
                  ..classes.add("spacedRow")
                  ..children.addAll([
                    ParagraphElement()
                      ..style.setProperty("margin", "0")
                      ..text = "Node Count"
                      ..style.setProperty("white-space", "nowrap"),
                    ParagraphElement()
                      ..id = "nodeCount"
                      ..text = 0.toString()
                  ]),
                ParagraphElement()
                  ..text = "Recenter"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    treeRenderer.recenter();
                    turtleRenderer.recenter();
                  }),
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

                      // for (var node in nodes) {
                      //   applyProductionRulesToNode(productionRulesMap, node);
                      // }
                      applyProductionRulesToNode(productionRulesMap, StringView(nodes));

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
                    ParagraphElement nodeCount = document.getElementById("nodeCount") as ParagraphElement;
                    nodeCount.text = this.nodeCount.toString();
                  }),
                ParagraphElement()
                  ..text = "Reset"
                  ..classes.addAll(["btn"])
                  ..onClick.listen(reset),
                ParagraphElement()
                  ..text = "Save Project"
                  ..classes.addAll(["btn"])
                  ..onClick.listen(SaveLoad.save),
                InputElement(type: "file")
                  ..style.setProperty("width", "100%")
                  ..onChange.listen(SaveLoad.load),
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

                if (iterations == 0) {
                  return;
                }

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

  Map<String, List<TurtleOption>> getTurtleConfig() {
    List<Node> turtleOptions = document.getElementsByClassName("turtleOption");
    Map<String, List<TurtleOption>> turtleOptionsMap = {};

    for (Node turtleOptionElement in turtleOptions) {
      if (turtleOptionElement is Element) {
        // command such as move forward, turn left, turn right
        String command = (turtleOptionElement.children[2] as SelectElement).value!;
        // the lhs of the production rule
        String symbol = (turtleOptionElement.children[3] as InputElement).value!;
        // the rhs of the production rule
        String value = (turtleOptionElement.children[4] as InputElement).value!;

        TurtleOption turtleOption = TurtleOption(command, symbol, double.parse(value));

        List<TurtleOption>? options = turtleOptionsMap.putIfAbsent(symbol, () => []);

        options.add(turtleOption);
      }
    }

    return turtleOptionsMap;
  }

  void reset(event) {
    String renderMode = (document.getElementById("renderMode") as SelectElement).value!;
    InputElement axiomElement = document.getElementById("axiom") as InputElement;
    root = TreeNode(axiomElement.value!);
    iterations = 0;
    this.nodeCount = 0;
    setCurrentGeneration(iterations);

    ParagraphElement nodeCount = document.getElementById("nodeCount") as ParagraphElement;
    nodeCount.text = this.nodeCount.toString();
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
      ..classes.add("turtleConfigRow")
      ..style.setProperty("display", "flex")
      ..style.setProperty("margin-top", "5px")
      ..classes.addAll(["turtleOption"])
      ..children.addAll([
        ParagraphElement()
          ..text = "^"
          ..style.setProperty("margin", "0 2px")
          ..style.setProperty("min-width", "20px")
          ..classes.add("btn")
          ..onClick.listen((event) {
            Element current = (event.currentTarget as Element).parent!;
            if (current.previousElementSibling != null && current.previousElementSibling!.classes.contains("turtleConfigRow")) {
              current.parent!.insertBefore(current, current.previousElementSibling);
            }
          }),
        ParagraphElement()
          ..text = "^"
          ..style.setProperty("margin", "0 2px")
          ..style.setProperty("min-width", "20px")
          ..style.setProperty("transform", "rotate(180deg)")
          ..classes.add("btn")
          ..onClick.listen((event) {
            Element current = (event.currentTarget as Element).parent!;
            if (current.nextElementSibling != null && current.nextElementSibling!.classes.contains("turtleConfigRow")) {
              current.parent!.insertBefore(current.nextElementSibling!, current);
            }
          }),
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
              ..text = "Z Rotation",
            OptionElement()
              ..value = "Push State"
              ..text = "Push State",
            OptionElement()
              ..value = "Pop State"
              ..text = "Pop State"
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

  void applyProductionRulesToNode(Map<String, ProductionRule> productionRulesMap, StringView stringView) {
    bool hasLengthTwoLHS = false;
    bool hasLengthThreeLHS = false;
    productionRulesMap.entries.toList().forEach((element) {
      if (element.key.length == 2) {
        hasLengthTwoLHS = true;
      } else if (element.key.length == 3) {
        hasLengthThreeLHS = true;
      }
    });

    List<bool> mappedChars = List.filled(stringView.totalLength, false);
    // iterate over each character cna check if there is production rule for it
    String? symbol;
    int index = 0;
    while ((symbol = stringView.nextSymbol()) != null) {
      ProductionRule? rhs = productionRulesMap[symbol];
      bool applied = false;
      if (rhs != null) {
        stringView.currentNode.addNode(TreeNode(rhs.getRhs()));
        nodeCount++;
        mappedChars[index] = true;
        applied = true;
      }

      String? nextSymbol = stringView.peakNext();
      if (hasLengthTwoLHS && nextSymbol != null) {
        String substring = symbol! + nextSymbol;
        rhs = productionRulesMap[substring];

        if (rhs != null) {
          if (rhs.type == "CS") {
            // context sensitive
            // sensitive part is on the left
            if (rhs.midIndex == 1) {
              stringView.peakNextSymbolNode()!.addNode(TreeNode(rhs.getRhs()));
              nodeCount++;
              mappedChars[index + 1] = true;
            } else {
              // sensitive is on the right
              stringView.currentNode.addNode(TreeNode(rhs.getRhs()));
              nodeCount++;
              mappedChars[index] = true;
              applied = true;
            }
          } else {
            stringView.currentNode.addNode(TreeNode(rhs.getRhs()));
            nodeCount++;
            mappedChars[index] = true;
            mappedChars[index + 1] = true;
            applied = true;
          }
        }
      }

      String? nextDoubleSymbol = stringView.peakDouble();
      if (hasLengthThreeLHS && nextDoubleSymbol != null) {
        String substring = symbol! + nextSymbol! + nextDoubleSymbol;
        rhs = productionRulesMap[substring];

        if (rhs != null) {
          if (rhs.type == "CS") {
            stringView.peakNextSymbolNode()!.addNode(TreeNode(rhs.getRhs()));
            nodeCount++;
            mappedChars[index + 1] = true;
          } else {
            stringView.currentNode.addNode(TreeNode(rhs.getRhs()));
            nodeCount++;
            mappedChars[index] = true;
            mappedChars[index + 1] = true;
            mappedChars[index + 2] = true;
            applied = true;
          }
        }
      }

      // no mapping for this sub set of symbols so assume its a terminal and keep it
      if (!applied && !mappedChars[index]) {
        stringView.currentNode.addNode(TreeNode(symbol!));
        nodeCount++;
      }
      index++;
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

  DivElement createProductionRule(String? lhs, String? rhs, String? probability, {String? left, String? right}) {
    return DivElement()
      // pr = production rule
      ..classes.addAll(["pr"])
      ..style.setProperty("padding-top", "5px")
      ..style.setProperty("display", "flex")
      ..style.setProperty("height", "25px")
      ..children.addAll([
        ParagraphElement()
          ..text = "^"
          ..style.setProperty("margin", "0 2px")
          ..style.setProperty("width", "20px")
          ..classes.add("btn")
          ..onClick.listen((event) {
            Element current = (event.currentTarget as Element).parent!;
            if (current.previousElementSibling != null && current.previousElementSibling!.classes.contains("pr")) {
              current.parent!.insertBefore(current, current.previousElementSibling);
            }
          }),
        ParagraphElement()
          ..text = "^"
          ..style.setProperty("margin", "0 2px")
          ..style.setProperty("width", "20px")
          ..style.setProperty("transform", "rotate(180deg)")
          ..classes.add("btn")
          ..onClick.listen((event) {
            Element current = (event.currentTarget as Element).parent!;
            if (current.nextElementSibling != null && current.nextElementSibling!.classes.contains("pr")) {
              current.parent!.insertBefore(current.nextElementSibling!, current);
            }
          }),
        SelectElement()
          ..classes.add("type")
          ..style.setProperty("margin-right", "5px")
          ..children.addAll([
            OptionElement()
              ..setAttribute("value", "CS")
              ..text = "CS",
            OptionElement()
              ..setAttribute("value", "NCF")
              ..text = "NCF"
          ]),
        // lhs
        InputElement()
          ..classes.addAll(["lhsLeft"])
          ..style.setProperty("width", "20px")
          ..setAttribute("maxlength", "1")
          ..style.setProperty("text-align", "center")
          ..style.setProperty("border-radius", "5px")
          ..value = left,
        InputElement()
          ..classes.addAll(["lhs"])
          ..style.setProperty("width", "20px")
          ..setAttribute("maxlength", "1")
          ..style.setProperty("text-align", "center")
          ..style.setProperty("border-radius", "5px")
          ..style.setProperty("margin", "0 2px")
          ..value = lhs,
        InputElement()
          ..classes.addAll(["lhsRight"])
          ..style.setProperty("width", "20px")
          ..setAttribute("maxlength", "1")
          ..style.setProperty("text-align", "center")
          ..style.setProperty("border-radius", "5px")
          ..value = right,
        ParagraphElement()
          ..text = "->"
          ..style.setProperty("margin", "0"),
        // rhs
        InputElement()
          ..classes.addAll(["rhs"])
          ..style.setProperty("width", "10px")
          ..style.setProperty("flex", "1")
          ..style.setProperty("border-radius", "5px")
          ..style.setProperty("text-align", "center")
          ..value = rhs,
        // probability
        InputElement()
          ..classes.addAll(["prob"])
          ..style.setProperty("width", "50px")
          ..style.setProperty("margin", "0 5px")
          ..style.setProperty("text-align", "center")
          ..style.setProperty("border-radius", "5px")
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
        InputElement lhs = node.getElementsByClassName("lhs").first as InputElement;
        InputElement lhsLeft = node.getElementsByClassName("lhsLeft").first as InputElement;
        InputElement lhsRight = node.getElementsByClassName("lhsRight").first as InputElement;
        InputElement rhs = node.getElementsByClassName("rhs").first as InputElement;
        InputElement prob = node.getElementsByClassName("prob").first as InputElement;
        SelectElement type = node.getElementsByClassName("type").first as SelectElement;

        String? lhsText = "${lhsLeft.value}${lhs.value}${lhsRight.value}";
        String rhsText = rhs.value ?? "";
        double probability = prob.value != null ? double.parse(prob.value!) : 0;

        if (lhsText.isNotEmpty) {
          ProductionRule? productionRule = productionRulesMap[lhsText];
          if (productionRule == null) {
            print(lhsText);
            print(lhsLeft.value != null);
            int midIndex = (lhsLeft.value != null && lhsLeft.value != "") && (lhsRight.value != null && lhsRight.value != "") ? 1 : 0;
            if (midIndex == 0 && (lhsLeft.value != null && lhsLeft.value != "")) {
              midIndex = 1;
            }
            print(midIndex);
            productionRule = ProductionRule(type.value!, midIndex);
            productionRulesMap[lhsText] = productionRule;
          }
          productionRule.addRHS(rhsText, probability);
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
