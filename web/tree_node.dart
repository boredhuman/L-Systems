import 'dart:html';

class TreeNode {
  String value;
  List<TreeNode> children = [];
  bool laidOut = false;
  Element? stalk;
  Element? self;
  Element? childNodeSpanLine;
  Element? lineFromNodeToSpanLine;

  TreeNode(this.value);

  addNode(TreeNode node) {
    children.add(node);
  }
}