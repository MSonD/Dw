module dw.superparse;
import std.algorithm;
import std.container;
import dw.token;
import dw.treebuild;
import dw.value;
import dw.impl;
alias DValue delegate (DValue[]...) DFun;
DValue findval(ref SList!zscope x,string name){
    DValue* val;
    switch(name){
        case "true":
            return DValue(true);
        case "false":
            return DValue(false);
        case "nil":
            return DValue(NIL());
        default:
    }
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
                    node!Token[]* fun2 = fun.peek!(node!(Token)[]);
                    if (fun2 is null) return DValue(EX("Wrong type of arguments for 'call'"));
                    if((*fun2).length == 1){
                        return eval((*fun2)[0]);
                    }else if((*fun2).length == 2){

                    }else{
                        return DValue(EX("Non function argument used for 'call'"));
                    }
                case "len":
                  if(no.values.data.length < 2)return DValue(EX("Wrong number of arguments for 'len'"));
                  if(no.values.data[1].sym.type != TOKEN.O_PAR) return DValue(1);
                  auto val = eval(no.values.data[1]);
                  if(val.peek!(void[]) is null) return DValue(1);
                  return DValue(val.length);
                case "if":
                  if(no.values.data.length < 4)return DValue(EX("Wrong number of arguments for 'if'"));
                  auto val = eval(no.values.data[1]).peek!bool;
                  if(val is null)return (DValue(EX("Expression not evaluates to bool for 'if'")));
                  else if(*val){
                    return eval(no.values.data[2]);
                  }else{
                    return eval(no.values.data[3]);
                  }
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
