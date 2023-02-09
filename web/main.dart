import 'app.dart';
import 'fibo_word_frac.dart';
import 'save_load.dart';

late App app;

void main() {
  app = App();
  SaveLoad.loadJson(FiboWordFrac.data);
}
