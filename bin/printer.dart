// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

var indent = "";
var line = "";

/**
 * Appends [s] to the current line.
 */
emit(String s) {
  line += s;
}

/**
 * Prints the current line and adapts the indent.
 * If [i] is < 0, the next line is dedented.
 * If [i] is > 0, the next line is indented.
 */
nl([i=0]) {
  if (i < 0) {
    indent = indent.slice(0, -2);
  }
  if (!line.isEmpty) {
    print(indent + line);
    line = "";
  }
  if (i > 0) {
    indent += "  ";
  }
}

typedef void Printer(Map ast);

/**
 * Returns a printer function for the binary operator [op].
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

Map<String, Printer> printMethods = {
   'assignment': (Map ast) {
     for (Map target in ast['targetList']) {
       pp(target);
       emit(",");
     }
     line=line.slice(0, -1);
     emit(" = ");
     for (Map expr in ast['exprList']) {
       pp(expr);
      emit(",");
     }
     line=line.slice(0, -1);
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
    if (!params.isEmpty) line=line.slice(0, -1);
    emit(")");
    ppblock(ast);
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
    if (!args.isEmpty) line=line.slice(0, -1);
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
    if (!args.isEmpty) line=line.slice(0, -1);
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
    emit("end");
    nl(-1);
  },
  'when': (Map ast) {
    emit('when ');
    for (var expr in ast['exprList']) {
      pp(expr);
      emit(",");
    }
    line=line.slice(0, -1);
    nl(1);
    pp(ast['block']);
    nl(-1);
  },
  'lit': (Map ast) {
    var value = ast['value'];
    if (value is String) {
      value = '"${value.replaceAll('"', '\\"')}"';
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
  'exprlist': (Map ast) {
    List<Map> list = ast['list'];
    for (var expr in list) {
      pp(expr);
      emit(",");
    }
    if (!list.isEmpty) line=line.slice(0, -1);
  },
  'array': (Map ast) {
    emit("[");
    List<Map> args = ast['args'];
    for (Map arg in args) {
      pp(arg);
      emit(",");
    }
    if (!args.isEmpty) line=line.slice(0, -1);
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
    ppblock(ast);
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
    ppblock(ast);
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
    emit(ast['old']);
    emit(" ");
    emit(ast['new']);
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
    ppblock(ast);
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
    ppblock(ast);
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
    ppblock(ast);
  }
};

void ppblock(Map ast) {
  nl(1);
  pp(ast['block']);
  nl(-1);
  emit("end");
}

void pp(Map ast) {
  String type = ast['type'];
  if (printMethods[type] == null) {
    throw "missing $ast";
  }
  printMethods[type](ast);
}

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
symbol          name
param           name init
restparam       name

 */
