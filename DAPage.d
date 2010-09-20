import std.string;

import DAUser;
import HTTPClient, HTTPDecl, HTTPUtil;
import MLParser;

import std.stdio;

class DAPage
{
private:
	MLTree html;

public:
	this( char[] _body )
	{
		html = new MLTree( _body );
	}

	DAUsr getUser()
	{
		DAUsr usr = new DAUsr();
		MLNode node;

		node = html.getNodeWith("div","class","iconleft deviant profile");

		if( !node.hasParm("class") || !(node.getParm("class") == "iconleft deviant profile") )
            return usr;

		//!// Name
		usr.setInfo( "name", node.getChildWith( "small" ).getText()[0..($-7)] );

		node = node.getChildWith( "h1" ).getChildWith( "a", "class", "u" );

        //!// Username
        usr.setUsername( node.getText() );

        node = node.getChildWith( "img", "class", "avatar" );

        //!// Avatar ending
        if( node.getParm("src") != "http://a.deviantart.com/avatars/default.gif" )
        {
            usr.setInfo( "avatarend", std.string.split( node.getParm("src"), "." )[$-1] );
        }

		node = html.getNodeWith("div","id","deviant-info");
		node = node.getChildNo(0);

        //!// Status
        switch( strip( node.getChildNo(0).getChildNo(0).getText()[8..$] ) )
        {
        case "Member":
            usr.setInfo( "status", 1 );
            break;
        case "deviantART Subscriber":
            usr.setInfo( "status", 2 );
            break;
        case "Official Beta Tester":
            usr.setInfo( "status", 3 );
            break;
        case "Banned":
            usr.setInfo( "status", 4 );
            break;
        case "Message Network Operator":
            usr.setInfo( "status", 5 );
            break;
        case "Help":
            usr.setInfo( "status", 6 );
            break;
        case "Senior Member":
            usr.setInfo( "status", 7 );
            break;
        case "Gallery Director":
            usr.setInfo( "status", 8 );
            break;
        case "Administrator":
            usr.setInfo( "status", 9 );
            break;
        case "Co-Founder":
            usr.setInfo( "status", 10 );
            break;
        case "Minister of deviantART":
            usr.setInfo( "status", 11 );
            break;
        case "Creative Staff":
            usr.setInfo( "status", 12 );
            break;
        default:
            usr.setInfo( "status", 0 );
            break;
        }

		//!// Type
        usr.setInfo( "type", node.getChildNo(2).getText );

		//!// Gender / Country
        char[] gc = node.getChildNo(4).getText;
        char[][] gcs = std.string.split( gc, "/" );
        if( gcs.length > 1 )
        {
            // Pass gender as a 1-length array and not a char to prevent collision with int version of setInfo
            usr.setInfo( "gender", strip(gcs[0])[0..1] );
            usr.setInfo( "country", strip(gcs[1]) );
        }
        else
        {
            usr.setInfo( "country", strip(gc) );
        }

		//!// Since
		node = node.getChildNo(8);
        usr.setInfo( "devsince", node.getChildNo(0).getText );

		node = html.getNodeWith("div","id","deviant-stats");
		node = node.getChildNo(0);

		//!// Stats
		foreach( MLNode* stat ; node.getChildren() )
		{
		    if( stat.getChildren().length > 1 )
		    {
                switch( stat.getChildNo(1).getText() )
                {
                    case " Deviations":
                        usr.setInfo( "deviations", cast(uint) atoi(removechars(stat.getChildNo(0).getText(),",")) );
                        break;
                    case " Scraps [":
                        usr.setInfo( "scraps", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    case " Deviation Comments":
                        usr.setInfo( "deviationComments", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    case " Deviant Comments":
                        usr.setInfo( "deviantComments", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    case " News Comments":
                        usr.setInfo( "newsComments", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    case " Forum Posts":
                        usr.setInfo( "forumPosts", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    case " Pageviews":
                        usr.setInfo( "pageviews", cast(uint) atoi(removechars(stat.getChildNo(0).getText,",")) );
                        break;
                    default:
                        break;
                }
		    }
		}

		//!// Devious Information
		if( html.hasNodeWith("div","id","deviant-infobox") )
		{
            node = html.getNodeWith("div","id","deviant-infobox");

            //!// Contact info
            foreach( MLNode* info ; node.getChildWith( "div", "class", "ppp" ).getChildNo(0).getChildWith( "ul", "class", "f h list" ).getChildren() )
            {
                if( info.getChildren().length > 1 )
                {
                    switch( info.getChildNo(0).getChildNo(0).getText() )
                    {
                    case "Website":
                        usr.setInfo( "website", strip( info.getChildNo(2).getParm("href") ) );
                        break;
                    case "Email":
                        usr.setInfo( "email", toURISafe( convHTMLChars( strip( info.getChildNo(2).getText() ) ) ) );
                        break;
                    case "AIM":
                        usr.setInfo( "aim", strip( info.getChildNo(2).getText() ) );
                        break;
                    case "MSN":
                        usr.setInfo( "msn", strip( info.getChildNo(2).getText() ) );
                        break;
                    case "Yahoo":
                        usr.setInfo( "yahoo", strip( info.getChildNo(2).getText() ) );
                        break;
                    case "ICQ":
                        usr.setInfo( "icq", strip( info.getChildNo(2).getText() ) );
                        break;
                    case "Skype":
                        usr.setInfo( "skype", strip( info.getChildNo(2).getText() ) );
                        break;
                    default:
                        break;
                    }
                }
            }

            //!// Additional info
            foreach( MLNode* info ; node.getChildWith("ul","class","f list").getChildren() )
            {
                if( info.getChildren().length > 1 )
                {
                    switch( info.getChildNo(0).getText() )
                    {
                    case "Current Age: ":
                        usr.setInfo( "curage", info.getChildNo(1).getText() );
                        break;
                    case "Current Residence: ":
                        usr.setInfo( "curresidence", info.getChildNo(1).getText() );
                        break;
                    case "Interests: ":
                        usr.setInfo( "interests", info.getChildNo(1).getText() );
                        break;
                    case "Favourite movie: ":
                        usr.setInfo( "favmovie", info.getChildNo(1).getText() );
                        break;
                    case "Favourite band or musician: ":
                        usr.setInfo( "favband", info.getChildNo(1).getText() );
                        break;
                    case "Favourite genre of music: ":
                        usr.setInfo( "favgenre", info.getChildNo(1).getText() );
                        break;
                    case "Favourite artist:":
                        usr.setInfo( "favartist", info.getChildNo(1).getText() );
                        break;
                    case "Favourite poet or writer: ":
                        usr.setInfo( "favwriter", info.getChildNo(1).getText() );
                        break;
                    case "Favourite photographer: ":
                        usr.setInfo( "favphotographer", info.getChildNo(1).getText() );
                        break;
                    case "Favourite style or digital art: ":
                        usr.setInfo( "favstyle", info.getChildNo(1).getText() );
                        break;
                    case "Operating System: ":
                        usr.setInfo( "os", info.getChildNo(1).getText() );
                        break;
                    case "MP3 player of choice: ":
                        usr.setInfo( "mp3player", info.getChildNo(1).getText() );
                        break;
                    case "Shell of choice: ":
                        usr.setInfo( "shell", info.getChildNo(1).getText() );
                        break;
                    case "Wallpaper of choice: ":
                        usr.setInfo( "wallpaper", info.getChildNo(1).getText() );
                        break;
                    case "Skin of choice: ":
                        usr.setInfo( "skin", info.getChildNo(1).getText() );
                        break;
                    case "Favourite game: ":
                        usr.setInfo( "favgame", info.getChildNo(1).getText() );
                        break;
                    case "Favourite gaming platform: ":
                        usr.setInfo( "favplatform", info.getChildNo(1).getText() );
                        break;
                    case "Favourite cartoon character: ":
                        usr.setInfo( "favcharacter", info.getChildNo(1).getText() );
                        break;
                    case "Personal Quote: ":
                        usr.setInfo( "quote", info.getChildNo(1).getText() );
                        break;
                    case "Tools of the Trade: ":
                        usr.setInfo( "tools", info.getChildNo(1).getText() );
                        break;
                    default:
                        break;
                    }
                }
            }
		}

		return usr;
	}

	char[] getLinks()
	{
	    char[] links = "";

        foreach( uint i, m ; std.regexp.split(html.toString(),`([a-zA-Z0-9\-]*?)\.deviantart\.com`,"g") ) // using ` for raw string
        {
            if( i%2 ) // only every second string is link
                links ~= m ~ newline;
        }

		return links;
	}

	bool gotError()
	{
	    if( html.hasNodeWith("body","class","error") )
            return true;
        return false;
	}

	char[] toString()
	{
	    return html.toString();
	}
}
