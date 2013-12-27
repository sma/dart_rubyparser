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

  void adjustorders() {
    orders.each((o) {
      if ((o.type != Order.Wait)) {
        return;
      }
      o.type = Order.Null;
      var i = orders.index(o) + 1;
      while (orders.length < Maxorders) {
        orders.insert(i, new Order(Order.Null,new Array()));
      }
    });
  }
}
