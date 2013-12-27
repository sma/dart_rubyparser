// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

// current indentation
String indent = "";

// current line
String line = "";

/**
 * Appends [s] to the current line.
 */
emit(String s) {
  line += s;
}

/**
 * Prints the current line and adapts the indent.
 * If [i] is < 0, the current line is dedented.
 * If [i] is > 0, the next line is indented.
 */
nl([i=0]) {
  if (i < 0) {
    indent = indent.substring(0, indent.length - 2);
  }
  if (!line.isEmpty) {
    print(indent + line);
    line = "";
  }
  if (i > 0) {
    indent += "  ";
  }
}

/**
 * Prints the given [ast] by using the [Printer] functions from [dartMethods].
 */
void pp(Map ast) {
  String type = ast['type'];
  Printer printer = dartMethods[type];
  if (printer == null) {
    throw "missing printer functino for $ast";
  }
  printer(ast);
}

/**
 * Defines a function that gets an AST node.
 */
typedef void Printer(Map ast);

/**
 * Returns a printer function for the binary operator [op].
 * It will recursively print the left and right expressions, in parenthesis, separated by [op].
 */
Printer op(String op) {
  return (Map ast) {
    emit("(");
    pp(ast['left']);
    emit(" $op ");
    pp(ast['right']);
    emit(")");
  };
}

Map<String, Printer> rubyMethods = {
   'assignment': (Map ast) {
     for (Map target in ast['targetList']) {
       pp(target);
       emit(",");
     }
     line = line.substring(0, line.length-1);
     emit(" = ");
     for (Map expr in ast['exprList']) {
       pp(expr);
      emit(",");
     }
     line = line.substring(0, line.length-1);
   },
  'block': (Map ast) {
    List<Map> list = ast['list'];
    for (var stmt in list) {
      pp(stmt);
      nl();
    }
  },
  'globalvar': (Map ast) {
    emit("\$${ast['name']}");
  },
  'doblock': (Map ast) {
    emit(" do");
    nl(1);
    List<Map> params = ast['params'];
    if (!params.isEmpty) {
      emit("|");
      for (var param in params) {
        emit(" ");
        pp(param);
      }
      emit(" | ");
    }
    nl();
    pp(ast['block']);
    emit("end");
    nl(-1);
  },
  'var': (Map ast) {
    emit(ast['name']);
  },
  'instvar': (Map ast) {
    emit("@" + ast['name']);
  },
  'const': (Map ast) {
    emit(ast['name']);
  },
  'def': (Map ast) {
    emit("def ");
    if (ast['classname'] != null) {
      emit(ast['classname']);
      emit(".");
    }
    emit(ast['name']);
    emit("(");
    List<Map> params = ast['params'];
    for (var param in params) {
      pp(param);
      emit(",");
    }
    if (!params.isEmpty) line = line.substring(0, line.length-1);
    emit(")");
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
  },
  'param': (Map ast) {
    emit(ast['name']);
    if (ast['init'] != null) {
      emit("=");
      pp(ast['init']);
    }
  },
  'restparam': (Map ast) {
    emit("*");
    emit(ast['name']);
  },
  'if': (Map ast) {
    emit("if ");
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
    emit("end");
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
  'mcall': (Map ast) {
    if (ast['expr'] != null) {
      pp(ast['expr']);
      emit(".");
    }
    emit(ast['name']);
    emit("(");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line = line.substring(0, line.length-1);
    emit(")");
    var block = ast['doblock'];
    if (block != null) {
      pp(block);
    }
  },
  '[]': (Map ast) {
    pp(ast['expr']);
    emit("[");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line = line.substring(0, line.length-1);
    emit("]");
  },
  'case': (Map ast) {
    emit("case ");
    pp(ast['expr']);
    nl(1);
    List<Map> whens = ast['whens'];
    for (var when in whens) {
      pp(when);
    }
    nl(-1);
    emit("end");
  },
  'when': (Map ast) {
    emit('when ');
    for (var expr in ast['exprList']) {
      pp(expr);
      emit(",");
    }
    line = line.substring(0, line.length-1);
    nl(1);
    pp(ast['block']);
    nl(-1);
  },
  'lit': (Map ast) {
    var value = ast['value'];
    if (value is String) {
      value = '"${value.replaceAll('"', '\\"')}"';
    }
    if (value is num) {
      if (value == value.truncate()) {
        value = value.truncate();
      }
    }
    emit("$value");
  },
  'relit': (Map ast) {
    emit("/${ast['value']}/");
  },
  '::': (Map ast) {
    pp(ast['expr']);
    emit("::");
    emit(ast['name']);
  },
  'array': (Map ast) {
    emit("[");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line = line.substring(0, line.length-1);
    emit("]");
  },
  'not': (Map ast) {
    emit("(!");
    pp(ast['expr']);
    emit(")");
  },
  'class': (Map ast) {
    emit('class ');
    emit(ast['name']);
    if (ast['superclass'] != null) {
      emit(" < ");
      pp(ast['superclass']);
    }
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
  },
  'attr_accessor': (Map ast) {
    List<String> symbols = ast['list'];
    for (var symbol in symbols) {
      emit("def $symbol() @$symbol end"); nl();
      emit("def $symbol=(obj) @$symbol=obj end"); nl();
    }
  },
  'attr_reader': (Map ast) {
    List<String> symbols = ast['list'];
    for (var symbol in symbols) {
      emit("def $symbol() @$symbol end"); nl();
    }
  },
  'for': (Map ast) {
    emit("for ");
    pp(ast['target']);
    emit(" in ");
    pp(ast['expr']);
    emit(" do ");
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
  },
  '..': op('..'),
  '...': op('...'),
  'next': (Map ast) {
    emit('exit');
  },
  '+=': (Map ast) {
    pp(ast['target']);
    emit(" += ");
    pp(ast['expr']);
  },
  '-=': (Map ast) {
    pp(ast['target']);
    emit(" -= ");
    pp(ast['expr']);
  },
  'alias': (Map ast) {
    emit("alias ");
    emit(":" + ast['old']);
    emit(" ");
    emit(":" + ast['new']);
  },
  'self': (Map ast) {
    emit('self');
  },
  'super': (Map ast) {
    emit('super');
  },
  '<=>': op('<=>'),
  'dowhile': (Map ast) {
    emit('begin');
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
    emit(" while ");
    pp(ast['expr']);
  },
  'symbol': (Map ast) {
    emit(":" + ast['name']);
  },
  'while': (Map ast) {
    emit("while ");
    pp(ast['expr']);
    emit(" do");
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
  },
  'break': (Map ast) => emit("break"),
  'ensure': (Map ast) => emit("ensure"),
  'rescue': (Map ast) => emit("rescue"),
  'splat': (Map ast) {
    emit("*");
    pp(ast['expr']);
  },
  '?:': (Map ast) {
    emit("(");
    pp(ast['expr']);
    emit(" ? ");
    pp(ast['then']);
    emit(" : ");
    pp(ast['else']);
    emit(")");
  },
  'return': (Map ast) {
    emit("return");
    if (ast['expr'] != null) {
      emit(" ");
      pp(ast['expr']);
    }
  },
  'neg': (Map ast) {
    emit("(-");
    pp(ast['expr']);
    emit(")");
  },
  'module': (Map ast) {
    emit("module ");
    emit(ast['name']);
    nl(1);
    pp(ast['block']);
    nl(-1);
    emit("end");
  }
};

/**
 * Emits a block with an optional return statment for the last statement.
 */
void returnblock(ast, {ret:false}) {
  List<Map> stmts = ast['list'];
  bool rescue = false, ensure = false;
  for (Map stmt in stmts) {
    if (stmt['type'] == 'rescue') rescue = true;
    if (stmt['type'] == 'ensure') ensure = true;
  }
  if (rescue || ensure) {
    emit("try {");
    nl(1);
  }
  for (int i = 0; i < stmts.length; i++) {
    if (ret && i == stmts.length - 1 && !['for', 'if', 'block'].contains(stmts[i]['type'])) {
      emit("return ");
    }
    pp(stmts[i]);
    if (!line.endsWith("}") && line.trim().length > 0) {
      emit(";");
    }
    nl();
  }
  if (rescue || ensure) {
    emit("}");
    nl(-1);
  }
}

/**
 * Makes Ruby names usable with Dart.
 * Replaces a trailing `?` with `_Q`, a trailing `!` with `_B`, and a trailing `=` with `_E`.
 */
String fixname(String name) {
  return name.replaceFirst("?", "_Q").replaceFirst("!", "_B").replaceFirst("=", "_E");
}

String className;

Map<String, Printer> dartMethods = {
  'assignment': (Map ast) {
    List<Map> targetList = ast['targetList'];
    List<Map> exprList = ast['exprList'];
    if (exprList.length < targetList.length) {
      emit("var ");
      for (Map target in targetList) {
        pp(target);
        emit(",");
      }
      line = line.substring(0, line.length-1);
      emit(" = ");
      for (Map expr in exprList) {
        pp(expr);
        emit(",");
      }
      line = line.substring(0, line.length-1);
      return;
    }
    for (int i = 0; i < targetList.length; i++) {
      if (targetList[i]['type'] == 'var') {
        emit("var ");
      }
      pp(targetList[i]);
      emit(" = ");
      pp(exprList[i]);
      if (i == targetList.length - 1) {
        if (exprList.length > targetList.length) {
          for (int j = i + 1; j < exprList.length; j++) {
            emit(",");
            pp(exprList[j]);
          }
        }
      } else {
        emit(";");
        nl();
      }
    }
  },
  'block': (Map ast) {
    returnblock(ast);
  },
  'globalvar': (Map ast) {
    emit("\$${ast['name']}");
  },
  'doblock': (Map ast) {
    emit("(");
    List<Map> params = ast['params'];
    for (var param in params) {
      pp(param);
      emit(",");
    }
    if (!params.isEmpty) line = line.substring(0, line.length-1);
    emit(") {");
    nl(1);
    returnblock(ast['block'], ret: true);
    nl(-1);
    emit("}");
  },
  'var': (Map ast) {
    emit(fixname(ast['name']));
  },
  'instvar': (Map ast) {
    emit("this." + ast['name']);
  },
  'const': (Map ast) {
    emit(ast['name']);
  },
  'def': (Map ast) {
    if (ast['classname'] != null) {
      if (ast['classname'] != className) {
        emit(ast['classname']);
        emit(".");
      } else {
        emit("static ");
      }
    }
    if (ast['name'] == 'initialize' && className != null) {
      emit(className);
    } else {
      emit(fixname(ast['name']));
    }
    emit("(");
    List<Map> params = ast['params'];
    for (var param in params) {
      pp(param);
      emit(",");
    }
    if (!params.isEmpty) line = line.substring(0, line.length-1);
    emit(") {");
    nl(1);
    returnblock(ast['block'], ret: ast['name'] != "initialize");
    nl(-1);
    emit("}");
  },
  'param': (Map ast) {
    if (ast['init'] != null) {
      emit("[");
      emit(ast['name']);
      emit("=");
      pp(ast['init']);
      emit("]");
    } else {
      emit(ast['name']);
    }
  },
  'restparam': (Map ast) { //TODO
    emit("*");
    emit(ast['name']);
  },
  'if': (Map ast) {
    emit("if (");
    pp(ast['expr']);
    emit(") {");
    nl(1);
    returnblock(ast['then']);
    if (ast['else'] != null) {
      nl(-1);
      emit('} else {');
      nl(1);
      returnblock(ast['else']);
    }
    nl(-1);
    emit("}");
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
  'mcall': (Map ast) {
    bool isNew = ast['name'] == "new";
    if (ast['expr'] != null) {
      if (isNew) emit("new ");
      pp(ast['expr']);
      if (!isNew) emit(".");
    }
    if (!isNew) emit(fixname(ast['name']));
    emit("(");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    var block = ast['doblock'];
    if (block != null) {
      pp(block);
    } else {
      if (!args.isEmpty) line = line.substring(0, line.length-1);
    }
    emit(")");
  },
  '[]': (Map ast) {
    pp(ast['expr']);
    emit("[");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line = line.substring(0, line.length-1);
    emit("]");
  },
  'case': (Map ast) {
    emit("switch (");
    pp(ast['expr']);
    emit(") {");
    nl(1);
    List<Map> whens = ast['whens'];
    for (var when in whens) {
      pp(when);
    }
    nl(-1);
    emit("}");
  },
  'when': (Map ast) {
    for (var expr in ast['exprList']) {
      emit('case ');
      pp(expr);
      emit(":");
      if (line == 'case true:') {
        line = "default:";
      }
      nl();
    }
    nl(1);
    returnblock(ast['block']);
    emit("break;");
    nl();
    nl(-1);
  },
  'lit': (Map ast) {
    var value = ast['value'];
    if (value is String) {
      value = '"${value.replaceAll('"', '\\"')}"';
    }
    if (value is num) {
      if (value == value.truncate()) {
        value = value.truncate();
      }
    }
    emit("$value");
  },
  'relit': (Map ast) {
    emit("new RegExp(r\"${ast['value']}\")");
  },
  '::': (Map ast) {
    pp(ast['expr']);
    emit(".");
    emit(ast['name']);
  },
  'array': (Map ast) {
    emit("new Array.from([");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line = line.substring(0, line.length-1);
    emit("])");
  },
  'not': (Map ast) {
    emit("(!");
    pp(ast['expr']);
    emit(")");
  },
  'class': (Map ast) {
    emit('class ');
    emit(ast['name']);
    if (ast['superclass'] != null) {
      emit(" extends ");
      pp(ast['superclass']);
    }
    emit(" {");
    nl(1);
    className = ast['name'];
    returnblock(ast['block']);
    className = null;
    nl(-1);
    emit("}");
  },
  'attr_accessor': (Map ast) {
    emit("var ");
    List<String> symbols = ast['list'];
    for (var symbol in symbols) {
      emit("$symbol,");
    }
    line = line.substring(0, line.length-1);
  },
  'attr_reader': (Map ast) {
    emit("final ");
    List<String> symbols = ast['list'];
    for (var symbol in symbols) {
      emit("$symbol,");
    }
    line = line.substring(0, line.length-1);
  },
  'for': (Map ast) {
    emit("for (");
    pp(ast['target']);
    emit(" in ");
    pp(ast['expr']);
    emit(") {");
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit("}");
  },
  '..': (Map ast) {
    emit("new Range.incl(");
    pp(ast['left']);
    emit(",");
    pp(ast['right']);
    emit(")");
  },
  '...': (Map ast) {
    emit("new Range.excl(");
    pp(ast['left']);
    emit(",");
    pp(ast['right']);
    emit(")");
  },
  'next': (Map ast) {
    emit('continue');
  },
  '+=': (Map ast) {
    pp(ast['target']);
    emit(" += ");
    pp(ast['expr']);
  },
  '-=': (Map ast) {
    pp(ast['target']);
    emit(" -= ");
    pp(ast['expr']);
  },
  'alias': (Map ast) {
  },
  'self': (Map ast) {
    emit('this');
  },
  'super': (Map ast) {
    emit('super');
  },
  '<=>': op('<=>'), //TODO
  'dowhile': (Map ast) {
    emit('do {');
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit("} while (");
    pp(ast['expr']);
    emit(")");
  },
  'symbol': (Map ast) {
    emit("'${ast['name']}'");
  },
  'while': (Map ast) {
    emit("while (");
    pp(ast['expr']);
    emit(") {");
    nl(1);
    returnblock(ast['block']);
    nl(-1);
    emit("}");
  },
  'break': (Map ast) => emit("break"),
  'ensure': (Map ast) {
    emit("}");
    nl(-1);
    emit("finally {");
    nl(1);
  },
  'rescue': (Map ast) {
    emit("}");
    nl(-1);
    emit("catch (e) {");
    nl(1);
  },
  'splat': (Map ast) {
    emit("*");
    pp(ast['expr']);
  },
  '?:': (Map ast) {
    emit("(");
    pp(ast['expr']);
    emit(" ? ");
    pp(ast['then']);
    emit(" : ");
    pp(ast['else']);
    emit(")");
  },
  'return': (Map ast) {
    emit("return");
    if (ast['expr'] != null) {
      emit(" ");
      pp(ast['expr']);
    }
  },
  'neg': (Map ast) {
    emit("(-");
    pp(ast['expr']);
    emit(")");
  },
  'module': (Map ast) { //TODO
    emit("class ");
    emit(ast['name']);
    emit(" {");
    nl(1);
    className = ast['name'];
    returnblock(ast['block']);
    className = null;
    emit("}");
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
