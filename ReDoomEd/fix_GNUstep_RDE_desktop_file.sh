# Script to modify ReDoomEd.desktop for better integration with Freedesktop environments

# 1) Add "StartupWMClass=" line
grep -q "StartupWMClass=" ReDoomEd.app/Resources/ReDoomEd.desktop \
|| echo "StartupWMClass=ReDoomEd" >> ReDoomEd.app/Resources/ReDoomEd.desktop

# 2) Add "Keywords=" line
grep -q "Keywords=" ReDoomEd.app/Resources/ReDoomEd.desktop \
|| echo "Keywords=Doom;Game;Map;Level;Editor;Shooter;FPS;Build;Sector;Wall;Texture;Thing;Wad;Dpr;Dwd;" >> ReDoomEd.app/Resources/ReDoomEd.desktop

