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
    // node string offset is already one greater than it was before when next symbol was called so don't need + 1
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
      // check if we can get symbol from neighbouring node
      if (treeNodeIndex + 1 < nodes.length) {
        TreeNode treeNode = nodes[treeNodeIndex + 1];
        // we are gonna want the second symbol from this node if we are on the last symbol of the previous node
        // otherwise if we aren't we are gonna want the first
        // if we want the second symbol and the treeNode value length is less than 2 we have to get the first symbol from
        // the next node

        // true if we are on the last symbol of the previous node
        // so we want two get the second symbol
        if (nodeStringOffset == currentNode.value.length) {
          if (treeNode.value.length > 1) {
            return treeNode.value[1];
          } else {
            if (treeNodeIndex + 2 < nodes.length) {
              return nodes[treeNodeIndex + 2].value[0];
            }
          }
          // we want the first
        } else {
          return treeNode.value[0];
        }
      }
      return null;
    }
  }
}