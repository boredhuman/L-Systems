import 'dart:convert';
import 'dart:html';

import 'main.dart';

class SaveLoad {
  static load(event) {
    InputElement self = event.target as InputElement;
    if (self.files != null && self.files!.isNotEmpty) {
      File file = self.files![0];
      Blob blob = file.slice(0, file.size);
      FileReader()
        ..readAsText(blob)
        ..onLoadEnd.listen((event) {
          String jsonData = (event.target as FileReader).result as String;
          loadJson(jsonData);
        });
    }
  }

  static loadJson(String jsonData) {
    Map<String, dynamic> json = jsonDecode(jsonData);

    // symbol then field and value for turtleOption
    Map<dynamic, dynamic> turtleData = json["turtleData"];
    Map<dynamic, dynamic> productionRulesMap = json["productionRules"];

    InputElement axiomElement = document.getElementById("axiom") as InputElement;

    axiomElement.value = json["axiom"];

    for (MapEntry<dynamic, dynamic> rule in productionRulesMap.entries) {
      String lhs = rule.key;
      List<dynamic> pairs = rule.value["pairs"];
      for (dynamic pair in pairs) {
        String rhs = pair["key"];
        dynamic probability = pair["value"].toString();
        axiomElement.parent!.insertBefore(app.createProductionRule(lhs, rhs, probability), axiomElement.nextNode!);
      }
    }

    Element turtleConfigElement = document.getElementById("turtle config")!;
    Element addSymbolRowElement = document.getElementById("addSymbolRow")!;

    for (MapEntry<dynamic, dynamic> turtleConfigEntry in turtleData.entries) {
      List<dynamic> turtleConfigList = turtleConfigEntry.value;
      for (Map<dynamic, dynamic> turtleConfig in turtleConfigList) {
        Element turtleConfigRowElement = app.createTurtleConfigRow(turtleConfig["command"]!, turtleConfig["symbol"]!, turtleConfig["value"]!);
        turtleConfigElement.insertBefore(turtleConfigRowElement, addSymbolRowElement);
      }
    }
  }

  static save(event) {
    Map<String, dynamic> saveData = {};
    saveData["axiom"] = app.getAxiom();
    saveData["productionRules"] = app.getProductionRulesMap().map((key, value) => MapEntry(key, {
          "pairs": value.pairs.map((e) => {"key": e.key, "value": e.value}).toList()
        }));
    saveData["turtleData"] = app
        .getTurtleConfig()
        .map((key, value) => MapEntry(key, value.map((e) => {"value": e.value, "command": e.command, "symbol": e.symbol}).toList()));
    String saveDataText = JsonEncoder().convert(saveData);

    Element tempElement = document.createElement('a');
    tempElement.setAttribute('href', "data:text/plain;charset=utf-8,${Uri.encodeComponent(saveDataText)}");
    tempElement.setAttribute('download', "l-system.json");

    tempElement.style.display = 'none';
    document.body!.children.add(tempElement);

    tempElement.click();

    tempElement.remove();
  }
}
