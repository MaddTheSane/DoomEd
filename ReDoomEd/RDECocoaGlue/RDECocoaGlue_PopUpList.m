/*
    RDECocoaGlue_PopUpList.m

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

#import "RDECocoaGlue_PopUpList.h"


#define kDefaultFrame   NSMakeRect(0,0,70,20)


@implementation PopUpList

- (id) init
{
    NSPopUpButtonCell *popUpButtonCell;
    self = [self initWithFrame: kDefaultFrame];

    if (!self)
        goto ERROR;

#ifdef __APPLE__
    // OS X: NSPopUpButton's default size is too large to tile next to a horizontal scrollbar,
    // so manually shrink the control's size & fontsize to fit.
    popUpButtonCell = [self cell];
    [popUpButtonCell setControlSize: NSMiniControlSize];
    [popUpButtonCell setFont: [NSFont menuFontOfSize: [NSFont smallSystemFontSize]]];
#endif

    return self;

ERROR:

    return nil;
}

- (id) itemList
{
    return self;
}

- (id) getNumRows: (int *) returnedRows numCols: (int *) returnedCols
{
    *returnedRows = [self numberOfItems];
    *returnedCols = 1;

    return self;
}

- (NSInteger) selectedRow
{
    return [self indexOfSelectedItem];
}

- (id) selectedCell
{
    return [self selectedItem];
}

- (id) selectCellAt: (int) row : (int) col
{
    [self selectItemAtIndex: row];

    return self;
}

- (id) addItem: (const char *) title
{
    NSString *titleString = RDE_NSStringFromCString(title);

    [self addItemWithTitle: titleString];

    return [self itemWithTitle: titleString];
}

#ifdef __APPLE__

//  Fix for issue on OS X (10.5, other versions too?): When an NSPopUpButton receives an
// updateTrackingAreas message, it sends an updateTrackingAreaWithFrame:inView: message to the
// currently selected item from its menu, however, NSMenuItems don't recognize that selector.
//  Workaround is to temporarily set the menu to nil (removing all menu items) before calling
// [super updateTrackingAreas], then restoring the original menu afterwards.

- (void) updateTrackingAreas
{
    __strong NSMenu *popUpButtonMenu = [self menu];

    [self setMenu: nil];

    [super updateTrackingAreas];

    [self setMenu: popUpButtonMenu];
}

#endif

@end

