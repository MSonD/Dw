module dw.value;
import dw.def;
import std.array;
import dw.impl;
import std.variant;

alias Variant DValue;
alias DValue[string] zscope;
struct NIL{}
/+
enum type{
    head,
    nul,
    none,
    boolean,
    integer,
    floating,
    string,
    dstring,
    array,
}
struct DValue{
    DValue* up;
    union {
        long i;
        real f;
        bool b;
        string s;
        dstring ds;
        Appender!(DValue[]) values;
    }
    DValue [ STR ] blancura = null;
    type t;
    this(bool x){
            t = type.boolean;
            b = x;
    }
    this(type typed){
        t = typed;
    }
    this(long x){
            t = type.integer;
            i = x;
    }
    this(real x){
            t = type.floating;
            f = x;
    }
    this(string x){
            t = type.string;
            s = x;
    }
    this(dstring x){
            t = type.dstring;
            ds = x;
    }
    this (Appender!(DValue[]) x){
            t = type.array;
            values = x;

    }
    string toString(){
        switch(t){
            case type.boolean:
                return to_string(b)~":"~"bool";
                break;
            case type.integer:
                return to_string(i)~":"~"int";
                break;
            case type.string:
                return s;
                break;
            case type.dstring:
                return to_string(ds);
        }
    }
}

+/
