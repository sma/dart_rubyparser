part of 'rainbowsend.dart';

class Entity {
  late int id;
  late String name;
  final orders = Array<Order>();
  final events = Array<String>();

  Entity(this.id, this.name);

  String get nameid => '$name [$id]';

  void event(String message) {
    events.add('${$slot}: $message.');
  }

  void quote(List<Object> args) {
    var buf = '${$slot}: >';
    for (var arg in args) {
      buf += ' ';
      final arg1 = arg.toString();
      if (arg1.contains(' ')) {
        buf += '"$arg"';
      } else {
        buf += arg1;
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
      final i = orders.index(o) + 1;
      while (orders.length < Maxorders) {
        orders.insert(i, Order(Order.Null, Array()));
      }
    });
  }
}
