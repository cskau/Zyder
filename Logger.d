import std.stdio;

class Logger
{
private:
	void delegate( char[] ) logFunc;

	void defaultLog( char[] _txt )
	{
			writefln( _txt );
	}

public:
	this()
	{
		logFunc = &defaultLog;
	}

	this( void delegate( char[] ) dg )
	{
		logFunc = dg;
	}

	void setLogger( void delegate( char[] ) dg )
	{
		logFunc = dg;
	}

	void log( char[] _txt )
	{
		if( logFunc )
			logFunc( _txt );
		else
			defaultLog( _txt );
	}
}
