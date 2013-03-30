part of rainbowsend;

class Entity {
  var id, name;
  List<Order> orders = [];
  List<String> events = [];

  get nameid => "${name} [${id}]";

  event(List<Object> args) {
    events.add("${G_slot}: ${args.join(' ')}.");
  }

  quote(List<Object> args) {
    var buf = "${G_slot}: >";
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
