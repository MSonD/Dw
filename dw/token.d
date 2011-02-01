module dw.token;
import dw.impl;
import dw.except;
import dw.meta;
import dw.def;
import std.concurrency;
enum TOKEN
{
    HEAD,
    O_PAR,//"("
    C_PAR,// ")"
    QUOTE,//"
    DQUOTE,//'
    INT,// 092 0xf
    FLOAT,
    ID,
    NUMX,
    STRLIT,
    NL
}
enum TOKEN_MODE
{
    NORMAL ,
    DQUOTE_LIT , //2on quotes
    QUOTE_LIT,
    COMMENT
}
enum NUM_MASK = 0b001;
enum CTYPE
{
    STR,//a-z
    DIG,//0-9
    OPR,//+ - * ?
    SPA,// ' ' whitespace
    NL// new line
}
struct Token
{
    string toString()
    {
        return token~" as "~to_string(type);
    }
    TOKEN type;
    STR token;
}


/*	See licence.txt for licence. Expd S-Expressions for D*/

void TokenServer(Tid write){
    bool cont = true;
    auto paren = receiveOnly!Tid();
    void tokenize(STR strin)
    {
        if(printer) _objout("LEX: tokenize called");
        //Temporal variables
        TOKEN_MODE mode = TOKEN_MODE.NORMAL;
        Token[] res;
        res.length=bufsize;
        STR bufr;
        size_t cptr = 0;
        bool cookingtoken=false;
        size_t LINE = 0;
        //size_t uni_size = utfstrlen(strin); Works already without all that mess, but up to what point?
        // Answer: restricts to have top only token elements wich are in ASCII, but allows ID and literals to be unicode

        //ends a single token
        void cutToken(ref Token tk)
        {
            res[cptr] = tk;
            bufr.length=0;
            cptr++;
        }
        void verifyt()
        {
            if(cookingtoken)
            {
                if(printer) _objout("LEX: <found token ",bufr[0..$-1]," at ",cptr," >");
                string g = bufr[0..$-1];
                Token t =Token(getType(g),g);
                res[cptr] = t;
                cptr++;
                if(cptr == bufsize)  //if the buffer is full, flush.
                {
                    write.send(res.idup);
                    cptr=0;
                    version(dbg3) synchronized _objout("LEX: pushing tokens...");
                    //AVOID RESIZING AT ALL COSTS
                }
                cookingtoken=0;
            }
        }

        //main loop
        //cur c strin

        foreach(cur,ref c; strin)
        {
            //quirky trick to avoid shadowing declaration
            if(cptr == bufsize)  //if the buffer is full, flush.
            {
                write.send(res.idup);
                cptr=0;
                version(dbg3) synchronized _objout("LEX: pushing tokens...");
                //AVOID RESIZING AT ALL COSTS
            }
            if(!(mode == TOKEN_MODE.COMMENT))bufr~=c;

            //One time char cases
            //TODO: do a kind of static seach tree to select mode intead of trying eachone too speed up
            if(mode== TOKEN_MODE.NORMAL)  //Normal operation mode
            {
                switch (c)
                {
                case _C!('#'):
                    verifyt();
                    mode = TOKEN_MODE.COMMENT;
                case _C!('('):
                    verifyt();
                    cutToken(Token(TOKEN.O_PAR));
                    continue;
                case _C!(')'):
                    verifyt();
                    cutToken(Token(TOKEN.C_PAR));
                    continue;
                case _C!('"'):
                    verifyt();
                    cutToken(Token(TOKEN.DQUOTE));
                    mode = TOKEN_MODE.DQUOTE_LIT;
                    continue;
                case _C!('\''):
                    verifyt();
                    cutToken(Token(TOKEN.QUOTE));
                    mode = TOKEN_MODE.QUOTE_LIT;
                    continue;
                case '\n': //this should work on unix likes and windows (dunno in mac oses)
                    verifyt();
                    write.send(SIG.NL); //Propagated to get line info
                    LINE++;
                    continue;
                case '\r':
                case ' ':
                    verifyt();
                    bufr=""; //clean
                    continue;
                default:
                    if(!cookingtoken) cookingtoken = true;
                    continue;
                }


            }else  if(mode == TOKEN_MODE.DQUOTE_LIT) //Double quoted mode
            {
                switch (c)
                {
                case _C!('"'):
                    cutToken(Token(TOKEN.STRLIT,bufr[0..$-1]));
                    cutToken(Token(TOKEN.DQUOTE));
                    //
                    mode = TOKEN_MODE.NORMAL;
                    continue;
                case _C!('\\'):
                    //TODO: handle escape sequences
                    continue;
                default:			//restart because it is a literal
                    continue;
                }
            }
            else if(mode== TOKEN_MODE.QUOTE_LIT) //Single quoted mode
            {
                switch (c)
                {
                case _C!('\''):
                    cutToken(Token(TOKEN.STRLIT,bufr[0..$-1]));
                    cutToken(Token(TOKEN.QUOTE));
                    mode = TOKEN_MODE.NORMAL;
                    continue;
                case _C!('\\'):
                    continue;
                default:       //restart because it is a literal
                    continue;
                }
            }
            else if(mode == TOKEN_MODE.COMMENT)
            {
                if(c == _C!('#'))
                {
                    mode =TOKEN_MODE.NORMAL;
                }
            }


        }
        bufr~=" "; //trick
        verifyt();
        if(cptr > 0)write.send(res[0..cptr].idup);
        write.send(SIG.FLUSH);
    }
    while(cont){
        receive(
                (string x){tokenize(x);paren.send(SIG.TERM);},
                (SIG x){if(x is SIG.TERM)paren.send(SIG.TERM);}
                );
    }
}

pure TOKEN getType(STR typof)
{
    TOKEN type;
    if(isNb(typof[0]))
    {
        type = TOKEN.INT;
        foreach(c; typof)
        {
            if(type == TOKEN.INT)
            {
                if(isNb(c))
                {

                }
                else if(c == _C!('.'))
                {
                    type = TOKEN.FLOAT;
                }
                else
                {
                    type = TOKEN.NUMX;
                }
            }
            else if (type == TOKEN.FLOAT)
            {
                if(!isNb(c))
                {
                    type = TOKEN.NUMX;
                }
            }
        }
    }
    else
    {
        type = TOKEN.ID; //DONT KNOW IF I SHOULD CONSIDER THINGS LIKE >a>! like identifiers
    }
    return type;

}
