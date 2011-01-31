module dw.executer;
import std.concurrency;
import core.thread;
import dw.impl;
import dw.token;
import dw.def;
import dw.treebuild;
struct Info{
    string msgout = "N\\A";
    Exception lastThrow = null;
}

///Executes intructions
void Executer(bool doThrow = false){
    if(printer)_objout("starting executer");
    auto aprinter=spawn(&printe);
    auto parser = spawn(&BuildTree,aprinter,thisTid());
    Tid tokenizer = spawn(&TokenServer,parser);
    tokenizer.send(thisTid());
    auto cont = true;

    void getSig(){
        bool term = true;
         while(term){receive(
                (SIG sig){ if(sig == SIG.TERM){term = false;}}

            );}
    }

    while(cont){
    receive(
            (string x){tokenizer.send(x);},
            (OwnerTerminated){cont = false;},
            (EX e){_objout(e.e);}
            );
            getSig();

    }


}


void printe(bool isPrompt = true){
    string prompt = ":::";
    while(true){
        receive(
                //(SIG x){if(SIG.FLUSH is x && isPrompt)_write(prompt);},
                (Token[] t){ _objout(t);},
                (tree t){ _objout("OK");}
                );
    }
}
