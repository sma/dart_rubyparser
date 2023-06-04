import 'package:rubyparser/rubyparser.dart';

/// Implements the usual lexicographic variable scoping.
class Scope {
  Scope(this.parent);

  final Scope? parent;
  final Map<String, Object?> values = {};

  /// Return a bound value or [unbound] if there no such such value.
  Object? operator [](String name) {
    for (Scope? scope = this; scope != null; scope = scope.parent) {
      if (scope.values.containsKey(name)) return scope.values[name];
    }
    return unbound;
  }

  /// Binds or rebinds a local value.
  void operator []=(String name, Object? value) {
    values[name] = value;
  }

  /// Evaluates [ast] in the current scope.
  Object? eval(AST ast) {
    final method = evalMethods[ast.type];
    if (method == null) throw 'missing eval for $ast';
    return method(this, ast);
  }

  static const unbound = Object();

  static final global = Scope(null);
}

/// Implements a user-defined function.
class Func {
  Func(this.definingScope, this.params, this.body);
  final Scope definingScope;
  final List<AST> params;
  final AST body;

  Object? call(List<Object?> args) {
    final scope = Scope(definingScope);
    for (var i = 0; i < params.length; i++) {
      if (params[i].type == 'restparam') throw _unsupported;
      if (i < args.length) {
        scope[params[i].name] = args[i];
      } else {
        final init = params[i]['init'] as AST?;
        scope[params[i].name] = init == null ? null : definingScope.eval(init);
      }
    }
    try {
      return scope.eval(body);
    } on _Return catch (r) {
      return r.value;
    }
  }
}

/// Implements the `return` statement, see [Func.call].
class _Return {
  _Return(this.value);
  final Object? value;
}

typedef Eval = dynamic Function(Scope, AST);

final evalMethods = <String, Eval>{
  'block': (scope, ast) {
    return _list(ast['list']).fold<Object?>(null, (_, ast) => scope.eval(ast));
  },
  'def': (scope, ast) {
    if (ast['classname'] != null) throw _unsupported;
    scope[ast.name] = Func(scope, _list(ast['params']), ast['block'] as AST);
    return ast.name;
  },
  'mcall': (scope, ast) {
    if (ast['expr'] != null) throw _unsupported;
    final func = scope[ast.name];
    if (func == Scope.unbound) throw 'unbound function ${ast.name}';
    final args = _list(ast['args']).map(scope.eval).toList();
    if (func is Func) return func.call(args);
    if (func is Object? Function()) return func.call();
    if (func is Object? Function(Object?)) return func.call(args.single);
    throw 'try calling non function $func';
  },
  'lit': (scope, ast) => ast['value'] as Object?,
  'if': (scope, ast) {
    final expr = scope.eval(ast['expr'] as AST) as bool;
    return scope.eval(ast[expr ? 'then' : 'else'] ?? AST('lit', {'value': null}));
  },
  '<': (scope, ast) => _op<num>(scope, ast, (a, b) => a < b),
  '+': (scope, ast) => _op<num>(scope, ast, (a, b) => a + b),
  '-': (scope, ast) => _op<num>(scope, ast, (a, b) => a - b),
  'var': (scope, ast) {
    final value = scope[ast.name];
    if (value == Scope.unbound) throw 'unbound name ${ast.name}';
    return value;
  },
  'return': (scope, ast) => throw _Return(scope.eval(ast['expr'] as AST))
};

List<AST> _list(dynamic asts) => asts as List<AST>;

Object? _op<T>(Scope scope, AST ast, Object? Function(T, T) op) {
  final left = scope.eval(ast['left'] as AST) as T;
  final right = scope.eval(ast['right'] as AST) as T;
  return op(left, right);
}

const _unsupported = 'not yet supported';

const fib = '''
def fib(n)
  return 1 if n < 3
  fib(n - 1) + fib(n - 2)
end
p "this takes a couple of seconds"
p fib 30''';

void main() {
  final ast = Parser(fib).parse();
  Scope.global['p'] = print;
  Scope.global.eval(ast);
}
