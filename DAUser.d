import std.string; // toString

import HTTPUtil;
import MyIO;

class DAUsr
{
private:
    char[] username;
    char[][char[]] infoStr;
    int[char[]] infoInt;

public:
    void setUsername( char[] _username )
    {
        username = _username;
    }

    void setInfo( char[] _label, char[] _cont )
    {
        infoStr[ _label ] = _cont;
    }

    void setInfo( char[] _label, int _cont )
    {
        infoInt[ _label ] = _cont;
    }

    char[] toPost()
    {
        char[] retStr = "username=" ~ username;

        // no need to check - they're only set if content is found
        foreach( char[] label, char[] cont ; infoStr )
            retStr ~= "&" ~ label ~ "=" ~ toURISafe(cont);

        foreach( char[] label, int cont ; infoInt )
            retStr ~= "&" ~ label ~ "=" ~ std.string.toString(cont);

        return retStr;
    }
}
