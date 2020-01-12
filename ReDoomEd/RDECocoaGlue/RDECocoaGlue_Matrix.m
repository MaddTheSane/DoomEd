/*
    RDECocoaGlue_Matrix.m

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

#import "RDECocoaGlue_Matrix.h"


@implementation NSMatrix (RDECocoaGlue_MatrixMethods)

- (id) getNumRows: (int *) rowCount numCols: (int *) colCount
{
    NSInteger rowCountNSInt, colCountNSInt;

    [self getNumberOfRows: &rowCountNSInt columns: &colCountNSInt];

    if (rowCount)
    {
        *rowCount = (int) rowCountNSInt;
    }

    if (colCount)
    {
        *colCount = (int) colCountNSInt;
    }

    return self;
}

- (NSCell *) cellAt: (int) row : (int) col
{
    return [self cellAtRow: row column: col];
}

- (id) selectCellAt: (int) row : (int) col
{
    [self selectCellAtRow: row column: col];

    return self;
}

- (int) selectedCol
{
    return [self selectedColumn];
}

- (id) findCellWithTag: (int) anInt
{
    return [self cellWithTag: anInt];
}

- (id) removeRowAt: (int) row andFree: (BOOL) flag
{
    [self removeRow: row];

    return self;
}

- (id) scrollCellToVisible: (int) row : (int) col
{
    [self scrollCellToVisibleAtRow: row column: col];

    return self;
}

- (id) insertRowAt: (int) row
{
    [self insertRow: row];

    return self;
}

@end

