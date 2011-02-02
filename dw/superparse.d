module dw.superparse;
import std.algorithm;
import std.container;
import dw.token;
import dw.treebuild;
import dw.value;
import dw.impl;
alias DValue function ( DValue[]... ) DFun;
alias DValue delegate ( DValue[]... ) DDlg;
class Scope {
    SList!zscope sc;
    DFun[string] binding;
    DDlg[string] dlgd;
    DValue findval ( string name ) {
      DValue *val;
      auto  bind = name in binding;
      if ( bind !is null ) return DValue ( *bind );
      auto  bind2 = name in dlgd;
      if ( bind2 !is null ) return DValue ( *bind2 );
      switch ( name ) {
          case "true":
            return DValue ( true );
          case "false":
            return DValue ( false );
          case "nil":
            return DValue ( NIL() );
          default:
        }
      foreach ( a; sc ) {
        val = name in a;
        if ( val !is null ) return *val;
      }
      return DValue ( EX("'"~name~"' not defined") );
    }
    this ( zscope input ) {
      sc = make! ( SList!zscope ) ( input );
    }
    this() {
    DValue[string] defaultScope = [ " _default_ ":DValue ( 0 ) ];
      sc = make! ( SList!zscope ) ( defaultScope );
    }
    void loadPrelude() {
      binding["+"] = &_add;
      binding["*"] = &_mul;
      binding["~"] = &_con;
      binding["/"] = &_div;
      binding["idx"] = &_idx;
      dlgd["clean"] = &clean;
    }
    void openScope(zscope a) {
      sc.insert ( a );
    }
    DValue clean(DValue[] ...){
        DValue[string] defaultScope = [ " _default_ ":DValue ( 0 ) ];
        sc = make! ( SList!zscope ) ( defaultScope );
        return DValue(NIL());
    }
    void closeScope() {
      sc.removeFront();
    }
    DValue putval ( string name, DValue xa ) {
      if ( ( name in sc.front() ) !is null ) return DValue ( EX ( "Cannot override immutable '"~name~"'" ) );
      auto arr = sc.front;
      arr[name] = xa;
      return xa;
    }
}

DValue _add ( DValue[] vals... ) {
  return reduce! ( "a + b" ) ( vals[0], vals[1..$] );
}
DValue _mul ( DValue[] vals... ) {
  return reduce! ( "a * b" ) ( vals[0], vals[1..$] );
}
DValue _con ( DValue[] vals... ) {
  return reduce! ( "a ~ b" ) ( vals[0], vals[1..$] );
}
DValue _div ( DValue[] vals... ) {
  return reduce! ( "a / b" ) ( vals[0], vals[1..$] );
}
DValue _idx ( DValue[] vals... ) {
  _objout ( "being called", vals );
  if ( vals.length  != 2 ) return DValue ( EX ( "idx called with wrong number of argumens" ) );
  try {
      if ( vals[1].type == typeid ( long ) ) {
          if ( * ( vals[1].peek!long ) == 1 ) return vals[0];
          return DValue ( EX ( "idx cannot extract data from "~vals[0].toString ) );
        }
      return vals[0][vals[1].coerce! ( size_t ) ];
    }
  catch ( Exception e ) {
      return DValue ( EX ( e.msg ) );
    }
}

DValue Eval ( ref node!Token no, ref Scope soc ) {
    size_t recursionlevel  = 0;
  DValue eval ( ref node!Token no ) {
    DValue[] mapval ( node!Token[] var ) {
      DValue[] x;
      x.length = var.length;
      foreach ( n, v; var ) x[n] = eval ( v );
      return x;
    }


    if ( no.sym.type == TOKEN.O_PAR || no.sym.type == TOKEN.HEAD ) {
        if ( no.data.length == 0 ) return DValue ( NIL() );
        try {
            switch ( no.data[0].sym.token ) {//Language basics
                case "let":
                  if ( no.data.length != 3 ) return DValue ( EX ( "Wrong number of arguments for 'let'" ) );
                  auto name = no.data[1];//get var name
                  if ( name.sym.type != TOKEN.ID ) return DValue ( EX ( "'Let' used whit invalid ID argument" ) );
                  return soc.putval ( name.sym.token, eval ( no.data[2] ) ); //set our value
                case "def":
                  if ( no.data.length < 2 ) return DValue ( EX ( "Wrong number of arguments for 'def'" ) );
                  return DValue ( no.data[1..$] );
                case "len":
                  if ( no.data.length < 2 ) return DValue ( EX ( "Wrong number of arguments for 'len'" ) );
                  if ( no.data[1].sym.type != TOKEN.O_PAR ) return DValue ( 1 );
                  auto val = eval ( no.data[1] );
                  if ( val.peek! ( void[] ) is null ) return DValue ( 1 );
                  return DValue ( val.length );
                case "if":
                  if ( no.data.length < 4 ) return DValue ( EX ( "Wrong number of arguments for 'if'" ) );
                  auto val = eval ( no.data[1] ).peek!bool;
                  if ( val is null ) return ( DValue ( EX ( "Expression not evaluates to bool for 'if'" ) ) );
                  else if ( *val ) {
                      return eval ( no.data[2] );
                    }
                  else {
                      return eval ( no.data[3] );
                    }
                default://asume function call, then list;
                  DValue[] a;
                  a.length = no.data.length;
                  foreach ( n, b; no.data ) {
                    a[n] = eval ( b );
                  }
                  if ( no.data.length > 1 )
                    if ( a[0].type == typeid ( DFun ) )
                     return ( * ( a[0].peek! ( DFun ) ) ) ( a[1..$] );
                  node!Token[]* fun2 = a[0].peek! ( node! ( Token ) [] ); //get sintax tree
                  if ( fun2 !is null ) {
                        auto fun3 = *fun2;
                      if ( fun3.length == 1 ) { //if only one arg,just call it
                           if(no.data.length  !=  1)
                            return DValue(EX("Wrong number of arguments for "~no.data[0].sym.token));
                           return eval ( ( fun3 ) [0] );
                        }else if (fun3.length == 2){
                            if (no.data.length-1 != fun3[0].data.length)
                                return DValue(EX("WANING number of arguments for '"~no.data[0].sym.token~"' do not match"));
                            zscope newscope;
                            foreach(n,m;fun3[0].data){
                                if(m.sym.type != TOKEN.ID) return DValue(EX("argument names can't be evaluable"));
                                newscope[m.sym.token] = a[n+1];
                            }
                            soc.openScope(newscope);
                            auto WOW = eval(fun3[1]);
                            soc.closeScope();
                            return WOW;
                        }
                    }
                  if ( a.length == 1 ) return a[0];
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
          return DValue ( no.sym.token );
        case TOKEN.ID:
          return soc.findval ( no.sym.token );
        default:
          return DValue ( EX ( " '"~no.sym.token~"' not defined" ) );
      }
  }
  return eval ( no );
}
