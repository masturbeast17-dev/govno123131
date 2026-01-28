cd addons
rm -r amxmodx
cd ..
wget http://sourcemod.otstrel.ru/amxmodx-1.8.2-base-linux.tar.gz
tar xf amxmodx-1.8.2-base-linux.tar.gz
tar xf amxmodx-1.8.2-base-linux.tar.gz
rm amxmodx-1.8.2-base-linux.tar.gz
wget http://sourcemod.otstrel.ru/amxmodx-1.8.2-cstrike-windows.zip
tar xf amxmodx-1.8.2-cstrike-windows.zip
rm amxmodx-1.8.2-cstrike-windows.zip
wget http://sourcemod.otstrel.ru/amxmodx-1.8.2-cstrike-linux.tar.gz
tar xf amxmodx-1.8.2-cstrike-linux.tar.gz
rm amxmodx-1.8.2-cstrike-linux.tar.gz
cd addons/amxmodx/dlls
mv amxmodx_mm_i386.so amxmodx.so
cd ..
rm -r scripting
