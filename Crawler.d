import std.thread;
import std.string;
import std.c.time; // msleep(win) / sleep(*nix)

import MyIO;
import HTTPClient, HTTPDecl;
import DAPage, DAUser;
import Logger;

//!//////////////////////////////////////////////////////////////////////

//const char[] URLFILTER = ".deviantart.com";
const char[] HOSTENGINE = "some.web.site";
const char[] ANDPASSPARM = "&p=AHEXPASS";

static const MAX_REDIR = 5;

//!//////////////////////////////////////////////////////////////////////

class Crawler : public Thread
{
	HTTPClient client;
	SHTTPStatusCode status;
	Logger logger;

	DAPage curPage;
	DAUsr curusr;

	uint interval, runs;
	bit stopNext = false;

	ushort port;
	char[] url;

	char[] banlist;
	char[] leadsChecked, leadsToCheck, leadsNew;

	void uploadUser( DAUsr usr )
	{
		logger.log( "       Uploading user.." );

		char[] usrString = usr.toPost();
		status = client.request( (HOSTENGINE~"/user_upload.php"), EHTTPRequestType.EHRT_POST, (usrString~ANDPASSPARM) );

		if( status.code != 200 )
			logger.log( "       Program Error !\r\n       " ~ status.getMsg() ~ newline );
	}

	void removeBadLeads()
	{
			// for each new lead, check with the three other lists
			foreach( char[] lead ; splitlines(leadsNew) )
			{
					if( ifind(banlist,lead) == -1 ) // && ifind( leadsToCheck, lead ) == -1
					{ // If new lead is on none of the lists
							// Check with server
							status = client.request( (HOSTENGINE~"/user_check.php"), EHTTPRequestType.EHRT_POST, ("u="~lead~ANDPASSPARM) );

							if( status.code == 200 )
							{
									if( client.getBody()[0..1] == "0" )
									{
											leadsToCheck ~= lead ~ newline;
									}
							}
							else
							{
									logger.log( "       Program Error !\r\n       " ~ status.getMsg() ~ newline );
							}
					}
			}
	}

	char[] getNextURL()
	{
		uint nextLine = ifind( leadsToCheck, newline );
		char[] newurl;
		if( nextLine == -1 )
			newurl = leadsToCheck[0 .. $];
		else
			newurl = leadsToCheck[0 .. nextLine];
		leadsToCheck = leadsToCheck[nextLine+2 .. $];
		return "http://" ~ newurl ~ ".deviantart.com/";
	}

public:
	this( char[] _seed = "http://www.deviantart.com/random/deviant", uint _interval = 1000, char[] _banlist = "banlist.txt" )
	{
		url = _seed;
		interval = _interval;
		banlist = fromFile( _banlist );
		client = new HTTPClient();
	}

	void setLogger( Logger l )
	{
		logger = l;
	}

	bool step()
	{
		if( url == "" )
		{
			logger.log( "       Program Error !\r\n       No URL\r\n" );
			return false;
		}

		logger.log( "   ### Stepping ###" );
		logger.log( "       Url: " ~ url );
		
		try
		{
			// Max redirections, so we don't get trapped in a spider trap
			for( uint i = 0 ; i < MAX_REDIR ; i++ )
			{
				status = client.request( url, EHTTPRequestType.EHRT_GET );
				logger.log(status.getMsg());

				if( client.getNewLocation() != "" )
				{
					url = client.getNewLocation();
					logger.log( "       New Location: " ~ client.getNewLocation() );
				}
				else
					break;
			}

			curPage = new DAPage( client.getBody() );
		}
		catch( Object o )
		{
			logger.log("Fatal Error:\r\n" ~ o.toString());
		}

		if( !curPage.gotError() )
		{
			try
			{
				curusr = curPage.getUser();
				uploadUser( curusr );
				leadsNew ~= curPage.getLinks();
			}
			catch( Object e )
			{
				logger.log( "       Program Error !\r\n       " ~ e.toString() ~ newline );
				return false;
			}
		}
		else
		{
			logger.log( "       Page Error !\r\n" );
			return false;
		}

		// If no more leads to follow, go through collected leads
		if( leadsToCheck.length <= 0 )
			removeBadLeads();

		url = getNextURL();

		logger.log("");

		return true;
	}

	void stop()
	{
		stopNext = true;
	}

	int run()
	{
		while( getState() == Thread.TS.RUNNING && !stopNext )
		{
			step();
			// Wait between crawl steps to make sure we don't stress the server
			logger.log( "   Waiting...\r\n" );
			sleep( interval );
		}
		if( stopNext )
			stopNext = false;
		return 0;
	}
}
