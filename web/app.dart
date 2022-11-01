import 'dart:html';

class App {
  App() {
    document.body!
      ..children.addAll([
        DivElement()
          ..style.setProperty("width", "1000px")
          ..style.setProperty("background-color", "#222222")
          ..style.setProperty("margin", "auto")
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
                  ..style.setProperty("margin", "auto"),
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
                              ..style.setProperty("width", "30px"),
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
                    TextAreaElement textAreaElement = document.getElementById("output") as TextAreaElement;
                    String? axiom = textAreaElement.text != null && textAreaElement.text!.isNotEmpty ? textAreaElement.text : axiomElement.value;

                    String output = "";

                    if (axiom != null) {
                      for (int i = 0; i < axiom.length; i++) {
                        String? rhs = productionRulesMap[axiom[i]];

                        if (rhs != null) {
                          output += rhs;
                        } else {
                          // symbol does not have a production rule so assume its a terminal and keep it
                          output += axiom[i];
                        }
                      }
                    }

                    textAreaElement.text = output;
                  }),
                TextAreaElement()
                  ..id = "output"
                  ..style.setProperty("width", "100%")
                  ..style.setProperty("pointer-events", "none")
              ])
          ])
      ])
      ..style.setProperty("background-color", "#111111")
      ..style.setProperty("overflow", "hidden")
      ..style.setProperty("margin-bottom", "200px");
  }
}
