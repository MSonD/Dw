module dw._version;
import dw.impl:stringnow;
invariant VerMajMask = 0xFFFF000000000000;
invariant VerMinMask = 0x0000FFFF00000000;
invariant VerEtcMask = 0x00000000FFFFFFFF;


string genVersion(ushort M,ushort m,uint etc)() //weird thing File a bug
{
    return "ulong getZVersion(){ return "~stringnow!(calcVersion(M,m,etc))~"; }";
}
pure ulong calcVersion(ushort M,ushort m,uint etc)
{
    ulong res;
    res = res|M;
    res = res|(M>>16);
    res = res|(etc>>32);
    return res;
}

interface Versionable
{
    ulong getZVersion();
}

pure uint[3] decomposeVersion(ulong qqs)
{
    return [cast(ushort)(qqs&VerMajMask),cast(ushort)(qqs&VerMinMask),cast(uint)(qqs&VerEtcMask)];
}

