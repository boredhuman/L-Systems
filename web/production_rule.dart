import 'dart:math';

class ProductionRule {
  List<MapEntry<String, MapEntry<double, String>>> pairs = [];
  double sum = 0;
  Random random = Random();
  String type;

  // this is when there is an identical string of length 2 but difference context sensitive symbols
  // this on has the last symbol as the context sensitive one
  ProductionRule? other;

  ProductionRule(this.type);

  void addRHS(String rhs, double probability, String colour, int midIndex) {
    if (type == "CS") {
      if (midIndex == 0) {
        pairs.add(MapEntry(rhs, MapEntry(probability, colour)));
      } else {
        other ??= ProductionRule(type);

        other!.addRHS(rhs, probability, colour, 0);
      }
    } else {
      pairs.add(MapEntry(rhs, MapEntry(probability, colour)));
    }
  }

  void done() {
    List<MapEntry<String, MapEntry<double, String>>> rhsList = pairs
      ..sort((left, right) {
        return left.value.key.compareTo(right.value.key);
      });
    sum = rhsList.map((e) => e.value.key).reduce((value, element) => value += element);

    other?.done();
  }

  // get rhs will go thru the probabilities
  MapEntry<String, String> getRhs() {
    if (pairs.isEmpty) {
      return MapEntry("", "Gray");
    }
    if (pairs.length == 1) {
      return MapEntry(pairs.first.key, pairs.first.value.value);
    } else {
      double rand = random.nextDouble() * sum;
      double offset = 0;
      for (MapEntry<String, MapEntry<double, String>> r in pairs) {
        if (rand < offset + r.value.key) {
          return MapEntry(r.key, r.value.value);
        }
        offset += r.value.key;
      }
    }
    // fail safe should not be called
    return MapEntry(pairs.last.key, "Gray");
  }
}
