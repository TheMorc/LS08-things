

# <pep8-80 compliant>

bl_info = {
    "name": "i3D format",
    "author": "Community",
    "blender": (2, 6, 2),
    "location": "File > Import-Export",
    "description": "i3D Exporter (v0.2.5 - 4.0.0)",
    "warning": "",
    "wiki_url": "http://176.101.178.133:370/",
    "tracker_url": "",
    "support": 'COMMUNITY',
    "category": "Import-Export"}


if "bpy" in locals():
    import imp
    if "export_i3d" in locals():
        imp.reload(export_i3d)


import bpy
from bpy.props import (StringProperty,
                       BoolProperty,
                       FloatProperty,
                       EnumProperty,
                       )

from bpy_extras.io_utils import (ExportHelper,
                                 path_reference_mode,
                                 axis_conversion,
                                 )


class ExportI3D(bpy.types.Operator, ExportHelper):
    '''Selection to an ASCII Autodesk FBW'''
    bl_idname = "export_scene.i3d"
    bl_label = "Export I3D"
    bl_options = {'PRESET'}

    filename_ext = ".i3d"
    
    use_physics = BoolProperty(name="Export Physics", description="Export physics information", default=True)
    use_modifiers = BoolProperty(name="Apply Modifiers", description="Apply mesh modifiers to exported shapes", default=True)
    

    def execute(self, context):	
        from . import export_i3d
        return export_i3d.save(self, context, **self.properties)


def menu_func(self, context):
    self.layout.operator(ExportI3D.bl_idname, text="GIANTS v0.2.5 - 4.0.0 (.i3d)")


def register():
    bpy.utils.register_module(__name__)

    bpy.types.INFO_MT_file_export.append(menu_func)


def unregister():
    bpy.utils.unregister_module(__name__)

    bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == "__main__":
    register()
