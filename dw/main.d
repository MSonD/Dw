module dw.main;
import dw.executer;
import std.concurrency;
import std.stdio;
import std.string;
import dw.treebuild;

void main(string[] args){
    auto run = &Executer;
    Tid handler1 = spawn(run,false);
    string inpu;
    while(true){
        inpu = readln();
        handler1.send(inpu);
    }
}
