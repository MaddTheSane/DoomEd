/*
    RDEGNUstepGlue_NSMatrix.m

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for GNUstep. ReDoomEd is a Doom game map editor,
    ported from id Software's DoomEd for NeXTSTEP.

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

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


@implementation NSObject (RDEGNUstepGlue_NSMatrix)

+ (void) rdeGSGlue_NSMatrix_InstallPatches
{
    macroSwizzleInstanceMethod(NSMatrix, sendAction, rdeGSPatch_SendAction);

    macroSwizzleInstanceMethod(NSMatrix, selectedRow, rdeGSPatch_SelectedRow);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_NSMatrix_InstallPatches);
}

@end

@implementation NSMatrix (RDEGNUStepGlue_NSMatrix)

// PATCH: -[NSMatrix sendAction]
// Workaround for GNUstep bug in NSMatrix that leaves multiple cells selected when
// a cell's key equivalent is pressed

- (BOOL) rdeGSPatch_SendAction
{
    [self performSelector: @selector(selectCell:)
            withObject: [self selectedCell]
            afterDelay: 0.0];

    return [self rdeGSPatch_SendAction];
}

// PATCH: -[NSMatrix selectedRow]
// Workaround for GNUstep bug in -[NSMatrix selectedRow] which returns the wrong
// row if that method is called from within the matrix's action method after
// pressing a cell's key equivalent

- (NSInteger) rdeGSPatch_SelectedRow
{
    NSInteger row;

    [self getRow: &row column: NULL ofCell: [self selectedCell]];

    return row;
}

@end

#endif  // GNUSTEP

