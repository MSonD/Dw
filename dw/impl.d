module dw.impl;

template Tuple(T...)
{
    alias T Tuple;
}
public import dw.def;
version(D_Version2)
{
    import std.stdio;
    import std.metastrings; //find replacement
    import std.utf;
    import std.ctype;
    import std.conv;
    import core.memory;

    alias writeln _objout;
    alias write _write;
    alias readln _read_line;
    alias toStringNow stringnow;

    alias count utfstrlen;
    alias isdigit isNb;
    alias to!string to_string;
    alias to To;
}
struct EX{
    string e;
    this(string e){
        this.e = "** "~e~" **";
    }
}
