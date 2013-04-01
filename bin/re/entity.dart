part of rainbowsend;

class Entity {
  int id;
  String name;
  final Array<Order> orders = new Array();
  final Array<String> events = new Array();

  String get nameid => "${name} [${id}]";

  void event(String message) {
    events.add("${$slot}: ${message}.");
  }

  void quote(List<Object> args) {
    var buf = "${$slot}: >";
    for (var arg in args) {
      buf += " ";
      arg = arg.toString();
      if (arg.contains(" ")) {
        buf += '"${arg}"';
      } else {
        buf += arg;
      }
    }
    events.add(buf);
  }
}
