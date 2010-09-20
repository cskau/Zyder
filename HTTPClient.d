import std.string;
import std.socket, std.stream, std.socketstream; // sockets
import std.stdio;

import HTTPDecl, HTTPUtil;

class HTTPClient
{
private:
//!// General vars
    Socket sock;
    Stream sockstream;

    ushort port = 80;

//!// Request vars
    char[][] reqHeadParms;
    uint maxRedirs = 0;
    bool autoRedir = true;

//!// Response vars
    SHTTPStatusCode statusCode;
    bit chunked;
    char[] respHeader, respBody, respFooter;
    char[] newLoc, lineRead;
    uint bodyLen, readLen;

//!// -----------------------

    void clean()
    {
        statusCode.code = 0;
        chunked = false;
        respHeader = "";
        respBody = "";
        respFooter = "";
        bodyLen = 0;
        readLen = 0;
        newLoc = "";
    }

    void connect( char[] url )
    {
			assert(url.length > 0);
			CURL c = new CURL(url);
			if( !c ) throw( new Exception("Failed to resolve host!") );
			InternetAddress ia;
			writefln("here");
			try{
			if( (ia = new InternetAddress( c.host(), port ) ) )
			{}else 
			writefln("here");
			}catch(Object o){ writefln(o.toString());}
			writefln("here");
			if( !ia ) c
			sock = new TcpSocket( ia );
			if( !sock ) throw( new Exception("Socket failed!") );
			assert(sock);
			sockstream = new SocketStream( sock );
			assert(sockstream);
    }

    void disconnect()
    {
        sockstream.close();
        sock.close();
    }

    void readHeader()
    {
        while( (lineRead = sockstream.readLine()) != "" )
            respHeader ~= lineRead ~ newline;

        foreach( char[] line ; splitlines(respHeader) )
        {
            // Use ifind to perform bound-safe and case-insensitive string comparison
            if( ifind(line,"HTTP/1.1 ") == 0 )
                statusCode.code = cast(uint) atoi( line[9 .. 12] );
            else if( ifind(line,"Transfer-Encoding: chunked") == 0 )
                chunked = true;
            else if( ifind(line,"Content-Length: ") == 0 )
                bodyLen = cast(uint) atoi( line[16 .. $] );
            else if( ifind(line,"Location: ") == 0 )
                newLoc = line[10 .. $];
        }
    }

    void readChuncked()
    {
        char[] chunkStr = "";

        while( chunkStr == "" )
            chunkStr = sockstream.readLine();

        // Everything after ";" is comment data, BUT ..
        // Unnecesary split, since hex2dec stops automaticly when non-hex chars are encountered
        // uint chunkLen = hex2dec( split( sockstream.readLine(), ";" )[0] );
        uint chunkLen = hex2dec( chunkStr );

        while( chunkLen > 0 ) // When we get 0 as chunck length we're at "End-of-Chuncks"
        {
            chunkStr = "";

            while( chunkStr.length < chunkLen )
                chunkStr ~= sockstream.readLine() ~ "\r";

            respBody ~= chunkStr;
            chunkStr = "";

            while( chunkStr == "" )
                chunkStr = sockstream.readLine();
            chunkLen = hex2dec( chunkStr );
        }
    }

    void readUnChuncked()
    {
        while( respBody.length < bodyLen )
            respBody ~= sockstream.readLine() ~ newline;
    }

    void readFooter()
    {
        while( (lineRead = sockstream.readLine()) != "" )
            respFooter ~= lineRead;
    }

    char[] constructRequest( char[] url, EHTTPRequestType reqType, char[] strBody )
    {
        CURL myUrl = new CURL(url);
        char[] retStr = HTTPRequestType[reqType] ~ myUrl.local ~ " HTTP/1.1\r\n"
          ~ "Host: " ~ myUrl.host ~ "\r\n"
          ~ "Connection: close\r\n"
          ~ "Content-Type: application/x-www-form-urlencoded\r\n"
          ~ "Content-Length: " ~ std.string.toString(strBody.length) ~ "\r\n";

        foreach( char[] parm ; reqHeadParms )
            retStr ~= parm ~ "\r\n";

        retStr ~= "\r\n" ~ strBody ~ "\r\n";

        return retStr;
    }

public:
    char[] getHeader() { return respHeader; }
    char[] getBody() { return respBody; }
    char[] getFooter() { return respFooter; }

    void addRequestParm( char[] parm ) { reqHeadParms ~= parm; }

    char[] getNewLocation() { return newLoc; }

    SHTTPStatusCode request( char[] url, EHTTPRequestType reqType, char[] strBody = "" )
    {
    	
        writefln("ssdsa");
        connect( url );

        writefln("ssdsa");
        
        if( sockstream )
        	sockstream.writeString( constructRequest( url, reqType, strBody ) ~ "\r\n\r\n" );
        else
        	return statusCode;

        clean();
        
        writefln("ssdsa");

        readHeader();
        if( chunked )
            readChuncked();
        else
            readUnChuncked();
        readFooter();

        disconnect();

        return statusCode;
    }

    SHTTPStatusCode requestRaw( char[] url, char[] reqStr )
    {
        if( newLoc != "" )
            url = newLoc;

        connect( url );

        sockstream.writeString( reqStr ~ "\r\n\r\n" );

        clean();

        readHeader();
        if( chunked )
            readChuncked();
        else
            readUnChuncked();
        readFooter();

        disconnect();

        return statusCode;
    }
}
