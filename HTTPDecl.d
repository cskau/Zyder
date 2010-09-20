import std.string;

//!//////////////////////////////////////////////////////////

class CURL
{
	char[] url;

	this( char[] _url )
	{
		url = _url;
	}

	char[] host()
	{
		int pos;
		char[] tmp = url;

		pos = std.string.find(tmp,"://") + 3;
		if( pos > 2 ) // make sure find didn't return -1
			tmp = tmp[pos .. $];

		pos = std.string.find(tmp,'/');
		if( pos > 0 ) // ditto
			tmp = tmp[0 .. pos];

		return tmp;
	}

	char[] local()
	{
		char[] tmp = host();
		uint pos = std.string.find( url, host() ) + host().length;
		tmp = url[pos .. $];

		if( tmp == "" )
			return "/";

		return tmp;
	}

}

//!//////////////////////////////////////////////////////////

static const enum EHTTPRequestType
{
	EHRT_OPTIONS,
	EHRT_GET,
	EHRT_HEAD,
	EHRT_POST,
	EHRT_PUT,
	EHRT_DELETE,
	EHRT_TRACE,
	EHRT_CONNECT
}

static const char[][] HTTPRequestType =
[
	EHTTPRequestType.EHRT_OPTIONS:"OPTIONS",
	EHTTPRequestType.EHRT_GET:"GET",
	EHTTPRequestType.EHRT_HEAD:"HEAD",
	EHTTPRequestType.EHRT_POST:"POST",
	EHTTPRequestType.EHRT_PUT:"PUT",
	EHTTPRequestType.EHRT_DELETE:"DELETE",
	EHTTPRequestType.EHRT_TRACE:"TRACE",
	EHTTPRequestType.EHRT_CONNECT:"CONNECT"
];

//!//////////////////////////////////////////////////////////

struct SHTTPStatusCode
{
    uint code;

    char[] getMsg()
    {
        return HTTPStatusCodes[ code ];
    }
};

// This is why I love 'D' :) Sooo easy
// .. well, assuming only 79 entries are allocated - not the full 510 .. perhaps this needs to be tested ?
// Status codes for HTTP Requests - ripped from Wikipedia
static const char[][] HTTPStatusCodes =
[
    000:"Fatal Error",
    100:"Continue",
    101:"Switching Protocols",
    102:"Processing",
    200:"OK",
    201:"Created",
    202:"Accepted",
    203:"Non-Authoritative Information",
    204:"No Content",
    205:"Reset Content",
    206:"Partial Content",
    207:"Multi-Status",
    300:"Multiple Choices",
    301:"Moved Permanently",
    302:"Found",
    303:"See Other",
    304:"Not Modified",
    305:"Use Proxy",
    306:"Switch Proxy",
    307:"Temporary Redirect",
    400:"Bad Request",
    401:"Unauthorized",
    402:"Payment Required",
    403:"Forbidden",
    404:"Not Found",
    405:"Method Not Allowed",
    406:"Not Acceptable",
    407:"Proxy Authentication Required",
    408:"Request Timeout",
    409:"Conflict",
    410:"Gone",
    411:"Length Required",
    412:"Precondition Failed",
    413:"Request Entity Too Large",
    414:"Request-URI Too Long",
    415:"Unsupported Media Type",
    416:"Requested Range Not Satisfiable",
    417:"Expectation Failed",
    422:"Unprocessable Entity",
    423:"Locked",
    424:"Failed Dependency",
    425:"Unordered Collection",
    426:"Upgrade Required",
    449:"Retry With",
    500:"Internal Server Error",
    501:"Not Implemented",
    502:"Bad Gateway",
    503:"Service Unavailable",
    504:"Gateway Timeout",
    505:"HTTP Version Not Supported",
    507:"Insufficient Storage",
    509:"Bandwidth Limit Exceeded"
];
