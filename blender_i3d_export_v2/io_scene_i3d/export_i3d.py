# ##### BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####

# Copyright (c) 2008-2012 GIANTS Software GmbH
# Contributors: Michel Dorge, Hans-Peter Imboden, Simon Broggi

import struct

def save(operator, context, filepath="",
			use_verbose=True,
			use_physics=True,
			use_modifiers=True):
	import bpy
	import time
	import math
	import mathutils
	import os
	from xml.dom.minidom import Document
	from bpy_extras.io_utils import create_derived_objects, free_derived_objects

	save.id = 0
	save.shape_ids = {}
	save.material_ids = {}
	save.file_ids = {}
	save.shape_uvs = None
	save.subset = None
	save.vertices = None
	save.triangles = None
	save.triSet = None
	save.materials = None
	save.shapes = None
	save.dynamics = None
	save.scene = None
	save.animation = None
	save.ua = None
	save.node_id = 0
	save.uvs = []
	
	materialName = "mat"
	
	save.doc = Document()
	
	save.i3D = save.doc.createElement("i3D")
	save.doc.appendChild(save.i3D)
	save.i3D.setAttribute("name", os.path.basename(bpy.data.filepath))
	save.i3D.setAttribute("version", "1.5")
	save.i3D.setAttribute("xsi:noNamespaceSchemaLocation", "http://i3d.giants.ch/schema/i3d-1.5.xsd")
	save.i3D.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
	
	save.asset = save.doc.createElement("Asset")
	save.i3D.appendChild(save.asset)
	
	export = save.doc.createElement("Export")
	export.setAttribute("version", "2")
	export.setAttribute("program", "Blender GE Exporter by Morc")
	save.asset.appendChild(export)	
	
	save.files = save.doc.createElement("Files")
	save.i3D.appendChild(save.files)
	
	save.materials = save.doc.createElement("Materials")
	save.i3D.appendChild(save.materials)
	
	save.shapes = save.doc.createElement("Shapes")
	save.i3D.appendChild(save.shapes)
	
	save.dynamics = save.doc.createElement("Dynamics")
	save.i3D.appendChild(save.dynamics)
	
	save.scene = save.doc.createElement("Scene")
	save.i3D.appendChild(save.scene)
	
	save.animation = save.doc.createElement("Animation")
	save.i3D.appendChild(save.animation)
	
	save.ua = save.doc.createElement("UserAttributes")
	save.i3D.appendChild(save.ua)
	
	def newTriangleSet(name,me):
		if name not in save.shape_ids:
			save.id = save.id + 1
			save.triSet = save.doc.createElement("IndexedFaceSet")
			save.shapes.appendChild(save.triSet)
			save.triSet.setAttribute("name", name)
			#save.triSet.setAttribute("shapeId","%d" % (save.id))
			save.shape_ids[name] = save.id
			
			save.vertices = save.doc.createElement("Vertices")
			save.vertices.setAttribute("normal", "true")
			for uv_tex in me.uv_textures:
				if uv_tex.active == True:
					save.vertices.setAttribute("uv0", "true")
			save.vertices.setAttribute("normal", "true")
			save.triSet.appendChild(save.vertices)
			save.triangles = save.doc.createElement("Faces")
			save.triSet.appendChild(save.triangles)
			#save.subs = save.doc.createElement("Subsets")
			#save.triSet.appendChild(save.subs)
			return True
		return False
		
	def addSubset(start):
		print("d")
		#save.subset = save.doc.createElement("Subset")
		#save.subset.setAttribute("firstVertex","%d" % start)
		#save.subset.setAttribute("firstIndex","%d" % start)
		
	def writeSubset(size):
		# We only attach the subset if there's anything in it
		if size > 0:
			save.subset.setAttribute("numVertices","%d" % size)
			save.subset.setAttribute("numIndices","%d" % size)
			#save.subs.appendChild(save.subset)
	
	def activeUV(mesh):
		for uv_tex in mesh.uv_textures:
			if uv_tex.active == True:
				return uv_tex
		return None
	
	def writeVertex(me, vIndex, face):
		v = me.vertices[ face.vertices[vIndex] ]
		vert = save.doc.createElement("v")
		vert.setAttribute("c", '%.6f %.6f %.6f' % (v.co.x,v.co.z,-v.co.y))
		#if face.use_smooth:
			#vert.setAttribute("c", '%.6f %.6f %.6f' % (v.normal.x, v.normal.z, -v.normal.y))
		#else:
		#	vert.setAttribute("c", '%.6f %.6f %.6f' % (face.normal.x, face.normal.z, -face.normal.y))
		save.vertices.appendChild(vert)
		return len(save.vertices.childNodes)-1
	
	def fakewriteVertex(me, vIndex, face):
		return len(save.vertices.childNodes)-1
	
	def writeFace(me, matInd, f):
		if matInd != f.material_index:
			return 0,0
		#Export face vertices
		indices = ""
		indices = "%s %d" % (indices , writeVertex(me, 0, f))
		indices = "%s %d" % (indices , writeVertex(me, 1, f))
		indices = "%s %d" % (indices , writeVertex(me, 2, f))
		tri = save.doc.createElement("f")
		faceVerts = f.vertices[:]
		tri.setAttribute("vi", indices.strip() )
		#Get active UV set
		uv_tex = activeUV(me)
		if uv_tex != None and len(uv_tex.data) > 0:
			uvs = ( uv_tex.data[f.index].uv[0][0], uv_tex.data[f.index].uv[0][1], uv_tex.data[f.index].uv[1][0], uv_tex.data[f.index].uv[1][1], uv_tex.data[f.index].uv[2][0], uv_tex.data[f.index].uv[2][1]) 
			tri.setAttribute("t0", '%.6f %.6f %.6f %.6f %.6f %.6f' % uvs)
		v1 = me.vertices[ f.vertices[0] ]
		v2 = me.vertices[ f.vertices[1] ]
		v3 = me.vertices[ f.vertices[2] ]
		tri.setAttribute("ci", "%d" % matInd)
		if f.use_smooth:
			tri.setAttribute("n", '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f' % (v1.normal.x,v1.normal.z,-v1.normal.y,v2.normal.x,v2.normal.z,-v2.normal.y,v3.normal.x,v3.normal.z,-v3.normal.y))
		else:
			tri.setAttribute("n", '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f' % (f.normal.x,f.normal.z,-f.normal.y,f.normal.x,f.normal.z,-f.normal.y,f.normal.x,f.normal.z,-f.normal.y))
		save.triangles.appendChild(tri)
		if len(f.vertices) == 4:
			#Export 2nd triangle for quads
			indices = ""
			indices = "%s %d" % (indices , writeVertex(me, 0, f))
			indices = "%s %d" % (indices , writeVertex(me, 2, f))
			indices = "%s %d" % (indices , writeVertex(me, 3, f))
			tri = save.doc.createElement("f")
			faceVerts = f.vertices[:]
			tri.setAttribute("vi", indices.strip() )
			v1 = me.vertices[ f.vertices[0] ]
			v2 = me.vertices[ f.vertices[1] ]
			v3 = me.vertices[ f.vertices[2] ]
			tri.setAttribute("ci", "%d" % matInd)
			if f.use_smooth:
				tri.setAttribute("n", '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f' % (v1.normal.x,v1.normal.z,-v1.normal.y,v2.normal.x,v2.normal.z,-v2.normal.y,v3.normal.x,v3.normal.z,-v3.normal.y))
			else:
				tri.setAttribute("n", '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f' % (f.normal.x,f.normal.z,-f.normal.y,f.normal.x,f.normal.z,-f.normal.y,f.normal.x,f.normal.z,-f.normal.y))
			save.triangles.appendChild(tri)
			return (6,2) # 6 Vertices in a quad
		return (3,1) # 3 Vertices in triangle
		
	
	def writeTexture(tex):
		if tex != None and tex.type == 'IMAGE' and (tex.image.filepath not in save.file_ids):
			save.id = save.id + 1
			file = save.doc.createElement("File")
			file.setAttribute("name", "%d" % (save.id))
			save.file_ids[tex.image.filepath] = save.id;
			#Why does the relative path even matter?
			file.setAttribute("filename", os.path.basename(tex.image.filepath))
			file.setAttribute("relativePath", "true")
			save.files.appendChild(file)
			return save.id
		return None
	
	def writeMaterial(mat):
		if mat.name not in save.material_ids:
			save.id = save.id + 1
			save.material_ids[mat.name] = save.id
			print("\tMaterial: %s Exported" % (mat.name))
			material = save.doc.createElement("Material")
			material.setAttribute("name", mat.name)
			#material.setAttribute("name","%d" % (save.id))
			tex_id = writeTexture(mat.active_texture)
			if tex_id != None:
				texture = save.doc.createElement("Texture")
				texture.setAttribute("name","%d" % (tex_id))
				material.appendChild(texture)
			material.setAttribute("diffuseColor","%.6f %.6f %.6f %.6f" % (mat.diffuse_color[0], mat.diffuse_color[1], mat.diffuse_color[2], mat.alpha))
			material.setAttribute("cosPower","%d" % (50))
			save.materials.appendChild(material)
		return save.material_ids[mat.name]
	
	
	# Export a mesh to shape
	def writeMesh(me,name):
		mats = me.materials
		matNames = ""
		lastMat = ""
		if newTriangleSet(name,me) == True:
			print("\tExporting Mesh: %s" % name)
			faces = me.faces[:]
			
			totalVertices = 0
			totalFaces = 0
			for matId in range(0,len(mats)):
				#addSubset(totalVertices)
				subVerts = 0
				subFaces = 0
				material = me.materials[matId] 
				print(material.name)
				if matId == 0:
					matNames = material.name
				else:
					matNames = matNames + ", " + material.name
					
				save.triangles.setAttribute("shaderlist", "%s" % matNames)
				for f in faces:
					vc, fc = writeFace(me, matId, f)
					subVerts += vc
					subFaces += fc
				lastMat = material.name
				#totalVertices += subVerts
				#totalFaces += subFaces
				# Save the subset for this material
				#writeSubset(subVerts)
			
			#save.vertices.setAttribute("count", "%d" % totalVertices)
			#save.triangles.setAttribute("count", "%d" % totalFaces)
			#save.subs.setAttribute("count","%d" % len(save.subs.childNodes))
		
		matids = ""
		for m in mats:
			mat_id = writeMaterial(m)
			if len(matids) > 0:
				matids = "%s, %d" % (matids, mat_id)
			else:
				matids = "%d" % (mat_id)
		
		return (save.shape_ids[name],matids)
	
	def saveObject(obj, parent):
		if obj.select != True:
			return
		
		matrix = obj.matrix_local.copy()
		
		element = None
		if obj.type == 'MESH':
			# Export the mesh
			element = save.doc.createElement("Shape")
			
			mesh = obj.data
			if use_modifiers == True:
				mesh = obj.to_mesh(obj.users_scene[0], True, 'PREVIEW')
			
			shape_id,mats = writeMesh(mesh,obj.data.name)
			element.setAttribute("ref", "%s" % obj.data.name)
			#element.setAttribute("materialIds", "%s" % mats)
			
			# If the mesh was created using create_mesh, we must destroy it
			if use_modifiers == True:
				bpy.data.meshes.remove(mesh)
			
			# Physics settings
			if use_physics == True:
				if obj.game.physics_type == 'STATIC':
					element.setAttribute("static", "true")
				elif obj.game.physics_type == 'RIGID_BODY':
					element.setAttribute("dynamic", "true")
					element.setAttribute("mass", "%.6f" % obj.game.mass)
				elif obj.game.physics_type == 'SENSOR':
					element.setAttribute("kinematic", "true")
		elif obj.type == 'EMPTY':
			element = save.doc.createElement("TransformGroup")
		elif obj.type == 'LAMP':
			element = save.doc.createElement("Light")
			
			element.setAttribute("type",obj.data.type.lower())
			if obj.data.use_diffuse:
				element.setAttribute("diffuseColor", "%.6f %.6f %.6f" % tuple(obj.data.color))
			if obj.data.use_specular:
				element.setAttribute("specularColor", "%.6f %.6f %.6f" % tuple(obj.data.color))
			element.setAttribute("range", "%.6f" % obj.data.distance)
		elif obj.type == 'CAMERA':
			#Rotate the matrix
			matrix = matrix*mathutils.Matrix.Rotation(math.radians(-90), 4, 'X')
			element = save.doc.createElement("Camera")
			cam = obj.data
			element.setAttribute("fov", "%.6f" % math.degrees(cam.angle))
			element.setAttribute("nearClip", "%.6f" % cam.clip_start)
			element.setAttribute("farClip", "%.6f" % cam.clip_end)
		else:
			print("Unable to export object of type %s" % obj.type)
			return
		
		print("Exporting Object %s [%s]" % (obj.name, obj.type))
		
		save.node_id = save.node_id + 1
		#element.setAttribute("nodeId", "%d" % save.node_id)
		element.setAttribute("name", obj.name)
		
		translation = matrix.to_translation()
		element.setAttribute("translation", "%.6f %.6f %.6f" % (translation.x, translation.z, -translation.y ) )
		# Y U NO USE RADIANS?!
		rotation = matrix.to_3x3().to_euler('YXZ')
		element.setAttribute("rotation", "%.6f %.6f %.6f" % (math.degrees(rotation.x), math.degrees(rotation.z), -math.degrees(rotation.y)))
		
		parent.appendChild(element)
		
		#Save Objects children
		for child in obj.children:
			saveObject(child,element)
	
	print("=== Begining i3D export ====================")
	time1 = time.clock()
	for obj in bpy.data.objects:
		if obj.parent == None:
			saveObject(obj, save.scene)
		

	f = open(filepath, 'w')
	save.doc.writexml(f,"","    ","\n")
	f.close()
	print("== Export Complete! Time Taken %.3f ms ====" % (time.clock() - time1))
	
	return {'FINISHED'}