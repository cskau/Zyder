import std.string; // hexdigits, ifind
import std.math; // Pow
import std.regexp; // split

//!//////////////////////////////////////////////////////////////////////

uint hex2dec( char[] hex )
{
    uint sum = 0;

    // Strip to remove any whitespace at both ends of the string
    hex = strip(hex);

    foreach( uint n, char c; hex )
    {
        if( ifind(hexdigits,c) < 0 )
            return sum;
        sum += ifind(hexdigits,c) * pow(cast(real)16,(hex.length-1 - n));
    }

    return sum;
}

char[] dec2hex( uint dec )
{
    uint top = cast(uint)floor(dec/16.0f);
    char[] cs;
    cs ~= hexdigits[top];
    cs ~= hexdigits[(dec-(top*16))];

    return cs;
}

//!//////////////////////////////////////////////////////////////////////

    // Unreserved chars: ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~
    // Reserved chars: !*'();:@&=+$,/?%#[]
    // Reserved subs: %21 %2A %27 %28 %29 %3B %3A %40 %26 %3D %2B %24 %2C %2F %3F %25 %23 %5B %5D

char[] toURISafe( char[] ori )
{
    char[] ret;
    foreach( wchar dc ; ori ) // Single-byte chars -> Multi-byte chars
    {
        byte[2] ubs = dc;
        ret ~= "%" ~ dec2hex(ubs[0]);
        if( ubs[0] != ubs[1] )
            ret ~= "%" ~ dec2hex(ubs[1]);
    }
    return ret;
}

//!//////////////////////////////////////////////////////////////////////

    // converts &#123; -like chars to raw chars

char[] convHTMLChars( char[] oriStr )
{
    char[] tmpstr;

    foreach( s ; std.regexp.split( oriStr, "&#([0-9]*?);", "g" ) )
    {
        if( s != "" )
            tmpstr ~= cast(char) atoi(s);
    }

    return tmpstr;
}
