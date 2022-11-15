class TreeNode {
  String value;
  List<TreeNode> children = [];

  TreeNode(this.value);

  addNode(TreeNode node) {
    children.add(node);
  }
}