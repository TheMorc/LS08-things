GIANTS Blender i3d exporter
===========================

Installation Windows
--------------------
1. Install Python Runtime 2.6 (http://www.python.org/ftp/python/2.6/python-2.6.msi)

2. Setup the environment variable PYTHONPATH to the python installation path. Also 
   add DLLs and LIB directory.
   Example: PYTHONPATH = C:\Python26;C:\Python26\DLLs;C:\Python26\Lib

3. Copy blenderI3DExport.py to Blenders scripts directory.
   (eg. C:\Documents and Settings\<USERNAME>\Application Data\Blender Foundation\Blender\.blender\scripts)
  
Installation Linux
------------------
You'll find a hidden directory called ".blender" in your home directory. Inside there's a sub-directory
called "scripts", place the file blenderI3DExport.py there. Restart Blender.

Change log
----------

4.1.2 (01.03.2009)
------------------
 - Fixed multi material export

4.1.1 (22.12.2008)
------------------
 - Fixed UV export

4.1.0 (14.11.2008)
------------------
 - Initial release
