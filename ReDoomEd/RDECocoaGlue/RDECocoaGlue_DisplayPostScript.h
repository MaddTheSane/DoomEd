/*
    RDECocoaGlue_DisplayPostScript.h

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for Mac OS X and GNUstep. ReDoomEd is a Doom game map
    editor, ported from id Software's DoomEd for NeXTSTEP.

    This file is distributed under the terms of the GNU Affero General Public License
    as published by the Free Software Foundation. You can redistribute it and/or modify
    it under the terms of version 3 of the License, or (at your option) any later
    version approved for distribution by this file's copyright holder (or an authorized
    proxy).

    ReDoomEd is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License along with
    this program. If not, see <http://www.gnu.org/licenses/>.
*/

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(unsigned char, DPSNumberFormat) {
#ifdef __BIG_ENDIAN__
    dps_float = 48,
    dps_long = 0,
    dps_short = 32
#else
    dps_float = 48+128,
    dps_long = 0+128,
    dps_short = 32+128
#endif
};

typedef NS_ENUM(unsigned char, DPSUserPathOp) {
    dps_setbbox = 0,
    dps_moveto,
    dps_rmoveto,
    dps_lineto,
    dps_rlineto,
    dps_curveto,
    dps_rcurveto,
    dps_arc,
    dps_arcn,
    dps_arct,
    dps_closepath,
    dps_ucache
};

typedef NS_ENUM(short, DPSUserPathAction)
{
    dps_uappend = 176,
    dps_ufill = 179,
    dps_ueofill = 178,
    dps_ustroke = 183,
    dps_ustrokepath = 364,
    dps_inufill = 93,
    dps_inueofill = 92,
    dps_inustroke = 312,
    dps_def = 51,
    dps_put = 120
};


void RDE_PSsetinstance(BOOL set);

void RDE_PSnewinstance(void);


void RDE_PSsetrgbcolor(float red, float green, float blue);

void RDE_PSsetgray(float gray);

void RDE_PSsetlinewidth(float width);

void RDE_PSselectfont(const char *name, float size);

void RDE_PSrotate(float angle);


void RDE_PSnewpath(void);

void RDE_PSmoveto(float x, float y);

void RDE_PSlineto(float x, float y);

void RDE_PSrlineto(float x, float y);

void RDE_PSclosepath(void);

void RDE_PSstroke(void);

void RDE_PSinstroke(float x, float y, int *pflag);

void RDE_PSsetdash(float pattern[], int size, float offset);


void RDE_PSshow(const char *string);


void RDE_PScompositerect(float x, float y, float w, float h, NSCompositingOperation operation);


void RDE_DPSDoUserPath(const void *coords, int numCoords, DPSNumberFormat numType,
                        const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action);


void RDE_DPSGlue_DrawInstanceIfNeeded(void);

void RDE_DPSGlue_NXFrameRectWithWidth(NSRect *rectPtr, float frameWidth);

void RDE_DPSGlue_SetNSColor(NSColor *color);

void RDE_DPSGlue_SetIsDrawingViewRect(BOOL isDrawingViewRect);


#define PSsetinstance   RDE_PSsetinstance
#define PSnewinstance   RDE_PSnewinstance

#define PSsetrgbcolor   RDE_PSsetrgbcolor
#define PSsetgray       RDE_PSsetgray
#define PSsetlinewidth  RDE_PSsetlinewidth
#define PSselectfont    RDE_PSselectfont
#define PSrotate        RDE_PSrotate
#define PSsetdash       RDE_PSsetdash

#define PSnewpath       RDE_PSnewpath
#define PSmoveto        RDE_PSmoveto
#define PSlineto        RDE_PSlineto
#define PSrlineto       RDE_PSrlineto
#define PSclosepath     RDE_PSclosepath
#define PSstroke        RDE_PSstroke
#define PSinstroke      RDE_PSinstroke

#define PSshow          RDE_PSshow

#define PScompositerect RDE_PScompositerect

#define DPSDoUserPath   RDE_DPSDoUserPath

