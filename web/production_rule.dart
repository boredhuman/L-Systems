import 'dart:math';

class ProductionRule {
  List<MapEntry<String, double>> pairs = [];
  double sum = 0;
  Random random = Random();

  ProductionRule();

  void addRHS(String rhs, double probability) {
    pairs.add(MapEntry(rhs, probability));
  }

  void done() {
    List<MapEntry<String, double>> rhsList = pairs
      ..sort((left, right) {
        return left.value.compareTo(right.value);
      });
    sum = rhsList.map((e) => e.value).reduce((value, element) => value += element);
  }

  // get rhs will go thru the probabilities
  String getRhs() {
    if (pairs.isEmpty) {
      return "";
    }
    if (pairs.length == 1) {
      return pairs.first.key;
    } else {
      double rand = random.nextDouble() * sum;
      double offset = 0;
      for (MapEntry<String, double> r in pairs) {
        if (rand < offset + r.value) {
          return r.key;
        }
        offset += r.value;
      }
    }
    // fail safe should not be called
    return pairs.last.key;
  }
}
