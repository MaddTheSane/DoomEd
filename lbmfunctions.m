#include <MacTypes.h>
#import <AppKit/AppKit.h>
#import "lbmfunctions.h"


// exception code
//#define LBMERR	NX_APPBASE

#define	BASEBYTEIMAGESIZE	64000

byte		*lbmpalette = NULL;
int		byteimagesize;
byte		*byteimage = NULL;
int		byteimagewidth, byteimageheight;

/*
============================================================================

						LBM STUFF

============================================================================
*/

#define PEL_WRITE_ADR		0x3c8
#define PEL_READ_ADR		0x3c7
#define PEL_DATA			0x3c9

extern NSExceptionName LBMExceptionName;
NSExceptionName LBMExceptionName = @"LBMException";

NS_ENUM(OSType) {
	//FORMID = 'FORM',
	ILBMID = 'ILBM',
	PBMID  = 'PBM ',
	BMHDID = 'BMHD',
	BODYID = 'BODY',
	CMAPID = 'CMAP',
};

#if 0
}
#endif

typedef unsigned char	UBYTE;
typedef short			WORD;
typedef unsigned short	UWORD;
typedef int				LONG;

typedef NS_ENUM(UBYTE, mask_t)
{
	ms_none,
	ms_mask,
	ms_transcolor,
	ms_lasso
};

typedef NS_ENUM(UBYTE, compress_t)
{
	cm_none,
	cm_rle1
};

typedef struct
{
	UWORD		w,h;
	WORD		x,y;
	UBYTE		nPlanes;
	mask_t		masking;
	compress_t	compression;
	UBYTE		pad1;
	UWORD		transparentColor;
	UBYTE		xAspect, yAspect;
	WORD		pageWidth,pageHeight;
} bmhd_t;

//
// things that might need to be freed on an exception
//
NSFileHandle		*filestream;		///< the memory map of the lbm file
byte				*byteimage;			///< the decompressed lbm image, expanded to 8 bits/pixel
unsigned			*meschedimage;		///< 32 bit truecolor
NSBitmapImageRep	*imagerep;			///< NSBitmapImageRep for meschedimage

//
// this stuff will remain current until another image is loaded
//
bmhd_t		bmhd;
unsigned	intpalette[256];			// (red<<24) + (green<<16) + (blue<<8) + 255


static long	Align (long l)
{
	if (l&1)
		return l+1;
	return l;
}



/*
================
=
= LBMRLEdecompress
=
= Source must be evenly aligned!
=
================
*/

static byte  const *LBMRLEDecompress (byte const *source, byte *unpacked, int bpwidth)
{
	int 	count;
	byte	b,rept;

	count = 0;

	do
	{
		rept = *source++;

		if (rept > 0x80)
		{
			rept = (rept^0xff)+2;
			b = *source++;
			memset(unpacked,b,rept);
			unpacked += rept;
		}
		else if (rept < 0x80)
		{
			rept++;
			memcpy(unpacked,source,rept);
			unpacked += rept;
			source += rept;
		}
		else
			rept = 0;		// rept of 0x80 is NOP

		count += rept;

	} while (count<bpwidth);

	if (count>bpwidth) {
		[NSException raise:LBMExceptionName format:@"Decompression exceeded width"];
	}


	return source;
}


#define BPLANESIZE	128
byte	bitplanes[9][BPLANESIZE];	// max size 1024 by 9 bit planes

/*
==================
=
= DecompressRLEPBM
=
= Decompresses the body chunk
=
==================
*/

static void DecompressRLEPBM (byte const *source, byte *dest, int width, int height)
{
	int		y;
	
	for (y=0 ; y<height ; y++, dest += width)
		source = LBMRLEDecompress (source, dest , width);
}


/*
==================
=
= ExtractUncompressedPBM
=
=  Just gets rid of the padding bytes if present
=
==================
*/

static void ExtractUncompressedPBM (byte const *source, byte *dest, int width, int height)
{
	int		y;
	
	if (width & 1)
	{
		for (y=0 ; y<height ; y++, dest += width)
		{
			memcpy (dest,source,width);
			source += width+1;
		}
	}
	else
		memcpy (dest, source, width*height);	// no padding
}


/*
==========================================================================
=
= LoadRawLBM
=
= Upon success:
= 	byteimage, byteimagewidth, byteimageheight, and lbmpalette will be full
=
= The byteimage and lbmpalette buffers are normally reused between calls, but you can copy the
= pointers and set them to NULL to force reallocation
=
==========================================================================
*/

BOOL	LoadRawLBM (char const *filename)
{
	byte	 	*LBM_P,  *LBMEND_P;
	
	int		formtype,formlength;
	int		chunktype,chunklength;

	byte		*cmap;
	byte	  	*body;

	int		size;
	
	//===========
	@try {
		//===========
		
		cmap = NULL;
		body = NULL;
		filestream = nil;
		//printf ("Filename: %s\n",filename);
		//
		// load the LBM with file mapping
		//
		filestream = [NSFileHandle fileHandleForUpdatingAtPath:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:filename length:strlen(filename)]];// NXMapFile (filename, NX_READONLY);
		if (!filestream) {
			[NSException raise:LBMExceptionName format:@"Couldn't map file"];
		}
		
		NSData *datastream = [filestream readDataToEndOfFile];
		
		
		//
		// parse the LBM header
		//
		LBM_P = [datastream bytes];
		
		if ( *(OSType  *)LBM_P != CFSwapInt32BigToHost(FORMID) ) {
			[NSException raise:LBMExceptionName format:@"No FORM ID at start of file!"];
		}
		
		LBM_P += 4;
		formlength = CFSwapInt32BigToHost(*(int  *)LBM_P);
		LBM_P += 4;
		LBMEND_P = LBM_P + Align(formlength);
		
		formtype = CFSwapInt32BigToHost(*(int  *)LBM_P);
		
		if (formtype != ILBMID && formtype != PBMID) {
			[NSException raise:LBMExceptionName format:@"Form not ILBM or PBM"];
		}
		
		LBM_P += 4;
		
		//
		// find the important chunks
		//
		while (LBM_P < LBMEND_P)
		{
			chunktype = CFSwapInt32BigToHost(*(int  *)LBM_P);
			LBM_P += 4;
			chunklength = CFSwapInt32BigToHost(*(int  *)LBM_P);
			LBM_P += 4;
			
			switch (chunktype)
			{
				case BMHDID:
					memcpy (&bmhd,LBM_P,sizeof(bmhd));
					break;
					
				case CMAPID:
					cmap = LBM_P;
					break;
					
				case BODYID:
					body = LBM_P;
					break;
			}
			
			LBM_P += Align(chunklength);
		}
		
		//
		// all done parsing
		// cmap and pic should be filled in
		//
		if ( bmhd.compression != cm_rle1 && bmhd.compression != cm_none) {
			[NSException raise:LBMExceptionName format:@"Unknown compression type"];
		}
		
		if (!cmap) {
			[NSException raise:LBMExceptionName format:@"No CMAP in file"];
		}
		
		if (!body){
			[NSException raise:LBMExceptionName format:@"No BODY in file"];
		}
		if (formtype != PBMID) {
			[NSException raise:LBMExceptionName format:@"Can't read interlaced LBMS yet..."];
		}
		
		//
		// allocate new buffers if needed and copy info
		//
		if (!byteimage)
		{
			byteimagesize = BASEBYTEIMAGESIZE;
			byteimage = malloc (byteimagesize);
			if (!byteimage) {
				[NSException raise:LBMExceptionName format:@"Couldn't allocate byteimage"];
			}
		}
		
		if (!lbmpalette)
		{
			lbmpalette = malloc (768);
			if (!lbmpalette) {
				[NSException raise:LBMExceptionName format:@"Couldn't allocate lbmpalette"];
			}
		}
		memcpy (lbmpalette, cmap, 768);
		
		byteimagewidth = bmhd.w;
		byteimageheight = bmhd.h;
		
		size = byteimagewidth * byteimageheight;
		
		if (size > byteimagesize)
		{
			byteimage = realloc (&byteimage, byteimagesize);
			if (!byteimage) {
				[NSException raise:LBMExceptionName format:@"Couldn't realloc byteimage"];
			}
		}
		
		if (bmhd.compression == cm_none)
			ExtractUncompressedPBM (body, byteimage, byteimagewidth, byteimageheight);
		else if (bmhd.compression == cm_rle1)
			DecompressRLEPBM (body, byteimage, byteimagewidth, byteimageheight);
		
		return YES;
		
		//===========
	} @catch (NSException *localException) {
		//===========
		if (filestream) {
			filestream = nil;
			//NXCloseMemory(filestream, NX_FREEBUFFER);
		}
		if (meschedimage)
			free (meschedimage);
		
		if (![localException.name isEqualToString:LBMExceptionName])
		{
			NSAlert *alert = [NSAlert new];
			alert.messageText = @"LBM Error";
			alert.informativeText = [NSString stringWithFormat:@"Unknown exception: %@", localException];
			[localException raise];
		} else {
			NSAlert *alert = [NSAlert new];
			alert.messageText = @"LBM Error";
			alert.informativeText = localException.reason;
			[alert runModal];
		}
		//===========
	}
	//===========
	return NO;
}


/*
==========================================================================
=
= SaveRawLBM
=
= Writes out a VGA lbm in PBM format
= The palette values should be in the full 0-256 scale
= Returns NO on error
==========================================================================
*/

bmhd_t	basebmhd = {320,200,0,0,8,0,0,0,0,5,6,320,200};

static void saveType(byte ** data, OSType typ)
{
	int* tmpPtr = (int *)(*data);
	*tmpPtr = CFSwapInt32HostToBig(typ);
	uintptr_t *thePtr = (uintptr_t *)data;
	*thePtr += sizeof(int);
}

BOOL SaveRawLBM ( char const *filename, byte const *data, int width, int height
	, byte const *palette)
{
	byte		*lbm,*lbmptr;
	int			*formlength,*bmhdlength,*cmaplength,*bodylength;
	ssize_t		length, written;
	int			handle;
	
	printf ("Writing %s (%i*%i) (%p, %p)...\n",filename, width,height,(void *)data,(void *)palette);
	
	lbm = lbmptr = malloc (width*height+2048);
	if (!lbm)
	{
		NSLog (@"couldn't malloc %i bytes\n",width*height+2048);
		return NO;
	}
	
	if (!palette  || !data)
	{
		free(lbm);
		NSLog (@"SaveLBM called with palette: %p  data: %p\n", palette, data);
		return NO;
	}
	
	//
	// start FORM
	//
	saveType(&lbmptr, FORMID);
	
	formlength = (int *)lbmptr;
	lbmptr+=4;			// leave space for length
	
	saveType(&lbmptr, PBMID);

	//
	// write BMHD
	//
	saveType(&lbmptr, BMHDID);
	
	bmhdlength = (int *)lbmptr;
	lbmptr+=4;			// leave space for length
	
	basebmhd.w = width;
	basebmhd.h = height;
	basebmhd.w = CFSwapInt16HostToBig(basebmhd.w);
	basebmhd.h = CFSwapInt16HostToBig(basebmhd.h);
	basebmhd.pageWidth = CFSwapInt16HostToBig(basebmhd.pageWidth);
	basebmhd.pageHeight = CFSwapInt16HostToBig(basebmhd.pageHeight);
	memcpy (lbmptr,&basebmhd,sizeof(basebmhd));
	lbmptr += sizeof(basebmhd);
	
	length = lbmptr-(byte *)bmhdlength-4;
	*bmhdlength = CFSwapInt32HostToBig((int)length);
	if (length&1)
		*lbmptr++ = 0;		// pad chunk to even offset
	
	//
	// write CMAP
	//
	saveType(&lbmptr, CMAPID);
	
	cmaplength = (int *)lbmptr;
	lbmptr+=4;			// leave space for length
	
	memcpy (lbmptr,palette,768);
	lbmptr += 768;
	
	length = lbmptr-(byte *)cmaplength-4;
	*cmaplength = CFSwapInt16HostToBig(length);
	if (length&1)
		*lbmptr++ = 0;		// pad chunk to even offset
	
	//
	// write BODY
	//
	saveType(&lbmptr, BODYID);
	
	bodylength = (int *)lbmptr;
	lbmptr+=4;			// leave space for length
	
	memcpy (lbmptr,data,width*height);
	lbmptr += width*height;
	
	length = lbmptr-(byte *)bodylength-4;
	*bodylength = CFSwapInt16HostToBig(length);
	if (length&1)
		*lbmptr++ = 0;		// pad chunk to even offset
	
	//
	// done
	//
	length = lbmptr-(byte *)formlength-4;
	*formlength = CFSwapInt16HostToBig(length);
	if (length&1)
		*lbmptr++ = 0;		// pad chunk to even offset

	//
	// write the file out
	//
	handle = open(filename, O_RDWR | O_CREAT | O_TRUNC, 0666);
	if (handle == -1)
	{
		free (lbm);
		NSLog(@"Error opening %s: %s\n", filename, strerror(errno));
		return NO;
	}
	
	length = lbmptr-lbm;
	written = write (handle,lbm,length);
	if (written != length)
	{
		close (handle);
		unlink (filename);
		free (lbm);
		if (written == -1)
			NSLog (@"Error writing to %s: %s\n", filename, strerror(errno));
		else
			NSLog (@"Only wrote %zi of %zi bytes to %s: %s\n", written, length, filename, strerror(errno));
		return NO;
	}
	
	close (handle);
	free (lbm);
	
	return YES;
}


/*
==========================================================================
=
= LBMpaletteTo??
=
==========================================================================
*/

void LBMpaletteTo16 (byte const *lbmpal, unsigned short *pal)
{
	int	r, g, b;

	for (int i=0 ; i<256 ; i++)
	{
		r = (*lbmpal++)>>4;
		g = (*lbmpal++)>>4;
		b = (*lbmpal++)>>4;
		pal[i] = CFSwapInt16BigToHost( (r<<12) + (g<<8) + (b<<4) + 15 );
	}
}

void LBMpaletteTo32 (byte const *lbmpal, unsigned *pal)
{
	int r, g, b;

	for (int i=0 ; i<256 ; i++)
	{
		r = *lbmpal++;
		g = *lbmpal++;
		b = *lbmpal++;
		pal[i] = CFSwapInt32BigToHost( (r<<24) + (g<<16) + (b<<8) + 255 );
	}
}

/*
==========================================================================
=
= ConvertLBMTo??
=
==========================================================================
*/

void ConvertLBMTo16 (byte const *in1, unsigned short *out1, int count
	, unsigned short const *shortpal)
{
	byte	const *stop;
	
	stop = in1 + count;
	while (in1 != stop)
		*out1++ = shortpal[*in1++];
}

void ConvertLBMTo32 (byte const *in1, unsigned *out1, int count
	, unsigned const *longpal)
{
	byte	const *stop;
	
	stop = in1 + count;
	while (in1 != stop)
		*out1++ = longpal[*in1++];
}

/*
==========================================================================
=
= Image??FromRawLBM
=
==========================================================================
*/

NSBitmapImageRep *Image16FromRawLBM (byte const *data, int width, int height, byte const *palette)
{
	byte				*dest_p;
	NSBitmapImageRep	*image_i;
	unsigned short	shortpal[256];

	//
	// make an NXimage to hold the data
	//
	image_i = [[NSBitmapImageRep alloc]
			   initWithBitmapDataPlanes:NULL
			   pixelsWide:width
			   pixelsHigh:height
			   bitsPerSample:4
			   samplesPerPixel:3
			   hasAlpha:NO
			   isPlanar:NO
			   colorSpaceName:NSCalibratedRGBColorSpace
			   bytesPerRow:width*2
			   bitsPerPixel:16];
	
	if (!image_i)
		return nil;
	
	//
	// translate the picture
	//
	dest_p = [image_i bitmapData];
	LBMpaletteTo16 (palette, shortpal);
	ConvertLBMTo16 (data, (unsigned short *)dest_p, width*height, shortpal);

	return image_i;
}


NSBitmapImageRep *Image32FromRawLBM (byte const *data, int width, int height, byte const *palette)
{
	byte				*dest_p;
	NSBitmapImageRep	*image_i;
	unsigned			longpal[256];

	//
	// make an NXimage to hold the data
	//
	image_i = [[NSBitmapImageRep alloc]
			   initWithBitmapDataPlanes:NULL
			   pixelsWide:width
			   pixelsHigh:height
			   bitsPerSample:8
			   samplesPerPixel:3
			   hasAlpha:NO
			   isPlanar:NO
			   colorSpaceName:NSCalibratedRGBColorSpace
			   bytesPerRow:width*4
			   bitsPerPixel:32];
	
	if (!image_i)
		return nil;
	
	//
	// translate the picture
	//
	dest_p = [image_i bitmapData];
	LBMpaletteTo32 (palette, longpal);
	ConvertLBMTo32 (data, (unsigned  *)dest_p, width*height, longpal);

	return image_i;
}


/*
==========================================================================
=
= Image??FromLBMFile
=
==========================================================================
*/

NSBitmapImageRep *Image16FromLBMFile (char const *filename)
{
	if (!LoadRawLBM (filename))
		return nil;
	return Image16FromRawLBM (byteimage, byteimagewidth, byteimageheight, lbmpalette);
}


NSBitmapImageRep *Image32FromLBMFile (char const *filename)
{
	if (!LoadRawLBM (filename))
		return nil;
	return Image32FromRawLBM (byteimage, byteimagewidth, byteimageheight, lbmpalette);
}



