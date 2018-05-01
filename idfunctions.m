#include <sys/stat.h>

#import "idfunctions.h"

/*
============
=
= BoxFromRect
=
============
*/

void BoxFromRect (box_t *box, NSRect *rect)
{
	box->left = rect->origin.x;
	box->right = box->left + rect->size.width;
	box->bottom= rect->origin.y;
	box->top = box->bottom + rect->size.height;	
}


/*
============
=
= BoxFromPoints
=
============
*/

void BoxFromPoints (box_t *box, NSPoint *p1, NSPoint *p2)
{
	if (p1->x < p2->x)
	{
		box->left = p1->x;
		box->right = p2->x;
	}
	else
	{
		box->right = p1->x;
		box->left = p2->x;
	}
	if (p1->y < p2->y)
	{
		box->bottom = p1->y;
		box->top = p2->y;
	}
	else
	{
		box->top = p1->y;
		box->bottom = p2->y;
	}
}


/*
================
=
= IDRectFromPoints
=
= Makes the rectangle just touch the two points
=
================
*/

void IDRectFromPoints(NSRect *rect, NSPoint const *p1, NSPoint const *p2 )
{
// return a rectangle that encloses the two points
	if (p1->x < p2->x)
	{
		rect->origin.x = p1->x;
		rect->size.width = p2->x - p1->x + 1;
	}
	else
	{
		rect->origin.x = p2->x;
		rect->size.width = p1->x - p2->x + 1;
	}
	
	if (p1->y < p2->y)
	{
		rect->origin.y = p1->y;
		rect->size.height = p2->y - p1->y + 1;
	}
	else
	{
		rect->origin.y = p2->y;
		rect->size.height = p1->y - p2->y + 1;
	}
}


/*
==================
=
= IDEnclosePoint
=
= Make the rect enclose the point if it doesn't allready
=
==================
*/

void IDEnclosePoint (NSRect *rect, NSPoint const *point)
{
	float	right, top;
	
	right = rect->origin.x + rect->size.width - 1;
	top = rect->origin.y + rect->size.height - 1;
	
	if (point->x < rect->origin.x)
		rect->origin.x = point->x;
	if (point->y < rect->origin.y)
		rect->origin.y = point->y;		
	if (point->x > right)
		right = point->x;
	if (point->y > top)
		top = point->y;
		
	rect->size.width = right - rect->origin.x + 1;
	rect->size.height = top - rect->origin.y + 1;
}


/*
===============
=
= ShortSwap
=
===============
*/

unsigned short ShortSwap (unsigned short dat)
{
	return CFSwapInt16LittleToHost (dat);
}


/*
===============
=
= LongSwap
=
===============
*/

unsigned LongSwap (unsigned dat)
{
	return CFSwapInt32LittleToHost (dat);
}


/*
================
=
= filelength
=
================
*/

off_t filelength (int handle)
{
	struct stat	fileinfo;
    
	if (fstat (handle,&fileinfo) == -1)
	{
		fprintf (stderr,"Error fstating");
		exit (1);
	}

	return fileinfo.st_size;
}

off_t tell (int handle)
{
	return lseek (handle, 0, L_INCR);
}


/*
================
=
= BackupFile
=
= Makes a file~ and unlinks the original
=
================
*/

void BackupFile (NSString *fname)
{
	NSString *backname = [fname stringByAppendingString:@"~"];
	
	unlink (backname.fileSystemRepresentation);
	link (fname.fileSystemRepresentation, backname.fileSystemRepresentation);
	unlink (fname.fileSystemRepresentation);
}

/*
==================
=
= DefaultExtension
=
==================
*/

void DefaultExtension (char *path, const char *extension)
{
	const char	*src;
//
// if path doesn't have a .EXT, append extension
// (extension should include the .)
//
	src = path + strlen(path) - 1;

	while (*src != '\\' && src != path)
	{
		if (*src == '.')
			return;			// it has an extension
		src--;
	}

	strcat (path, extension);
}

void DefaultPath (char *path, char *basepath)
{
	char	temp[128];

	if (path[0] == '\\')
		return;							// absolute path location
	strcpy (temp,path);
	strcpy (path,basepath);
	strcat (path,temp);
}


/*
======================
=
= ExtractFileName
=
======================
*/

void ExtractFileName (const char *path, char *dest)
{
	const char		*src;

	src = path + strlen(path) - 1;

//
// back up until a / or the start
//
	while (src != path && *(src-1) != '/')
		src--;

	strcpy (dest, src);
}


/*
===================
=
= StripExtension
=
===================
*/

void StripExtension (char *path)
{
	char	*c;
	
	c = path + strlen (path);
	
// search backwards for a period

	do
	{
		if (--c == path)
			return;		// no period in path string
	} while (*c != '.');
	
	*c = 0;				// terminate the string there
}


/*
===================
=
= StripFilename
=
===================
*/

void StripFilename (char *path)
{
	char	*c;
	
	c = path + strlen (path);
	
// search backwards for a slash

	do
	{
		if (--c == path)
			return;		// no period in path string
	} while (*c != '/');
	
	*c = 0;				// terminate the string there
}


/*
===================
=
= IdException
=
===================
*/

void IdException (char const *format, ...)
{
	char		msg[1025];
	va_list 	args;
	
	va_start(args, format);
	vsprintf(msg, format, args);
	va_end(args);
	strcat (msg,"\n");
	
	[[NSException exceptionWithName:@"DoomEdInternalException" reason:@(msg) userInfo:nil] raise];
}

