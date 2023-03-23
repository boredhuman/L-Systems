import 'dart:html';

class TreeNode {
  String value;
  List<TreeNode> children = [];
  bool laidOut = false;
  Element? stalk;
  Element? self;
  Element? childNodeSpanLine;
  Element? lineFromNodeToSpanLine;
  String color;

  TreeNode(this.value, this.color);

  addNode(TreeNode node) {
    children.add(node);
  }
}