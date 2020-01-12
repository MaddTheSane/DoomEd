// doombsp.c

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "doombsp.h"

#ifdef REDOOMED
#   import "../RDEdoombsp.h"
#endif

id 			wad_i;
boolean		draw;

/*
==================
=
= main
=
==================
*/

#ifdef REDOOMED
// ReDoomEd embeds the doombsp tool's sources rather than building them as a separate binary,
// so renamed doombsp's main() to RDEdoombsp_main() to prevent multiple main() functions.
int RDEdoombsp_main(int argc, char **argv)
#else // Original
int main (int argc, char **argv)
#endif
{
	char		*inmapname, *scan, *scan2;
	char		outmapname[1024];
	char		basename[80];
#ifdef REDOOMED
	int	returnValue = 0;
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];

	NS_DURING   // Error() function was redefined to raise an objc exception instead of exit()
#endif
	
	memset (outmapname,0,sizeof(outmapname));
	memset (basename,0,sizeof(basename));
	inmapname = NULL;
	
	if (argc == 4)
	{
		if (strcmp(argv[1], "-draw"))
			Error ("doombsp [-draw] inmap outwadpath");
		inmapname = argv[2];
		strcpy (outmapname,argv[3]);
		draw = true;
		NXApp = [Application new];
	}
	else if (argc == 3)
	{
		inmapname = argv[1];
		strcpy (outmapname,argv[2]);
		draw = false;
	}
	else
		Error ("doombsp [-draw] inmap outwadpath");
		
	strcat (outmapname,"/");
	scan = inmapname+strlen(inmapname)-1;
	while (*scan != '.' && scan !=inmapname)
		scan--;
	if (scan == inmapname)
		strcpy (basename, inmapname);	// no extension
	else
	{
		scan2 = scan;
		while (*scan != '/' && scan !=inmapname)
			scan--;
		if (scan != inmapname)
			scan++;
		strncpy (basename, scan, scan2-scan);
	}
	
	strcat (outmapname, basename);
	strcat (outmapname,".wad");
	
printf ("output wadfile: %s\n", outmapname);

//
// write a label for the map name at the start of the wadfile
//
	wad_i = [[Wadfile alloc] initNew: outmapname];
	[wad_i addName:basename data:basename size:0];
	
	LoadDoomMap (inmapname);
	DrawMap ();
	BuildBSP ();
	
printf ("segment cuts: %i\n",cuts);

	SaveDoomMap ();
	SaveBlocks ();
	
	[wad_i writeDirectory];
	[wad_i close];

#ifdef REDOOMED
	NS_HANDLER

	NSRunAlertPanel([localException name], @"%@", @"OK", nil, nil, [localException reason]);
	returnValue = -1;

	NS_ENDHANDLER
#endif

	[wad_i free];
	
//getchar();

#ifdef REDOOMED
	[autoreleasePool release];
	return returnValue;
#else // Original
	return 0;
#endif
}

#ifdef REDOOMED
// Define Error() function here instead of cmdlib.c so it can throw an objc exception instead
// of calling exit()

void Error (char *format, ...)
{
	char errorStr[256];
	va_list argptr;

	va_start(argptr, format);
	vsnprintf (errorStr, sizeof(errorStr), format, argptr);
	va_end (argptr);

	[NSException raise: @"Doombsp Error" format: @"%s", errorStr];
}

#endif // REDOOMED
