module dw.treebuild;
import std.array;
import dw.value;
import dw.impl;
import dw.except;
import dw.def;
import dw.token;
import dw.superparse;
import std.concurrency;

void BuildTree(Tid write,Tid mgr){
    size_t line;
    Token top;
    top = Token();
    auto tr = new tree(Token.init);
    size_t parens;
    zscope ocope;
    ocope["_version"] = DValue([0,0,1]);
     void push(immutable(Token)[] a)
        {
        foreach(tok; a)
        {
            switch(tok.type)
            {
            case TOKEN.DQUOTE:
            case TOKEN.QUOTE:
                break;
            case TOKEN.O_PAR:
                parens++;
                tr.append(tok);
                tr.select();
                break;
            case TOKEN.C_PAR:
                if(parens == 0){mgr.send(EX("parentesis no concordantes"));break;}
                else{
                parens--;
                tr.up();
                }
                                break;
            default:
                tr.append(tok);
                break;

            }
        }
            if (parens == 0){
                try{
                _objout("=> ",Eval(tr.top,ocope)," \n");
                }catch(Exception e){
                    mgr.send(EX(e.msg));
                }
                    tr.clean();
            }
        }

        bool cont = true;
        try{
        while(cont) receive(
            (immutable(Token)[] x){push(x);}
        );
        }catch(Exception e){

        }
}

void parse(tree t){

}

class tree{
    alias node!Token Node;
    Node top;
    Node* cur;
    void clean(){
        top.values.clear(); //rely on the GC
        this.cur = &this.top;
    }
    this(in Token top){
        this.top = Node(top);
        this.cur = &this.top;
    }
    Token getTop(){
        return top.sym;
    }
    Token getCur(){
        return cur.sym;
    }
    void select(size_t idxz){
          cur = &cur.values.data[idxz];

    }
    void append(in Token idxs){
        Node x = Node(idxs,cur);
        cur.values.put(x);
    }
    Token opIndex(size_t indz){
        return cur.values.data[indz].sym;
    }
    void select(){
        cur = &cur.values.data[cur.values.data.length-1];
    }
    void up(){
        cur = cur.up;
    }
    override string toString(){
        return top.toString();
    }
}
struct node(T)
{
    T sym;
    node!(T)* up;
    Appender!(node!(T)[]) values;
    size_t nb = 0;
    string toString()
    {
        if(sym.type != TOKEN.O_PAR && sym.type != TOKEN.HEAD) return to_string(sym);
        else return "{"~to_string(sym)~"}"~to_string(values.data);
    }
}