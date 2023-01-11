import 'dart:html';
import 'dart:svg';

import 'tree_node.dart';

class TreeRenderer {
  late Rectangle<num> svgContainerBoundingRect;
  Element svgContainer;

  TreeRenderer(this.svgContainer);

  // setup initial parameters
  void layoutTreeNodeInit(TreeNode node, int y, [bool? visibilityCheckOnly]) {
    Rectangle<num> boundingBox = svgContainer.parent!.getBoundingClientRect();
    int midPoint = boundingBox.width ~/ 2;
    var rect = svgContainer.parent!.getBoundingClientRect();
    // since the nodes vertices are given relate to the svgContainers top left we translate the bounding rect by that point so its in the same
    // space as the node vertices
    int xOffset = 0;
    int yOffset = 0;
    if (svgContainer.hasAttribute("transform")) {
      String? transform = svgContainer.getAttribute("transform");
      if (transform != null) {
        var translation =
            transform.substring(transform.indexOf("(") + 1, transform.indexOf(")")).split(" ").map((number) => int.parse(number)).toList();
        xOffset = -translation[0];
        yOffset = -translation[1];
      }
    }

    svgContainerBoundingRect = Rectangle(xOffset, yOffset, rect.width.toInt(), rect.height.toInt());
    layoutTreeNode(node, midPoint, y, visibilityCheckOnly ?? false);
  }

  updateElement(Element element, int x, int y, int right, int bottom) {
    bool visible = isVisible(element, x, y, right, bottom);
    if (element.parent != null && !visible) {
      element.remove();
    } else if (visible) {
      svgContainer.children.add(element);
    }
  }

  bool isVisible(Element element, int x, int y, int right, int bottom) {
    int svgRight = svgContainerBoundingRect.right.toInt();
    int svgLeft = svgContainerBoundingRect.left.toInt();
    int svgTop = svgContainerBoundingRect.top.toInt();
    int svgBottom = svgContainerBoundingRect.bottom.toInt();

    // there is an overlap
    return ((right > svgRight && x < svgRight) ||
        (right > svgLeft && x < svgLeft) ||
        (y < svgTop && bottom > svgTop) ||
        (y < svgBottom && bottom > svgBottom) ||
        (x > svgLeft && right < svgRight && y > svgTop && bottom < svgBottom));
  }

  void layoutTreeNode(TreeNode node, int midPoint, int y, bool visibilityCheckOnly) {
    if (node.children.isEmpty) {
      return;
    }
    List<int> widths = [];
    int totalWidth = 0;

    // get the width for each child node and sum them up
    for (TreeNode child in node.children) {
      int width = getNodeWidth(child);
      widths.add(width);
      totalWidth += width;
    }

    int xStart = midPoint - totalWidth ~/ 2;
    int rowStart = -1;
    int rowEnd = -1;

    for (int i = 0; i < node.children.length; i++) {
      int nodeWidth = widths[i];
      xStart += nodeWidth ~/ 2;
      TreeNode childNode = node.children[i];

      if (!node.laidOut) {
        // background and text
        updateElement(
            childNode.self = ForeignObjectElement()
              ..setAttribute("x", "${xStart - 50}")
              ..setAttribute("y", "$y")
              ..setAttribute("width", "100")
              ..setAttribute("height", "25")
              ..classes.add("nodeBox")
              ..children.add(ParagraphElement()
                ..text = childNode.value
                ..classes.add("nodeText")),
            xStart,
            y,
            xStart + 50,
            y + 25);
        // line connecting node box to the parent line above
        updateElement(
            childNode.stalk = LineElement()
              ..setAttribute("x1", "$xStart")
              ..setAttribute("y1", "${y - 25 / 2}")
              ..setAttribute("x2", "$xStart")
              ..setAttribute("y2", "$y")
              ..setAttribute("stroke", "white"),
            xStart,
            y - 25 ~/ 2,
            xStart,
            y);
      } else {
        // background and text
        if (!visibilityCheckOnly) {
          childNode.self!
            ..setAttribute("x", "${xStart - 50}")
            ..setAttribute("y", "$y");
        }

        updateElement(childNode.self!, xStart - 50, y, xStart + 50, y + 25);

        // line connecting node box to the parent line above
        if (!visibilityCheckOnly) {
          childNode.stalk!
            ..setAttribute("x1", "$xStart")..setAttribute("y1", "${y - 25 / 2}")..setAttribute("x2", "$xStart")..setAttribute("y2", "$y");
        }

        updateElement(childNode.stalk!, xStart, y - 25 ~/ 2, xStart, y);
      }

      if (i == 0) {
        rowStart = xStart;
      } else if (i == node.children.length - 1) {
        rowEnd = xStart;
      }

      layoutTreeNode(childNode, xStart, y + 50, visibilityCheckOnly);

      xStart += nodeWidth ~/ 2;
    }

    if (node.children.isNotEmpty) {
      if (node.laidOut) {
        // line down to connect to children
        if (!visibilityCheckOnly) {
          node.lineFromNodeToSpanLine!
            ..setAttribute("x1", "$midPoint")
            ..setAttribute("y1", "${y - 25}")
            ..setAttribute("x2", "$midPoint")
            ..setAttribute("y2", "${y - 25 / 2}");
        }

        updateElement(node.lineFromNodeToSpanLine!, midPoint, y - 25, midPoint, y - 25 ~/ 2);

        // line from the top of the first child to the last child
        if (node.childNodeSpanLine != null) {
          if (!visibilityCheckOnly) {
            node.childNodeSpanLine!
              ..setAttribute("x1", "$rowStart")
              ..setAttribute("y1", "${y - 25 / 2}")
              ..setAttribute("x2", "$rowEnd")
              ..setAttribute("y2", "${y - 25 / 2}");
          }

          updateElement(node.childNodeSpanLine!, rowStart, y - 25 ~/ 2, rowEnd, y - 25 ~/ 2);
        }
      } else {
        // line down to connect to children
        updateElement(
            node.lineFromNodeToSpanLine = LineElement()
              ..setAttribute("x1", "$midPoint")
              ..setAttribute("y1", "${y - 25}")
              ..setAttribute("x2", "$midPoint")
              ..setAttribute("y2", "${y - 25 / 2}")
              ..setAttribute("stroke", "white"),
            midPoint,
            y - 25,
            midPoint,
            (y - 25 / 2).toInt());
        // line from the top of the first child to the last child
        if (rowStart != -1 && rowEnd != -1) {
          updateElement(
              node.childNodeSpanLine = LineElement()
                ..setAttribute("x1", "$rowStart")
                ..setAttribute("y1", "${y - 25 / 2}")
                ..setAttribute("x2", "$rowEnd")
                ..setAttribute("y2", "${y - 25 / 2}")
                ..setAttribute("stroke", "red"),
              rowStart,
              (y - 25 / 2).toInt(),
              rowEnd,
              (y - 25 / 2).toInt());
        }
      }
    }

    node.laidOut = true;
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
}
