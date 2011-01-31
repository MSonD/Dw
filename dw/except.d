
/*	See licence.txt for licence. Expd S-Expressions for D*/
/** Module for all kinds of Exceptions and errors**/
module dw.except;

///Any exception related to the inner workings of Expd
class ExpdException:Exception
{
    public this(string msg)
    {
        super(msg);
    }
}

///An exception happened trying to tokenize
class LexEException : ExpdException
{
    public this(string msg,string prefix = "Lex error: ")
    {
        super(prefix~msg);
    }
}

///An exception involving parse tree
class TreeBuildingEException : ExpdException
{
    public this(string msg,string prefix = "Error building parse tree: ")
    {
        super(prefix~msg);
    }
}

///Exception involving invalid escape sequences
class InvalidEscapeEException:LexEException
{
    public this(string escape_sequence)
    {
        super(" Invalid escape sequence '"~escape_sequence~"'");
    }
}

class InvalidLiteralEException:LexEException
{
    public this(string liter)
    {
        super(" Invalid literal '"~liter~"'");
    }
}
