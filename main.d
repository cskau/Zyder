//import dfl.all;
//import GUI;

import std.thread;
import Crawler, Logger;

int main()
{
	short result = 0;

	Logger logger = new Logger();
	Crawler crawler = new Crawler();
	crawler.setLogger(logger);

	try
	{
		logger.log( " Starting crawler... " );
		if( crawler.getState() == Thread.TS.INITIAL )
			crawler.start();
		else
			crawler.run();
	}
	catch( Object o )
	{
		logger.log( "Fatal Error:\r\n" ~ o.toString() );
		result = -1;
	}

	return result;
}
