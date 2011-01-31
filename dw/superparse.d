module dw.superparse;
import std.algorithm;
import std.container;
import dw.token;
import dw.treebuild;
import dw.value;
import dw.impl;

DValue findval(ref SList!zscope x,string name){
    DValue* val;
    foreach(a;x){
        val = name in a;
        if(val !is null) return *val;
    }
    return DValue(NIL());
}
DValue putval(ref SList!zscope x,string name, DValue xa){
    if((name in x.front()) !is null) return DValue(EX("Cannot override immutable '"~name~"'"));
    auto arr = x.front;
    arr[name] = xa;
    return xa;
}
DValue Eval ( ref node!Token no, ref zscope soc ) {
  auto stack = make!(SList!zscope)(soc);//name stack
  DValue eval ( ref node!Token no ) {

    DValue[] mapval ( node!Token[] var ) {
      DValue[] x;
      x.length = var.length;
      foreach ( n, v; var ) x[n] = eval ( v );
      return x;
    }

    if ( no.sym.type == TOKEN.O_PAR || no.sym.type == TOKEN.HEAD ) {
        if ( no.values.data.length == 0 ) return DValue ( null );
        try {
            switch ( no.values.data[0].sym.token ) {
                case "+":
                  return reduce! ( "a + b" ) ( DValue ( 0 ), mapval ( no.values.data[1..$] ) ); //OPTIMIZE
                case "-":
                  return DValue ( eval ( no.values.data[1] ) ) - reduce! ( "a + b" ) ( DValue ( 0 ), mapval ( no.values.data[2..$] ) ); //TODO: OPTIMIZe
                case "*":
                  return reduce! ( "a * b" ) ( DValue ( 1 ),  mapval ( no.values.data[1..$] ) ); //TODO: OPTIMIZE
                case "con":
                  return reduce! ( "a ~ b" ) ( DValue ( "" ),  mapval ( no.values.data[1..$] ) ); //TODO: OPTIMIZE
                case "let":
                  if(no.values.data.length != 3)return DValue(EX("Wrong number of arguments for 'let'"));
                  auto name = no.values.data[1];
                  if(name.sym.type != TOKEN.ID) return DValue(EX("'Let' used whit invalid ID argument"));
                  return putval(stack,name.sym.token,eval(no.values.data[2]));
                case "def":
                  if(no.values.data.length < 2)return DValue(EX("Wrong number of arguments for 'def'"));
                  return DValue(no.values.data[1..$]);
                case "call":
                    if(no.values.data.length < 2)return DValue(EX("Wrong number of arguments for 'call'"));
                    auto fun = eval(no.values.data[1]);
                    //node!Token[] fun2 = fun.peek!node!Token[])
                default:
                  DValue[] a;
                  a.length = no.values.data.length;
                  foreach ( n, b; no.values.data ) {
                    a[n] = eval ( b );
                  }
                  if (a.length == 1) return a[0];
                  return DValue ( a );
              }
          }
        catch ( Exception e ) {
            return DValue ( EX ( e.msg ) );
          }
      }
    switch ( no.sym.type ) {
        case TOKEN.INT:
          return DValue ( To! ( long ) ( no.sym.token ) );
        case TOKEN.FLOAT:
          return DValue ( To! ( real ) ( no.sym.token ) );
        case TOKEN.STRLIT:
          return DValue ( no.sym.token);
        case TOKEN.ID:
          return findval(stack,no.sym.token);
        default:
          return DValue ( EX ( " '"~no.sym.token~"' not defined" ) );
      }
  }
  return eval ( no );
}
