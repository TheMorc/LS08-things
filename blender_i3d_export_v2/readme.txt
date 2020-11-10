GIANTS Blender i3d exporter v2 for GIANTS Editor 0.2.5/0.3.0 - 4.0.0
===========================

Installation
------------

1. Install Blender 2.62 32 or 64bit (https://download.blender.org/release/Blender2.62/).

2. Extract the io_scene_i3d folder from the zip archive and place it in your Blender addons folder.
   Example addons folder path: C:\Program Files\Blender Foundation\Blender\2.62\scripts\addons

3. Launch Blender and go to "File -> User Preferences...".

4. Click on "Install Addon..." in the "Addons" section.

5. Browse to the io_scene_i3d folder previously extracted.
   Example path: C:\Program Files\Blender Foundation\Blender\2.62\scripts\addons\io_scene_i3d
 
6. Select the file __init__.py and click "Install Addon...".

7. Select and enable the "Import-Export: i3D format" addon in the right list.
   Hint: Apply the "Community" and "Import-Export" filters on the left for less items to browse.

8. Click on the "Save as Default" button to automatically load the addon each time you launch Blender.

9. Now, you can export with "File -> Export" to "GIANTS v0.2.5 - 4.0.0 (.i3d)".

Change log
----------

0.2.5-4.0.0 v2 (23.10.2020)
----------------------
 - Exporter modified to properly export i3d 1.5 format files

5.0.1 (10.09.2012)
------------------
 - Minor fixes

4.2.0 (01.03.2012)
------------------
 - Added support for Blender 2.6.2

4.1.5 (30.12.2009)
------------------
 - Added armature animation export (only active action)

4.1.2 (01.03.2009)
------------------
 - Fixed multi material export
