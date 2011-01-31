module dw.meta;
import dw.impl;
//Our char handler
template _C(char c)
{
    alias c _C;
}

pure string genIsNum(string varname)
{
    return("
           ( "~varname~">'0' && "~varname~" <'9')
           ");
}
