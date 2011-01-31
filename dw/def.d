module dw.def;
alias string STR;
alias const char CHAR;
immutable bool printer = false;
immutable uint bufsize = 10;
enum SIG{
    FLUSH,
    NL,
    TERM,
    REQUEST
}
