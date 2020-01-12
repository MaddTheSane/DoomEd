/*
    RDECocoaGlue_NXDefaults.m

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

#import "RDECocoaGlue_NXDefaults.h"


int NXRegisterDefaults(const char *owner, NXDefaultsVector vector)
{
    NSMutableDictionary *defaultsDict;
    NXDefaultsRecord *defaultsEntry;
    NSString *key, *object;

    if (!vector)
        goto ERROR;

    defaultsDict = [NSMutableDictionary dictionary];

    defaultsEntry = (NXDefaultsRecord *) vector;

    while (defaultsEntry->name)
    {
        key = RDE_NSStringFromCString(defaultsEntry->name);
        object = RDE_NSStringFromCString(defaultsEntry->value);

        [defaultsDict setObject: object forKey: key];

        defaultsEntry++;
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultsDict];

    return 0;

ERROR:
    return -1;
}

const char *NXGetDefaultValue(const char *owner, const char *name)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return RDE_CStringFromNSString([defaults stringForKey: RDE_NSStringFromCString(name)]);
}

int NXWriteDefault(const char *owner, const char *name, const char *value)
{
    NSString *key, *object = nil;

    key = RDE_NSStringFromCString(name);

    if (value)
    {
        object = RDE_NSStringFromCString(value);
    }

    [[NSUserDefaults standardUserDefaults] setObject: object forKey: key];

    return 0;
}

