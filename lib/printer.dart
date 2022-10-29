// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

// current indentation
String indent = '';

// current line
String line = '';

/**
 * Appends [s] to the current line.
 */
void emit(String s) {
  line += s;
}

/**
 * Prints the current line and adapts the indent.
 * If [i] is < 0, the current line is dedented.
 * If [i] is > 0, the next line is indented.
 */
void nl([int i = 0]) {
  if (i < 0) {
    indent = indent.substring(0, indent.length - 2);
  }
  if (line.isNotEmpty) {
    print(indent + line);
    line = '';
  }
  if (i > 0) {
    indent += '  ';
  }
}

/**
 * Prints the given [ast] by using the [Printer] functions from [dartMethods].
 */
void pp(AST ast) {
  final printer = dartMethods[ast.type];
  if (printer == null) {
    throw 'missing printer function for $ast';
  }
  printer(ast);
}

/**
 * Defines a function that gets an AST node.
 */
typedef Printer = void Function(AST ast);

/**
 * Returns a printer function for the binary operator [op].
 * It will recursively print the left and right expressions, in parenthesis, separated by [op].
 */
Printer op(String op) {
  return (ast) {
    emit('(');
    pp(ast['left']);
    emit(' $op ');
    pp(ast['right']);
    emit(')');
  };
}

final rubyMethods = <String, Printer>{
  'assignment': (ast) {
    for (final target in ast['targetList'] as List<AST>) {
      pp(target);
      emit(',');
    }
    line = line.substring(0, line.length - 1);
    emit(' = ');
    for (final expr in ast['exprList'] as List<AST>) {
      pp(expr);
      emit(',');
    }
    line = line.substring(0, line.length - 1);
  },
  'block': (ast) {
    final list = ast['list'] as List<AST>;
    for (final stmt in list) {
      pp(stmt);
      nl();
    }
  },
  'globalvar': (ast) {
    emit('\$${ast.name}');
  },
  'doblock': (ast) {
    emit(' do');
    nl(1);
    final params = ast['params'] as List<AST>;
    if (params.isNotEmpty) {
      emit('|');
      for (final param in params) {
        emit(' ');
        pp(param);
      }
      emit(' | ');
    }
    nl();
    pp(ast['block']);
    emit('end');
    nl(-1);
  },
  'var': (ast) {
    emit(ast.name);
  },
  'instvar': (ast) {
    emit('@${ast.name}');
  },
  'const': (ast) {
    emit(ast.name);
  },
  'def': (ast) {
    emit('def ');
    if (ast['classname'] != null) {
      emit(ast['classname'] as String);
      emit('.');
    }
    emit(ast.name);
    emit('(');
    final params = ast['params'] as List<AST>;
    for (final param in params) {
      pp(param);
      emit(',');
    }
    if (params.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(')');
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
  },
  'param': (ast) {
    emit(ast.name);
    if (ast['init'] != null) {
      emit('=');
      pp(ast['init']!);
    }
  },
  'restparam': (ast) {
    emit('*');
    emit(ast.name);
  },
  'if': (ast) {
    emit('if ');
    pp(ast['expr']);
    nl(1);
    pp(ast['then']);
    if (ast['else'] != null) {
      nl(-1);
      emit('else');
      nl(1);
      pp(ast['else']);
    }
    nl(-1);
    emit('end');
  },
  '==': op('=='),
  '!=': op('!='),
  '>=': op('>='),
  '<=': op('<='),
  '>': op('>'),
  '<': op('<'),
  '||': op('||'),
  '&&': op('&&'),
  '<<': op('<<'),
  '=~': op('=~'),
  '+': op('+'),
  '-': op('-'),
  '*': op('*'),
  '/': op('/'),
  '%': op('%'),
  'mcall': (ast) {
    if (ast['expr'] != null) {
      pp(ast['expr']!);
      emit('.');
    }
    emit(ast.name);
    emit('(');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(')');
    final block = ast['doblock'] as AST?;
    if (block != null) {
      pp(block);
    }
  },
  '[]': (ast) {
    pp(ast['expr']);
    emit('[');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(']');
  },
  'case': (ast) {
    emit('case ');
    pp(ast['expr']);
    nl(1);
    final whens = ast['whens'] as List<AST>;
    for (final when in whens) {
      pp(when);
    }
    nl(-1);
    emit('end');
  },
  'when': (ast) {
    emit('when ');
    for (final expr in ast['exprList'] as List<AST>) {
      pp(expr);
      emit(',');
    }
    line = line.substring(0, line.length - 1);
    nl(1);
    pp(ast['block']);
    nl(-1);
  },
  'lit': (ast) {
    Object? value = ast['value'];
    if (value is String) {
      value = '"${value.replaceAll('"', '\\"')}"';
    }
    if (value is num) {
      if (value == value.truncate()) {
        value = value.truncate();
      }
    }
    emit('$value');
  },
  'relit': (ast) {
    emit("/${ast['value']}/");
  },
  '::': (ast) {
    pp(ast['expr']);
    emit('::');
    emit(ast.name);
  },
  'array': (ast) {
    emit('[');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(']');
  },
  'not': (ast) {
    emit('(!');
    pp(ast['expr']);
    emit(')');
  },
  'class': (ast) {
    emit('class ');
    emit(ast.name);
    if (ast['superclass'] != null) {
      emit(' < ');
      pp(ast['superclass']!);
    }
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
  },
  'attr_accessor': (ast) {
    final symbols = ast['list'] as List<String>;
    for (final symbol in symbols) {
      emit('def $symbol() @$symbol end');
      nl();
      emit('def $symbol=(obj) @$symbol=obj end');
      nl();
    }
  },
  'attr_reader': (ast) {
    final symbols = ast['list'] as List<String>;
    for (final symbol in symbols) {
      emit('def $symbol() @$symbol end');
      nl();
    }
  },
  'for': (ast) {
    emit('for ');
    pp(ast['target']);
    emit(' in ');
    pp(ast['expr']);
    emit(' do ');
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
  },
  '..': op('..'),
  '...': op('...'),
  'next': (ast) {
    emit('exit');
  },
  '+=': (ast) {
    pp(ast['target']);
    emit(' += ');
    pp(ast['expr']);
  },
  '-=': (ast) {
    pp(ast['target']);
    emit(' -= ');
    pp(ast['expr']);
  },
  'alias': (ast) {
    emit('alias ');
    emit(":${ast['old']}");
    emit(' ');
    emit(":${ast['new']}");
  },
  'self': (ast) {
    emit('self');
  },
  'super': (ast) {
    emit('super');
  },
  '<=>': op('<=>'),
  'dowhile': (ast) {
    emit('begin');
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
    emit(' while ');
    pp(ast['expr']);
  },
  'symbol': (ast) {
    emit(':${ast.name}');
  },
  'while': (ast) {
    emit('while ');
    pp(ast['expr']);
    emit(' do');
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
  },
  'break': (ast) => emit('break'),
  'ensure': (ast) => emit('ensure'),
  'rescue': (ast) => emit('rescue'),
  'splat': (ast) {
    emit('*');
    pp(ast['expr']);
  },
  '?:': (ast) {
    emit('(');
    pp(ast['expr']);
    emit(' ? ');
    pp(ast['then']);
    emit(' : ');
    pp(ast['else']);
    emit(')');
  },
  'return': (ast) {
    emit('return');
    if (ast['expr'] != null) {
      emit(' ');
      pp(ast['expr']);
    }
  },
  'neg': (ast) {
    emit('(-');
    pp(ast['expr']);
    emit(')');
  },
  'module': (ast) {
    emit('module ');
    emit(ast.name);
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit('end');
  }
};

/**
 * Emits a block with an optional return statment for the last statement.
 */
void returnblock(AST ast, {bool ret = false}) {
  final stmts = ast['list'] as List<AST>;
  var rescue = false, ensure = false;
  for (final stmt in stmts) {
    if (stmt.type == 'rescue') rescue = true;
    if (stmt.type == 'ensure') ensure = true;
  }
  if (rescue || ensure) {
    emit('try {');
    nl(1);
  }
  for (var i = 0; i < stmts.length; i++) {
    if (ret && i == stmts.length - 1 && !['for', 'if', 'block'].contains(stmts[i].type)) {
      emit('return ');
    }
    pp(stmts[i]);
    if (!line.endsWith('}') && line.trim().isNotEmpty) {
      emit(';');
    }
    nl();
  }
  if (rescue || ensure) {
    emit('}');
    nl(-1);
  }
}

/**
 * Makes Ruby names usable with Dart.
 * Replaces a trailing `?` with `_Q`, a trailing `!` with `_B`, and a trailing `=` with `_E`.
 */
String fixname(String name) {
  return name.replaceFirst('?', '_Q').replaceFirst('!', '_B').replaceFirst('=', '_E');
}

String? className;

final dartMethods = <String, Printer>{
  'assignment': (ast) {
    final targetList = ast['targetList'] as List<AST>;
    final exprList = ast['exprList'] as List<AST>;
    if (exprList.length < targetList.length) {
      emit('var ');
      for (final target in targetList) {
        pp(target);
        emit(',');
      }
      line = line.substring(0, line.length - 1);
      emit(' = ');
      for (final expr in exprList) {
        pp(expr);
        emit(',');
      }
      line = line.substring(0, line.length - 1);
      return;
    }
    for (var i = 0; i < targetList.length; i++) {
      if (targetList[i].type == 'var') {
        emit('var ');
      }
      pp(targetList[i]);
      emit(' = ');
      pp(exprList[i]);
      if (i == targetList.length - 1) {
        if (exprList.length > targetList.length) {
          for (var j = i + 1; j < exprList.length; j++) {
            emit(',');
            pp(exprList[j]);
          }
        }
      } else {
        emit(';');
        nl();
      }
    }
  },
  'block': (ast) {
    returnblock(ast);
  },
  'globalvar': (ast) {
    emit('\$${ast.name}');
  },
  'doblock': (ast) {
    emit('(');
    final params = ast['params'] as List<AST>;
    for (final param in params) {
      pp(param);
      emit(',');
    }
    if (params.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(') {');
    nl(1);
    returnblock(ast['block'], ret: true);
    nl(-1);
    emit('}');
  },
  'var': (ast) {
    emit(fixname(ast.name));
  },
  'instvar': (ast) {
    emit('this.${ast.name}');
  },
  'const': (ast) {
    emit(ast.name);
  },
  'def': (ast) {
    if (ast['classname'] != null) {
      if (ast['classname'] != className) {
        emit(ast['classname'] as String);
        emit('.');
      } else {
        emit('static ');
      }
    }
    if (ast.name == 'initialize' && className != null) {
      emit(className!);
    } else {
      emit(fixname(ast.name));
    }
    emit('(');
    final params = ast['params'] as List<AST>;
    for (final param in params) {
      pp(param);
      emit(',');
    }
    if (params.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(') {');
    nl(1);
    returnblock(ast['block'], ret: ast.name != 'initialize');
    nl(-1);
    emit('}');
  },
  'param': (ast) {
    if (ast['init'] != null) {
      emit('[');
      emit(ast.name);
      emit('=');
      pp(ast['init']);
      emit(']');
    } else {
      emit(ast.name);
    }
  },
  'restparam': (ast) {
    //TODO
    emit('*');
    emit(ast.name);
  },
  'if': (ast) {
    emit('if (');
    pp(ast['expr']);
    emit(') {');
    nl(1);
    returnblock(ast['then']);
    if (ast['else'] != null) {
      nl(-1);
      emit('} else {');
      nl(1);
      returnblock(ast['else']);
    }
    nl(-1);
    emit('}');
  },
  '==': op('=='),
  '!=': op('!='),
  '>=': op('>='),
  '<=': op('<='),
  '>': op('>'),
  '<': op('<'),
  '||': op('||'),
  '&&': op('&&'),
  '<<': op('<<'),
  '=~': op('=~'), //TODO
  '+': op('+'),
  '-': op('-'),
  '*': op('*'),
  '/': op('/'),
  '%': op('%'),
  'mcall': (ast) {
    final isNew = ast.name == 'new';
    if (ast['expr'] != null) {
      if (isNew) emit('new ');
      pp(ast['expr']);
      if (!isNew) emit('.');
    }
    if (!isNew) emit(fixname(ast.name));
    emit('(');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    final block = ast['doblock'] as AST?;
    if (block != null) {
      pp(block);
    } else {
      if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    }
    emit(')');
  },
  '[]': (ast) {
    pp(ast['expr']);
    emit('[');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    emit(']');
  },
  'case': (ast) {
    emit('switch (');
    pp(ast['expr']);
    emit(') {');
    nl(1);
    final whens = ast['whens'] as List<AST>;
    for (final when in whens) {
      pp(when);
    }
    nl(-1);
    emit('}');
  },
  'when': (ast) {
    for (final expr in ast['exprList'] as List<AST>) {
      emit('case ');
      pp(expr);
      emit(':');
      if (line == 'case true:') {
        line = 'default:';
      }
      nl();
    }
    nl(1);
    returnblock(ast['block']);
    emit('break;');
    nl();
    nl(-1);
  },
  'lit': (ast) {
    Object? value = ast['value'];
    if (value is String) {
      value = '"${value.replaceAll('"', '\\"')}"';
    }
    if (value is num) {
      if (value == value.truncate()) {
        value = value.truncate();
      }
    }
    emit('$value');
  },
  'relit': (ast) {
    emit("new RegExp(r\"${ast['value']}\")");
  },
  '::': (ast) {
    pp(ast['expr']);
    emit('.');
    emit(ast.name);
  },
  'array': (ast) {
    emit('new Array.from([');
    final args = ast['args'] as List<AST>;
    for (final arg in args) {
      pp(arg);
      emit(',');
    }
    if (args.isNotEmpty) line = line.substring(0, line.length - 1);
    emit('])');
  },
  'not': (ast) {
    emit('(!');
    pp(ast['expr']);
    emit(')');
  },
  'class': (ast) {
    emit('class ');
    emit(ast.name);
    if (ast['superclass'] != null) {
      emit(' extends ');
      pp(ast['superclass']);
    }
    emit(' {');
    nl(1);
    className = ast.name;
    returnblock(ast['block']);
    className = null;
    nl(-1);
    emit('}');
  },
  'attr_accessor': (ast) {
    emit('var ');
    final symbols = ast['list'] as List<String>;
    for (final symbol in symbols) {
      emit('$symbol,');
    }
    line = line.substring(0, line.length - 1);
  },
  'attr_reader': (ast) {
    emit('final ');
    final symbols = ast['list'] as List<String>;
    for (final symbol in symbols) {
      emit('$symbol,');
    }
    line = line.substring(0, line.length - 1);
  },
  'for': (ast) {
    emit('for (');
    pp(ast['target']);
    emit(' in ');
    pp(ast['expr']);
    emit(') {');
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit('}');
  },
  '..': (ast) {
    emit('new Range.incl(');
    pp(ast['left']);
    emit(',');
    pp(ast['right']);
    emit(')');
  },
  '...': (ast) {
    emit('new Range.excl(');
    pp(ast['left']);
    emit(',');
    pp(ast['right']);
    emit(')');
  },
  'next': (ast) {
    emit('continue');
  },
  '+=': (ast) {
    pp(ast['target']);
    emit(' += ');
    pp(ast['expr']);
  },
  '-=': (ast) {
    pp(ast['target']);
    emit(' -= ');
    pp(ast['expr']);
  },
  'alias': (ast) {},
  'self': (ast) {
    emit('this');
  },
  'super': (ast) {
    emit('super');
  },
  '<=>': op('<=>'), //TODO
  'dowhile': (ast) {
    emit('do {');
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit('} while (');
    pp(ast['expr']);
    emit(')');
  },
  'symbol': (ast) {
    emit("'${ast.name}'");
  },
  'while': (ast) {
    emit('while (');
    pp(ast['expr']);
    emit(') {');
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit('}');
  },
  'break': (ast) => emit('break'),
  'ensure': (ast) {
    emit('}');
    nl(-1);
    emit('finally {');
    nl(1);
  },
  'rescue': (ast) {
    emit('}');
    nl(-1);
    emit('catch (e) {');
    nl(1);
  },
  'splat': (ast) {
    emit('*');
    pp(ast['expr']);
  },
  '?:': (ast) {
    emit('(');
    pp(ast['expr']);
    emit(' ? ');
    pp(ast['then']);
    emit(' : ');
    pp(ast['else']);
    emit(')');
  },
  'return': (ast) {
    emit('return');
    if (ast['expr'] != null) {
      emit(' ');
      pp(ast['expr']);
    }
  },
  'neg': (ast) {
    emit('(-');
    pp(ast['expr']);
    emit(')');
  },
  'module': (ast) {
    //TODO
    emit('class ');
    emit(ast.name);
    emit(' {');
    nl(1);
    className = ast.name;
    returnblock(ast['block']);
    className = null;
    emit('}');
    nl(-1);
  }
};

/*

List of AST nodes:

block           list
module          name block
break
next
return          expr
alias           old new
attr_reader     list
attr_accessor   list
dowhile         expr block
class           name superclass block
def             name classname params block
if              expr then else
while           expr block
for             target expr block
when            exprList block
case            whens
assignment      targetList exprList
+=              target expr
-=              target expr
?:              expr then else
..              left right
...             left right
||              left right
&&              left right
==              left right
!=              left right
<=>             left right
===             left right
=~              left right
<               left right
>               left right
<=              left right
>=              left right
<<              left right
+               left right
-               left right
*               left right
/               left right
%               left right
neg             expr
not             expr
splat           expr
mcall           expr name args doblock
[]              expr args
::              expr name
doblock         params block
lit             value
relit           value
self
super
array           args
var             name
instvar         name
globalvar       name
const           name
symbol          name
param           name init
restparam       name
 */
