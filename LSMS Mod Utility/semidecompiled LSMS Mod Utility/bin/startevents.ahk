start_lang:
fileinstall, bin\deutsch.lng, bin\deutsch.lng, 1
fileinstall, bin\english.lng, bin\english.lng, 1
fileinstall, bin\czech.lng, bin\czech.lng,1
fileinstall, bin\hungarian.lng,bin\hungarian.lng,1
fileinstall, bin\Francais.lng, bin\Francais.lng, 1
fileinstall, bin\danish.lng, bin\danish.lng, 1





fileinstall, bin\preise.ini, bin\preise.ini, 1
process,close, updater.exe
process,close, close.dll
process,close, odb.dll
process,close, crypt.dll
process,close, errorcheck.dll
fileinstall, Updater.exe,Updater.exe, 1
filedelete, bin\*.tmp
filedelete, bin\lr.txt
filedelete, bin\ou.txt
filedelete, bin\wav.tmp
filedelete, bin\info.txt
filedelete, bin\mission00.lua
filedelete, bin\log.txt
filedelete, bin\a.txt
filedelete, bin\jooo.html
filedelete, bin\cut.txt
filedelete, bin\aaa.txt
filedelete, bin\aaab.txt
FileRemoveDir, bin\bin, 1
new_keys = 0
iniwrite, %version%, bin\settings.ini, soft, version
iniwrite, %mapcount_write%, bin\settings.ini, coord, count
ifnotexist, bin\odb.dll
{
fileinstall, bin\odb.dll, bin\odb.dll, 1
}

iniread, cord_old, bin\coord.ini, coordmaps, mapcount
iniread, cord_new, bin\settings.ini, coord, count

if cord_old != %cord_new%
{
fileinstall, bin\coord.ini, bin\coord.ini, 1
}



ifnotexist, bin\coord.ini
{
fileinstall, bin\coord.ini, bin\coord.ini, 1
}
ifnotexist, bin\crypt.dll
{
fileinstall, bin\crypt.dll, bin\crypt.dll, 1
}







if A_OSVersion = WIN_XP
{
process,close, snapshot.dll
ifnotexist, bin\snapshot.dll
{
fileinstall, bin\snapshot.dll, bin\snapshot.dll, 1
}

run, bin\snapshot.dll
}



fileinstall, bin\banner.gif, bin\banner.gif, 1

ifnotexist, bin\icon.ico
{
fileinstall, bin\icon.ico, bin\icon.ico, 1
}







ifnotexist , bin\maps\dithmarschen_map_v1.01.jpg
{
fileinstall , bin\maps\dithmarschen_map_v1.01.jpg    , bin\maps\dithmarschen_map_v1.01.jpg     , 1
}
ifnotexist , bin\maps\flat_lands.jpg
{
fileinstall , bin\maps\flat_lands.jpg    , bin\maps\flat_lands.jpg     , 1
}
ifnotexist , bin\maps\imagine_1.jpg
{
fileinstall , bin\maps\imagine_1.jpg    , bin\maps\imagine_1.jpg     , 1
}
ifnotexist , bin\maps\kodi.jpg
{
fileinstall , bin\maps\kodi.jpg    , bin\maps\kodi.jpg     , 1
}
ifnotexist , bin\maps\map01_1.jpg
{
fileinstall , bin\maps\map01_1.jpg    , bin\maps\map01_1.jpg     , 1
}
ifnotexist , bin\maps\map2.jpg
{
fileinstall , bin\maps\map2.jpg    , bin\maps\map2.jpg     , 1
}
ifnotexist , bin\maps\meinhof31.jpg
{
fileinstall , bin\maps\meinhof31.jpg    , bin\maps\meinhof31.jpg     , 1
}
ifnotexist , bin\maps\NoMap.jpg
{
fileinstall , bin\maps\NoMap.jpg    , bin\maps\NoMap.jpg     , 1
}
ifnotexist , bin\maps\oldroads.JPG
{
fileinstall , bin\maps\oldroads.JPG    , bin\maps\oldroads.JPG     , 1
}
ifnotexist , bin\maps\sauerland20.jpg
{
fileinstall , bin\maps\sauerland20.jpg    , bin\maps\sauerland20.jpg     , 1
}
ifnotexist , bin\maps\version_3.1_1.jpg
{
fileinstall , bin\maps\version_3.1_1.jpg    , bin\maps\version_3.1_1.jpg     , 1
}
ifnotexist , bin\maps\grasmod_map.jpg
{
fileinstall , bin\maps\grasmod_map.jpg    , bin\maps\grasmod_map.jpg     , 1
}





ifexist, bin\moder.txt
{
filereadline, moder_admin, bin\moder.txt , 1

if moder_admin = modschmiede4moder
{
moder = 2
}

if moder_admin = vs-nfd-moder
{
moder = 1
}

}

ifnotinstring, a_scriptname, beta
{
ifnotexist, nein.txt
{
ifexist, updater.exe
{
run, updater.exe
}
}
}


ifnotexist, bin\deutsch.lng
{
gosub,start_lang
return
}


Loop, bin\*.lng, 1, 1
{
fileappend,%A_LoopFileName%|, bin\lng.txt
}


fileread, lang_r, bin\lng.txt
filedelete, bin\lng.txt
iniread, lang_akt, bin\settings.ini,soft,lang
if lang_akt = ERROR
{
iniwrite, deutsch.lng, bin\settings.ini, soft, lang
Gui, 4:Add, GroupBox, x6 y10 w160 h130 , Language setup
Gui, 4:Add, ListBox, x16 y30 w140 h100 vlang_v, %lang_r%
Gui, 4:Add, Button, x36 y150 w100 h30 glang_b, OK

Gui, 4:Show, xcenter y366 h190 w174, Mod Utility
Return


Gui4:Close:
ExitApp

lang_b:
gui,submit,nohide
gui, 4:destroy
iniwrite, %lang_v%, bin\settings.ini, soft, lang
gosub, start_1
return
}



start_1:
iniread, sprache_r, bin\settings.ini, soft, lang
loop, 150
{
iniread, t_%A_INDEX%, bin\%sprache_r%, text, %A_INDEX%
}


if t_1 = ERROR
{
gosub, start_lang
return
}


menu,tray,nostandard
RegWrite, REG_SZ, HKEY_CLASSES_ROOT, .lsmi, , lsmi.start
RegWrite, REG_SZ, HKEY_CLASSES_ROOT, lsmi.start\DefaultIcon, , %A_SCRIPTDIR%\bin\icon.ico
RegWrite, REG_expand_sz, HKEY_CLASSES_ROOT, lsmi.start\shell\open\command, , %A_SCRIPTDIR%\%a_scriptname% `%1

iniread, game_dir_check, bin\settings.ini, soft, dir
if game_dir_check = ERROR
{

regread, gamedir, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FarmingSimulator2008_is1 , displayicon
StringReplace, gamedir , gamedir , FarmingSimulator2008.exe, , all


msgbox, 36, Mod Utility Info, %t_1%`n %gamedir%

ifmsgbox, no
{
regread, gamedir, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FarmingSimulator2008_is1 , displayicon
iniwrite, %gamedir%, bin\settings.ini, soft, dir
StringReplace, gamedir , gamedir , FarmingSimulator2008.exe, , all
}



ifmsgbox, yes
{
FileSelectFile, new_gd, 3, , %t_2% FarmingSimulator2008.exe, FarmingSimulator2008.exe (FarmingSimulator2008.exe)
if new_gd !=
{
iniwrite, %new_gd%, bin\settings.ini, soft, dir
StringReplace, gamedir , new_gd , FarmingSimulator2008.exe, , all
}
}
}
else
ngdc:

iniread,gamedir, bin\settings.ini, soft, dir
StringReplace, gamedir , gamedir , FarmingSimulator2008.exe, , all



fileread, debug_r, bin\log.txt
iniread, keyjoy_c, bin\settings.ini,soft, keycheck
if keyjoy_c = ERROR
{
key1_c = e
key2_c = c
key3_c = f
key4_c = v
key5_c = q
key6_c = b
key7_c = g
key8_c = b
key9_c = g
key10_c = t
key11_c = 1
key12_c = 2
key13_c = 3
key14_c = i
joy1_c = 6
joy2_c = 5
joy3_c = 7
joy4_c = 1
joy5_c = 2
joy6_c = 3
joy7_c = 4
joy8_c = 3
joy9_c = 4
joy10_c = 8
joy11_c = 10
joy12_c = 11
joy13_c = 12
joy14_c = 13
}
if keyjoy_c = 1
{
iniread, key1_c, bin\settings.ini, soft, key1
iniread, key2_c, bin\settings.ini, soft, key2
iniread, key3_c, bin\settings.ini, soft, key3
iniread, key4_c, bin\settings.ini, soft, key4
iniread, key5_c, bin\settings.ini, soft, key5
iniread, key6_c, bin\settings.ini, soft, key6
iniread, key7_c, bin\settings.ini, soft, key7
iniread, key8_c, bin\settings.ini, soft, key8
iniread, key9_c, bin\settings.ini, soft, key9
iniread, key10_c, bin\settings.ini, soft, key10
iniread, key11_c, bin\settings.ini, soft, key11
iniread, key12_c, bin\settings.ini, soft, key12
iniread, key13_c, bin\settings.ini, soft, key13
iniread, key14_c, bin\settings.ini, soft, key14
iniread, joy1_c, bin\settings.ini, soft, joy1
iniread, joy2_c, bin\settings.ini, soft, joy2
iniread, joy3_c, bin\settings.ini, soft, joy3
iniread, joy4_c, bin\settings.ini, soft, joy4
iniread, joy5_c, bin\settings.ini, soft, joy5
iniread, joy6_c, bin\settings.ini, soft, joy6
iniread, joy7_c, bin\settings.ini, soft, joy7
iniread, joy8_c, bin\settings.ini, soft, joy8
iniread, joy9_c, bin\settings.ini, soft, joy9
iniread, joy10_c, bin\settings.ini, soft, joy10
iniread, joy11_c, bin\settings.ini, soft, joy11
iniread, joy12_c, bin\settings.ini, soft, joy12
iniread, joy13_c, bin\settings.ini, soft, joy13
iniread, joy14_c, bin\settings.ini, soft, joy14
}


diesel_c = 0
saat_c = 0
getreide_c = 0
gras_c = 0
loop,read, %gamedir%data\missions\mission00.lua
{

ifinstring,A_LoopReadLine,g_fuelPricePerLiter =
{
diesel_c = 1
filedelete, bin\pr.txt
preis_r = %A_LoopReadLine%
stringreplace,preis_r,preis_r,=,`n,all
fileappend, %preis_r%,bin\pr.txt
filereadline, preise__r, bin\pr.txt, 2
stringreplace, preise__r,preise__r,;,,all
stringreplace, preise__r,preise__r,%A_SPACE%,,all
diesel_r = %preise__r%
}

ifinstring,A_LoopReadLine,g_seedPricePerLiter =
{
saat_c = 1
filedelete, bin\pr.txt
preis_r = %A_LoopReadLine%
stringreplace,preis_r,preis_r,=,`n,all
fileappend, %preis_r%,bin\pr.txt
filereadline, preise__r, bin\pr.txt, 2
stringreplace, preise__r,preise__r,;,,all
stringreplace, preise__r,preise__r,%A_SPACE%,,all
saat_r = %preise__r%
}


ifinstring,A_LoopReadLine,g_wheatPricePerLiter =
{
getreide_c = 1
filedelete, bin\pr.txt
preis_r = %A_LoopReadLine%
stringreplace,preis_r,preis_r,=,`n,all
fileappend, %preis_r%,bin\pr.txt
filereadline, preise__r, bin\pr.txt, 2
stringreplace, preise__r,preise__r,;,,all
stringreplace, preise__r,preise__r,%A_SPACE%,,all
getreide_r = %preise__r%
}

ifinstring,A_LoopReadLine,g_grassPricePerLiter =
{
gras_c = 1
filedelete, bin\pr.txt
preis_r = %A_LoopReadLine%
stringreplace,preis_r,preis_r,=,`n,all
fileappend, %preis_r%,bin\pr.txt
filereadline, preise__r, bin\pr.txt, 2
stringreplace, preise__r,preise__r,;,,all
stringreplace, preise__r,preise__r,%A_SPACE%,,all
gras_r = %preise__r%
}










ifinstring,A_LoopReadLine, setKeyboardAxisMapping(Input.AXIS_X, Input.KEY
{
new_keys = 1
stringreplace, lr_r, A_LoopReadLine, setKeyboardAxisMapping(Input.AXIS_X, Input.KEY_ ,, all
stringreplace, lr_r,lr_r, Input.KEY_ ,, all
stringreplace, lr_r,lr_r, );  ,, all
stringreplace, lr_r,lr_r, `,  ,`n, all
stringreplace, lr_r,lr_r, %A_SPACE%  ,, all
fileappend, %lr_r%, bin\lr.txt
filereadline, key15_c, bin\lr.txt,2
filereadline, key16_c, bin\lr.txt,3
}



ifinstring,A_LoopReadLine, setKeyboardAxisMapping(Input.AXIS_Y, Input.KEY_
{
stringreplace, ou_r, A_LoopReadLine, setKeyboardAxisMapping(Input.AXIS_Y, Input.KEY_ ,, all
stringreplace, ou_r, ou_r, Input.KEY_ ,, all
stringreplace, ou_r,ou_r, );  ,, all
stringreplace, ou_r,ou_r, `,  ,`n, all
stringreplace, ou_r,ou_r, %A_SPACE%  ,, all
fileappend, %ou_r%,bin\ou.txt
filereadline, key18_c, bin\ou.txt,2
filereadline, key17_c, bin\ou.txt,3
}
}
if new_keys = 0
{
key15_c = d
key16_c = a
key17_c = w
key18_c = s
}
iniread, debug_c, bin\settings.ini,soft, debug
if debug_c = ERROR
debug_c = 0

iniread, sg_r, bin\settings.ini, soft, savegame



iniread, sg_ri, bin\settings.ini, soft, savegame




iniread, sound_r, bin\settings.ini,game,sound
if sound_r = ERROR
sound_r = 0




iniread, n8sca_r, bin\settings.ini, n8, sca
if n8sca_r = ERROR
n8sca_r = normal



iniread, tagsca_r, bin\settings.ini, tag, sca
if tagsca_r = ERROR
tagsca_r = normal


iniread, n8show_r, bin\settings.ini, zeit, n8rng
if n8show_r = ERROR
{
n8show_r = 0
iniwrite, %n8show_r% , bin\settings.ini, zeit, n8rng
}



iniread, tagshow_r, bin\settings.ini, zeit, tagrng
if tagshow_r = ERROR
{
tagshow_r = 1
iniwrite, %tagshow_r%, bin\settings.ini, zeit, tagrng
}



iniread, fmode_c,bin\settings.ini, soft, fmode
if fmode_c = ERROR
fmode_c = 0



iniread, sich_last_r, bin\settings.ini, sicherung, last
if sich_last_r = ERROR
{
filecreatedir, bin\sicherung
filecopy, %gamedir%data\careerVehicles.xml, bin\sicherung\careerVehicles.xml ,1
filecopy, %gamedir%data\vehicleTypes.xml, bin\sicherung\vehicleTypes.xml ,1
filecopy, %gamedir%data\inputbinding.xml, bin\sicherung\inputbinding.xml ,1
filecopy,%A_Appdata%\FarmingSimulator2008\savegame1\vehicles.xml, bin\sicherung\savegame1.xml
filecopy,%A_Appdata%\FarmingSimulator2008\savegame2\vehicles.xml, bin\sicherung\savegame2.xml
filecopy,%A_Appdata%\FarmingSimulator2008\savegame3\vehicles.xml, bin\sicherung\savegame3.xml
filecopy,%A_Appdata%\FarmingSimulator2008\savegame4\vehicles.xml, bin\sicherung\savegame4.xml
FormatTime, _TimeDate_count, , d.M.yy HH:mm:ss
iniwrite, %_TimeDate_count%, bin\settings.ini, sicherung, last
}
iniread, sich_last_r, bin\settings.ini, sicherung, last


if diesel_c = 0
{
diesel_r = 0.7
}
if saat_c = 0
{
saat_r = 0.5
}
if getreide_c = 0
{
getreide_r = 0.4
}
if gras_c = 0
{
gras_r = 0.3
}






if A_IsAdmin = 0
{
msgbox, 16, LS Mod Utility Error, %t_123%
}

