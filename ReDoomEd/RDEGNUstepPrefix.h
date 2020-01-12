/*
    RDEGNUstepPrefix.h

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for GNUstep.
    ReDoomEd is a Doom game map editor, ported from id Software's DoomEd for NeXTSTEP.
*/

#ifdef GNUSTEP

#   import "RDEGNUstepGlue/RDEGNUstepFrameworksVersionCheck.h"

//  if CGFLOAT_IS_DOUBLE is undefined, define it using GNUstep's CGFLOAT_IS_DBL
#   if !defined(CGFLOAT_IS_DOUBLE) && defined(CGFLOAT_IS_DBL)
#       define CGFLOAT_IS_DOUBLE CGFLOAT_IS_DBL
#   endif

//  MinGW: May have #defined ERROR, so undefine it (ReDoomEd uses ERROR as a goto label)
#   ifdef ERROR
#       undef ERROR
#   endif

//  Solaris: Define missing math functions
#   ifdef __sun
#       define floorf(x) floor(x)
#       define ceilf(x) ceil(x)
#       define roundf(x) round(x)
#       define round(x) floor(x + 0.5)
#   endif

#endif  // GNUSTEP
