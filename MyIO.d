import std.file;
import std.string;
import std.stdio;
import std.conv;

//!//////////////////////////////////////////////////////////////////////

void toFile( char[] fileName, char[] data, bit append )
{
    if( append )
    {
        std.file.append( fileName, data );
    }
    else
    {
        std.file.write( fileName, data );
    }
}

//!//////////////////////////////////////////////////////////////////////

char[] fromFile( char[] fileName )
{
    if( !std.file.exists( fileName ) )
        return "";

    char[] file = cast(char[])std.file.read( fileName );

    return file;
}
