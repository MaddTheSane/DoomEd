/*
    RDECocoaGlue_Menu.m

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

#import "RDECocoaGlue_Menu.h"


@implementation NSMenu (RDECocoaGlue_MenuMethods)

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
    NSInteger numItems, index;

    numItems = [self numberOfItems];

    for (index=0; index<numItems; index++)
    {
        if ([[self itemAtIndex: index] state] == NSOnState)
        {
            return index;
        }
    }

    return -1;
}

- (id) selectedCell
{
    NSInteger selectedRow = [self selectedRow];
    NSCell *selectedCell = nil;

    if (selectedRow >= 0)
    {
        selectedCell = (NSCell *) [self itemAtIndex: selectedRow];
    }

    return selectedCell;
}

- (id) selectCellAt: (int) row : (int) col
{
    NSInteger numItems, index, state;

    numItems = [self numberOfItems];

    for (index=0; index<numItems; index++)
    {
        state = (index == row) ? NSOnState : NSOffState;

        [[self itemAtIndex: index] setState: state];
    }

    return self;
}

@end

