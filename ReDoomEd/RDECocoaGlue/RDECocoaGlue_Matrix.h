/*
    RDECocoaGlue_Matrix.h

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
#import "RDECocoaGlue_Macros.h"


@interface NSMatrix (RDECocoaGlue_MatrixMethods)

- (id) getNumRows: (int *) rowCount numCols: (int *) colCount RDE_DEPRECATED_WITH_REPLACEMENT("-getNumberOfRows:columns:", macos(10.0, 10.0));

- (NSCell *) cellAt: (int) row : (int) col RDE_DEPRECATED_WITH_REPLACEMENT("-cellAtRow:column:", macos(10.0, 10.0));

- (id) selectCellAt: (int) row : (int) col RDE_DEPRECATED_WITH_REPLACEMENT("-selectCellAtRow:column:", macos(10.0, 10.0));

- (int) selectedCol RDE_DEPRECATED_WITH_REPLACEMENT("-selectedColumn", macos(10.0, 10.0));

- (id) findCellWithTag: (int) anInt RDE_DEPRECATED_WITH_REPLACEMENT("-cellWithTag:", macos(10.0, 10.0));

- (id) removeRowAt: (int) row andFree: (BOOL) flag RDE_DEPRECATED_WITH_REPLACEMENT("-removeRow:", macos(10.0, 10.0)); 

- (id) scrollCellToVisible: (int) row : (int) col RDE_DEPRECATED_WITH_REPLACEMENT("-scrollCellToVisibleAtRow:column:", macos(10.0, 10.0));

- (id) insertRowAt: (int) row RDE_DEPRECATED_WITH_REPLACEMENT("-insertRow:", macos(10.0, 10.0));

@end
