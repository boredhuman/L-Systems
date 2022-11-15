import 'dart:html';
import 'dart:svg';

import 'tree_node.dart';

class App {
  late SvgSvgElement svgContainer;

  App() {
    TreeNode root = TreeNode("");
    int iterations = 0;
    int prevMouseX = 0;
    int prevMouseY = 0;
    bool dragging = false;

    document.body!
      ..style.setProperty("display", "flex")
      ..children.addAll([
        // l system configurations
        DivElement()
          ..style.setProperty("z-index", "1")
          ..style.setProperty("width", "400px")
          ..style.setProperty("background-color", "#222222")
          ..style.setProperty("height", "100%")
          ..style.setProperty("display", "flex")
          ..style.setProperty("justify-content", "center")
          ..style.setProperty("align-items", "center")
          ..style.setProperty("text-align", "center")
          ..style.setProperty("color", "white")
          ..children.addAll([
            DivElement()
              ..children.addAll([
                InputElement()
                  ..id = "axiom"
                  ..placeholder = "axiom"
                  ..style.setProperty("margin", "auto")
                  ..style.setProperty("text-align", "center"),
                ParagraphElement()
                  ..text = "Add Production Rule"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    Element clicked = event.target as Element;

                    clicked.parent!.insertBefore(
                        DivElement()
                          // pr = production rule
                          ..classes.addAll(["pr"])
                          ..style.setProperty("padding-top", "5px")
                          ..style.setProperty("display", "flex")
                          ..style.setProperty("height", "25px")
                          ..children.addAll([
                            InputElement()
                              ..classes.addAll(["lhs"])
                              ..style.setProperty("width", "30px")
                              // max length as all productions rules must be context free
                              ..setAttribute("maxlength", "1"),
                            ParagraphElement()
                              ..text = "->"
                              ..style.setProperty("margin", "0"),
                            InputElement()
                              ..classes.addAll(["rhs"])
                              ..style.setProperty("width", "10px")
                              ..style.setProperty("flex", "1")
                          ]),
                        clicked);
                  }),
                ParagraphElement()
                  ..text = "Compute"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    print('Computing');
                    List<Node> productionRules = document.getElementsByClassName("pr");
                    Map<String, String> productionRulesMap = {};

                    for (Node node in productionRules) {
                      if (node is Element) {
                        List<Node> lhs = node.getElementsByClassName("lhs");
                        List<Node> rhs = node.getElementsByClassName("rhs");

                        if (lhs.isNotEmpty && lhs[0] is InputElement && rhs.isNotEmpty && rhs[0] is InputElement) {
                          InputElement lhsElement = lhs[0] as InputElement;
                          InputElement rhsElement = rhs[0] as InputElement;
                          String? lhsText = lhsElement.value;
                          String? rhsText = rhsElement.value;

                          if (lhsText != null) {
                            productionRulesMap[lhsText] = rhsText ?? "";
                          }
                        }
                      }
                    }

                    InputElement axiomElement = document.getElementById("axiom") as InputElement;
                    String? axiom = axiomElement.value;

                    if (axiom == null || axiom.isEmpty) {
                      return;
                    }

                    // axiom has been changed
                    if (axiom != root.value) {
                      root = TreeNode(axiom);
                      iterations = 0;
                    }

                    // so we go over each node and convert each symbol in the value using the production rules
                    // we then set the next level to the first child of the current tree node
                    if (iterations == 0) {
                      root.value = axiom;
                    }

                    List<TreeNode> nodes = getElementsAtDepth(root, iterations, 0);

                    for (var node in nodes) {
                      applyProductionRulesToNode(productionRulesMap, node);
                    }

                    iterations += 1;

                    svgContainer.children.clear();
                    Rectangle<num> boundingBox = svgContainer.getBoundingClientRect();
                    int midPoint = boundingBox.width ~/ 2;
                    // fill TreeNode
                    layoutTreeNode(TreeNode("")..children.add(root), midPoint, 50);
                  }),
                ParagraphElement()
                  ..text = "Reset"
                  ..classes.addAll(["btn"])
                  ..onClick.listen((event) {
                    InputElement axiomElement = document.getElementById("axiom") as InputElement;
                    root = TreeNode(axiomElement.value!);
                    iterations = 0;

                    svgContainer.children.clear();
                    Rectangle<num> boundingBox = svgContainer.getBoundingClientRect();
                    int midPoint = boundingBox.width ~/ 2;
                    layoutTreeNode(TreeNode("")..children.add(root), midPoint, 50);
                  })
              ])
          ]),
        // l system rendering
        DivElement()
          ..style.setProperty("width", "100%")
          ..style.setProperty("height", "100%")
          ..onMouseDown.listen((event) {
            if (event.target.hashCode == svgContainer.parent.hashCode || event.target.hashCode == svgContainer.hashCode) {
              dragging = true;
              prevMouseX = event.client.x.toInt();
              prevMouseY = event.client.y.toInt();
            }
          })
          ..onMouseMove.listen((event) {
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
              }
            }
          })
          ..children.addAll([
            svgContainer = SvgSvgElement()
              ..id = "svgContainer"
              ..style.setProperty("width", "100%")
              ..style.setProperty("height", "100%")
          ])
      ])
      ..style.setProperty("background-color", "#111111")
      ..style.setProperty("overflow", "hidden")
      ..style.setProperty("margin-bottom", "200px");

    document.body!.onMouseUp.listen((event) {
      dragging = false;
    });
  }

  layoutTreeNode(TreeNode node, int midPoint, int y) {
    List<int> widths = [];
    int totalWidth = 0;

    for (TreeNode child in node.children) {
      int width = getNodeWidth(child);
      widths.add(width);
      totalWidth += width;
    }

    int xStart = midPoint - totalWidth ~/ 2;

    for (int i = 0; i < node.children.length; i++) {
      int nodeWidth = widths[i];
      xStart += nodeWidth ~/ 2;
      // draw rect
      svgContainer.children.addAll([
        ForeignObjectElement()
          ..setAttribute("x", "${xStart - 50}")
          ..setAttribute("y", "$y")
          ..setAttribute("width", "100")
          ..setAttribute("height", "25")
          ..style.setProperty("background-color", "#333")
          ..style.setProperty("border-radius", "3px")
          ..children.add(ParagraphElement()
            ..text = node.children[i].value
            ..style.setProperty("color", "white")
            ..style.setProperty("margin", "0")
            ..style.setProperty("margin-top", "3px")
            ..style.setProperty("text-align", "center"))
      ]);

      layoutTreeNode(node.children[i], xStart, y + 50);

      xStart += nodeWidth ~/ 2;
    }
  }

  int getNodeWidth(TreeNode node) {
    if (node.children.isNotEmpty) {
      int width = 0;
      for (TreeNode child in node.children) {
        width += getNodeWidth(child);
      }
      return width;
    } else {
      return 150;
    }
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

  applyProductionRulesToNode(Map<String, String> productionRulesMap, TreeNode node) {
    String string = node.value;
    // iterate over each character cna check if there is production rule for it
    // todo potentially add support for production rules longer than a single character
    for (int i = 0; i < string.length; i++) {
      String? rhs = productionRulesMap[string[i]];

      if (rhs != null) {
        node.addNode(TreeNode(rhs));
      } else {
        // symbol does not have a production rule so assume its a terminal and keep it
        node.addNode(TreeNode(string[i]));
      }
    }
  }
}
