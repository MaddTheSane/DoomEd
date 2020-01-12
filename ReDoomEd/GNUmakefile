include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = ReDoomEd
APP_NAME = ReDoomEd

VERSION = 0.92

ReDoomEd_APPLICATION_ICON = ReDoomEd_Icon_GNUstep.png

ReDoomEd_OBJC_PRECOMPILED_HEADERS = ReDoomEd_Prefix.pch

ReDoomEd_OBJC_FILES = \
    main.m \
    RDEApplication.m \
    RDEInfoPanel.m \
    RDEMapExport.m \
     \
    RDEUtilities/NSObject_PPUtilities.m \
    RDEUtilities/NSObject_PPUtilities_MethodSwizzling.m \
    RDEUtilities/PPAppBootUtilities.m \
    RDEUtilities/PPObjCUtilities.m \
    RDEUtilities/PPSRGBUtilities.m \
     \
    RDECocoaGlue/RDECocoaGlue_Application.m \
    RDECocoaGlue/RDECocoaGlue_DisplayPostScript.m \
    RDECocoaGlue/RDECocoaGlue_Form.m \
    RDECocoaGlue/RDECocoaGlue_List.m \
    RDECocoaGlue/RDECocoaGlue_Matrix.m \
    RDECocoaGlue/RDECocoaGlue_Menu.m \
    RDECocoaGlue/RDECocoaGlue_NXAlertPanel.m \
    RDECocoaGlue/RDECocoaGlue_NXBitmapImageRep.m \
    RDECocoaGlue/RDECocoaGlue_NXColor.m \
    RDECocoaGlue/RDECocoaGlue_NXDefaults.m \
    RDECocoaGlue/RDECocoaGlue_NXGraphics.m \
    RDECocoaGlue/RDECocoaGlue_NXImage.m \
    RDECocoaGlue/RDECocoaGlue_NXStream.m \
    RDECocoaGlue/RDECocoaGlue_Object.m \
    RDECocoaGlue/RDECocoaGlue_OpenPanel.m \
    RDECocoaGlue/RDECocoaGlue_PanelUtilities.m \
    RDECocoaGlue/RDECocoaGlue_PopUpList.m \
    RDECocoaGlue/RDECocoaGlue_ScrollView.m \
    RDECocoaGlue/RDECocoaGlue_Sound.m \
    RDECocoaGlue/RDECocoaGlue_Storage.m \
    RDECocoaGlue/RDECocoaGlue_StringUtilities.m \
    RDECocoaGlue/RDECocoaGlue_Text.m \
    RDECocoaGlue/RDECocoaGlue_View.m \
    RDECocoaGlue/RDECocoaGlue_Window.m \
     \
    RDEGNUstepGlue/PPGNUstepGlue_BitmapNonpremultipliedPNG.m \
    RDEGNUstepGlue/PPGNUstepGlue_ColorPanel.m \
    RDEGNUstepGlue/PPGNUstepGlue_MenuKeyEquivalents.m \
    RDEGNUstepGlue/PPGNUstepGlue_MenuWindowHiding.m \
    RDEGNUstepGlue/PPGNUstepGlue_ModifierKeys.m \
    RDEGNUstepGlue/PPGNUstepGlue_WindowOrdering.m \
    RDEGNUstepGlue/PPGNUstepGlue_WindowStyleOffsets.m \
    RDEGNUstepGlue/PPGNUstepGlue_Workspace.m \
    RDEGNUstepGlue/PPGNUstepGlueUtilities.m \
    RDEGNUstepGlue/PPImagePixelAlphaPremultiplyTables.m \
    RDEGNUstepGlue/RDEGNUstepGlue_BitmapGraphicsContext.m \
    RDEGNUstepGlue/RDEGNUstepGlue_CustomTheme.m \
    RDEGNUstepGlue/RDEGNUstepGlue_MainMenuWindow.m \
    RDEGNUstepGlue/RDEGNUstepGlue_MapViewRedrawing.m \
    RDEGNUstepGlue/RDEGNUstepGlue_MapWindowResizing.m \
    RDEGNUstepGlue/RDEGNUstepGlue_MenuActivatedModalSessions.m \
    RDEGNUstepGlue/RDEGNUstepGlue_MouseDragging.m \
    RDEGNUstepGlue/RDEGNUstepGlue_NSBrowser.m \
    RDEGNUstepGlue/RDEGNUstepGlue_NSMatrix.m \
    RDEGNUstepGlue/RDEGNUstepGlue_OpenPanelDefaultDirectory.m \
    RDEGNUstepGlue/RDEGNUstepGlue_ThermoPanel.m \
     \
    DoomEd/BlockWorld.m \
    DoomEd/Coordinator.m \
    DoomEd/DoomProject.m \
    DoomEd/EditWorld.m \
    DoomEd/EWDoomSave.m \
    DoomEd/EWLoadSave.m \
    DoomEd/FindLine_plaintextformat.m \
    DoomEd/FlatRemapper.m \
    DoomEd/FlatsView.m \
    DoomEd/LinePanel.m \
    DoomEd/LineSpecialRemapper.m \
    DoomEd/MapView.m \
    DoomEd/MapViewDraw.m \
    DoomEd/MapViewResp.m \
    DoomEd/MapWindow.m \
    DoomEd/PopScrollView.m \
    DoomEd/PreferencePanel.m \
    DoomEd/Remapper.m \
    DoomEd/SectorEditor.m \
    DoomEd/SectorEditView.m \
    DoomEd/SettingsPanel.m \
    DoomEd/SpecialList.m \
    DoomEd/SpecialListWindow.m \
    DoomEd/TextLog.m \
    DoomEd/TextureEdit.m \
    DoomEd/TexturePalette.m \
    DoomEd/TexturePalView.m \
    DoomEd/TexturePatchView.m \
    DoomEd/TextureRemapper.m \
    DoomEd/TextureView.m \
    DoomEd/ThermoView.m \
    DoomEd/ThingPalette.m \
    DoomEd/ThingPalView.m \
    DoomEd/ThingPanel.m \
    DoomEd/ThingRemapper.m \
    DoomEd/ThingStripper.m \
    DoomEd/ThingWindow.m \
    DoomEd/ToolPanel.m \
    DoomEd/Wadfile.m \
    DoomEd/idfunctions.m \
    DoomEd/lbmfunctions.m \
    DoomEd/pathops.m \
     \
    doombsp/buildbsp.m \
    doombsp/doombsp.m \
    doombsp/doomload.m \
    doombsp/drawing.m \
    doombsp/saveblocks.m \
    doombsp/savebsp.m \
    doombsp/saveconnect.m \
    doombsp/savesectors.m

ReDoomEd_C_FILES = \
    doombsp/cmdlib.c

ReDoomEd_RESOURCE_FILES = \
    ReDoomEd.appdata.xml \
     \
    Images/ReDoomEd_Icon_GNUstep.png \
    Images/LeftArrow_Cocoa.tiff \
    Images/RightArrow_Cocoa.tiff \
    Images/UpArrow_Cocoa.tiff \
    Images/DownArrow_Cocoa.tiff \
     \
    DoomEd/DoomEd.tiff \
    DoomEd/DoomEdIcon.tiff \
    DoomEd/DoomEdMap.tiff \
    DoomEd/DoomEdWorld.tiff \
    DoomEd/OldDoomEd.tiff \
    DoomEd/SmallDemon.tiff \
    DoomEd/Find.tiff \
    DoomEd/Delete.tiff \
    DoomEd/Recycle.tiff \
    DoomEd/WarningLight1.tiff \
    DoomEd/WarningLight2.tiff \
    DoomEd/Me1.tiff \
    DoomEd/Me2.tiff \
    DoomEd/johnc.tiff \
     \
    DoomEd/DESave.snd \
    DoomEd/D_Dbite.snd \
    DoomEd/D_EPain.snd

ReDoomEd_LOCALIZED_RESOURCE_FILES = \
    DoomEd_Cocoa.nib \
    FindLine_Cocoa.nib \
    line_Cocoa.nib \
    preferences_Cocoa.nib \
    Project_Cocoa.nib \
    Remapper_Cocoa.nib \
    SectorEditor_Cocoa.nib \
    SpecialList_Cocoa.nib \
    TextLog_Cocoa.nib \
    TextureEdit_Cocoa.nib \
    TexturePalette_Cocoa.nib \
    thing_Cocoa.nib \
    ThingPalette_Cocoa.nib \
    ThingStripper_Cocoa.nib

ReDoomEd_LANGUAGES = \
    English

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

