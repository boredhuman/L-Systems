import 'tree_node.dart';

class StringView {
  List<TreeNode> nodes;
  int treeNodeIndex = 0;
  int nodeStringOffset = 0;
  late TreeNode currentNode = nodes[0];
  int totalLength = 0;

  StringView(this.nodes) {
    totalLength = nodes.map((e) => e.value.length).reduce((value, element) => value += element);
  }

  String? nextSymbol() {
    // check if node string offset is still within bounds of current nodes string
    if (nodeStringOffset >= currentNode.value.length) {
      // get next tree node
      if (treeNodeIndex + 1 < nodes.length) {
        currentNode = nodes[++treeNodeIndex];
        nodeStringOffset = 0;
        // no more tree nodes length
      } else {
        return null;
      }
    }
    // get character at node string offset then increment the offset
    return currentNode.value[nodeStringOffset++];
  }

  String? peakNext() {
    if (nodeStringOffset < currentNode.value.length) {
      return currentNode.value[nodeStringOffset];
    } else {
      if (treeNodeIndex + 1 < nodes.length) {
        return nodes[treeNodeIndex + 1].value[0];
      } else {
        return null;
      }
    }
  }

  TreeNode? peakNextSymbolNode() {
    if (nodeStringOffset < currentNode.value.length) {
      return currentNode;
    } else {
      if (treeNodeIndex + 1 < nodes.length) {
        return nodes[treeNodeIndex + 1];
      } else {
        return null;
      }
    }
  }

  String? peakDouble() {
    // check if we can source the symbol from the current node
    if (nodeStringOffset + 1 < currentNode.value.length) {
      return currentNode.value[nodeStringOffset + 1];
    } else {
      if (treeNodeIndex + 1 < nodes.length) {
        TreeNode treeNode = nodes[treeNodeIndex + 1];
        if (currentNode.value.length == 2) {
          return treeNode.value[0];
        } else if (treeNode.value.length > 1) {
          return treeNode.value[1];
        } else if (treeNodeIndex + 2 < nodes.length) {
          return nodes[treeNodeIndex + 2].value[0];
        }
      }
      return null;
    }
  }
}