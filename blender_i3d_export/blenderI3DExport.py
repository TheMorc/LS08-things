#!BPY

"""
Name: 'GIANTS (.i3d)...'
Blender: 248
Group: 'Export'
Tooltip: 'Export to a GIANTS i3D file'
"""

__author__ = "Simon Broggi"
__url__ = ("giants engine homepage, http://gdn.giants.ch/")
__version__ = "4.1.2"
__email__ = "simon.broggi@zhdk.ch"
__bpydoc__ = """\
Exports to Giants .i3d file.

Usage:
-Place this script in youre .blender/scripts directory.
-Open a Scripts window in blender.
-Choose Scripts -> Export -> Giants (.i3d)

if youre object turns out pink you probably forgot to asign a material.
if its black you probably forgot to uv unwrap it.
if youre computer explodes there was probably something wrong with this exporter.

not jet supported / todo:
	Material per Object (only materials per mesh supported).
	Keyframe animations.
	Nurb Curves.
"""

from Blender import Scene, Mesh, Window, sys, Mathutils, Draw, Image, BGL, Get, Material, Text, Get, ShowHelp
import BPyMessages
import bpy
import math
import os
from xml.dom.minidom import Document, parseString
true = 1
false = 0

class I3d:
	def __init__(self, name="untitled"):
		self.doc = Document()
		self.root = self.doc.createElement("i3D")
		self.root.setAttribute("name", name)
		self.root.setAttribute("version", "1.6")
		self.root.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
		self.root.setAttribute("xsi:noNamespaceSchemaLocation", "http://i3d.giants.ch/schema/i3d-1.6.xsd")		
		self.doc.appendChild(self.root)
		
		self.asset = self.doc.createElement("Asset")
		self.root.appendChild(self.asset)
		exportProgram = self.doc.createElement("Export")
		exportProgram.setAttribute("program", "Blender")
		exportProgram.setAttribute("version", "%i"%Get("version"))
		self.asset.appendChild(exportProgram)
		
		self.files = self.doc.createElement("Files")
		self.root.appendChild(self.files)
		self.materials = self.doc.createElement("Materials")
		self.defaultMat = 0
		self.root.appendChild(self.materials)
		self.lastMaterialId = 0
		self.parentArmBones = None
		self.shapes = self.doc.createElement("Shapes")
		self.root.appendChild(self.shapes)
		self.lastShapeId = 0
		self.scene = self.doc.createElement("Scene")
		self.root.appendChild(self.scene)
		self.lastNodeId = 0
		self.animation = self.doc.createElement("Animation")
		self.animationSets = self.doc.createElement("AnimationSets")
		self.animation.appendChild(self.animationSets)
		self.root.appendChild(self.animation)
		self.userAttributes = self.doc.createElement("UserAttributes")
		self.root.appendChild(self.userAttributes)
		
		#self.armaturesMap = []
	
	def setTranslation(self, node, pos):
		#node.setAttribute("translation", "%f %f %f" %(pos[0], pos[2], -pos[1]))
		node.setAttribute("translation", "%f %f %f" %(pos[0], pos[2], -pos[1]))
	#somethings not right. get mesh first to make testing visual	
	def setRotation(self, node, rot, rotX90):
		rot[0], rot[1], rot[2] = math.degrees(rot[0]), math.degrees(rot[2]), math.degrees(-rot[1])
		
		RotationMatrix= Mathutils.RotationMatrix
		MATRIX_IDENTITY_3x3 = Mathutils.Matrix([1.0,0.0,0.0],[0.0,1.0,0.0],[0.0,0.0,1.0])
		x,y,z = rot[0]%360,rot[1]%360,rot[2]%360 # Clamp all values between 0 and 360, values outside this raise an error.
		xmat = RotationMatrix(x,3,'x')
		ymat = RotationMatrix(y,3,'y')
		zmat = RotationMatrix(z,3,'z')
		eRot = (xmat*(zmat * (ymat * MATRIX_IDENTITY_3x3))).toEuler()
		
		if rotX90:
			node.setAttribute("rotation", "%f %f %f" %(eRot.x-90, eRot.y, eRot.z))
		else:
			node.setAttribute("rotation", "%f %f %f" %(eRot.x, eRot.y, eRot.z))
	
	
	def addObject(self, obj):#adds a scene node.
		#print("add object %s" %(obj.getName()))
		node = None
		parentNode = self.scene
		if not obj.getParent() is None:
			#searching parent asuming it is already in i3d (must export ordered by hyrarchie)
			for sceneNode in self.scene.getElementsByTagName("Shape"):
				if sceneNode.getAttribute("name") == obj.getParent().getName():
					parentNode = sceneNode
					break
			if parentNode == self.scene:
				for sceneNode in self.scene.getElementsByTagName("TransformGroup"):
					if sceneNode.getAttribute("name") == obj.getParent().getName():
						parentNode = sceneNode
						break
			if parentNode == self.scene:
				print("  parent not found!")
		rotX90=0
		
		if obj.type == "Mesh":
			#need armature parent data
			#parentArmBones holds the names of the bones and the i3d nodeId
			
			node = self.doc.createElement("Shape")
			shapeId, materialIds = self.addMesh(obj.getData(mesh=1), self.parentArmBones)
			node.setAttribute("shapeId", "%i" %(shapeId))
			node.setAttribute("materialIds", "%s" %(materialIds))
			
			if not self.parentArmBones is None:
				skinBindNodeIds = ""
				for pab in self.parentArmBones:
					if skinBindNodeIds == "":
						skinBindNodeIds = "%i"%(pab[1])
					else:
						skinBindNodeIds = "%s %i"%(skinBindNodeIds, pab[1])
				node.setAttribute("skinBindNodeIds", skinBindNodeIds)
				self.parentArmBones = None
			
			
			#shading propertys stored per object in giants: getting them from first blender material
			if len(obj.getData(mesh=1).materials) > 0:
				if obj.getData(mesh=1).materials[0]:
					mat = obj.getData(mesh=1).materials[0]
					if mat.getMode() & Material.Modes['SHADOWBUF']:
						node.setAttribute("castsShadows", "true")
					else:
						node.setAttribute("castsShadows", "false")
					if mat.getMode() & Material.Modes['SHADOW']:
						node.setAttribute("receiveShadows", "true")
					else:
						node.setAttribute("receiveShadows", "false")
			else:
				node.setAttribute("castsShadows", "false")
				node.setAttribute("receiveShadows", "false")
		elif obj.type == "Empty":
			node = self.doc.createElement("TransformGroup")
		elif obj.type == "Armature":
			node = self.doc.createElement("TransformGroup")
			#self.parentArmBones = self.addArmature(node, obj.getData())
			#self.parentArmBones = self.addArmature(parentNode, obj.getData(), obj)
			self.parentArmBones = self.addArmature(node, obj.getData(), obj)
			#self.armaturesMap.append({0:obj.name, 1:self.parentArmBones})
		elif obj.type == "Camera":
			rotX90=1
			node = self.doc.createElement("Camera")
			node.setAttribute("fov", "%f" %(obj.getData().lens))
			node.setAttribute("nearClip", "%f" %(obj.getData().clipStart))
			node.setAttribute("farClip", "%f" %(obj.getData().clipEnd))
		elif obj.type == "Lamp":
			rotX90=1
			node = self.doc.createElement("Light")
			lamp = obj.getData()
			lampType = ["point", "directional", "spot", "ambient"]
			if lamp.getType() > 3:
				node.setAttribute("type", lampType[0])
				print("WARNING: lamp type not supported")
			else:
				node.setAttribute("type", lampType[lamp.getType()])
			node.setAttribute("diffuseColor", "%f %f %f" %(lamp.R*lamp.energy, lamp.G*lamp.energy, lamp.B*lamp.energy))
			node.setAttribute("emitDiffuse", "true")
			node.setAttribute("specularColor", "%f %f %f" %(lamp.R*lamp.energy, lamp.G*lamp.energy, lamp.B*lamp.energy))
			node.setAttribute("emitSpecular", "true")
			node.setAttribute("decayRate", "%f"%(5000-lamp.getDist()))
			node.setAttribute("range", "500")
			if lamp.getMode() & lamp.Modes['Shadows']:
				node.setAttribute("castShadowMap", "true")
			else:
				node.setAttribute("castShadowMap", "false")
			node.setAttribute("depthMapBias", "%f"%(lamp.bias/1000))
			node.setAttribute("depthMapResolution", "%i"%lamp.bufferSize)
			node.setAttribute("coneAngle", "%f"%(lamp.getSpotSize()))
			node.setAttribute("dropOff", "%f"%(lamp.getSpotBlend()*5))#dropOff seems to be between 0 and 5 right?


		if not node is None:
			node.setAttribute("name", obj.getName())
			self.lastNodeId = self.lastNodeId + 1
			node.setAttribute("nodeId", "%i" %(self.lastNodeId))
			
			# getLocation("localspace") seems to be buggy!
			# http://blenderartists.org/forum/showthread.php?t=117421
			localMat = Mathutils.Matrix(obj.matrixLocal)
			#self.setTranslation(node, obj.getLocation("localspace"))
			self.setTranslation(node, localMat.translationPart())			
			#self.setRotation(node, localMat.rotationPart().toEuler(), rotX90)
			self.setRotation(node, obj.getEuler("localspace"), rotX90)
			parentNode.appendChild(node)
			
			#Todo....
			#Export the animations, assuming obj is an armature, hopefully it will also work with objects
			#only the active action (=clip) is exported
			"""
			action = obj.getAction()
			if not action is None:
				print("exporting animation: "+action.getName())
				animSet = self.doc.createElement("AnimationSet")
				animSet.setAttribute("name", obj.getName())#AnimationSets are equivalent to blenders NLA, only one per object
				
				clip = self.doc.createElement("Clip")
				clip.setAttribute("name", action.getName())
				print self.parentArmBones
				print action.getFrameNumbers()#the keyframes (would be nice to have them per channel)
				for channel in action.getChannelNames():
					print " "+channel
					key_NodeId = self.lastNodeId
					if not self.parentArmBones is None:
						for nameId in self.parentArmBones:
							if nameId[0] == channel:
								key_NodeId = nameId[1]
					keyframes = self.doc.createElement("Keyframes")
					keyframes.setAttribute("nodeId", "%i"%key_NodeId)
					
					ipo = action.getChannelIpo(channel)
					for curve in ipo:
						print "  "+curve.name
						for bezTri in curve.bezierPoints:
							time, value = bezTri.pt
						#ohoh, now the rotation would have to be calculated from Quats...
						
						#another aproach would be to set the time of the global timeline to the keyframe times
						#and then get the data from the object.getPose() which returns the current pose. (probably eazyer, but might result in redundant data)
						
					clip.appendChild(keyframes)
				#clip.setAttribute("duration", 
				animSet.appendChild(clip)
				#print("chanels: ")
				#print(action.getChannelNames())
				
				self.animationSets.appendChild(animSet)
			"""
				
			
			#parse ScriptLink file and merge xml into i3d
			for sl in obj.getScriptLinks("FrameChanged") + obj.getScriptLinks("Render") + obj.getScriptLinks("Redraw") + obj.getScriptLinks("ObjectUpdate") + obj.getScriptLinks("ObDataUpdate"):
				if sl.endswith(".i3d"):
					xmlText = ""
					#print Text.Get(sl).asLines()
					for l in Text.Get(sl).asLines():
						#print l.replace("i3dNodeId", "%i" %self.lastNodeId)
						xmlText = xmlText + l.replace("i3dNodeId", "%i" %self.lastNodeId)
					#print "xml: ",xmlText			
					#slDom = parseString(xmlText)
					slDom = None
					try:
						slDom = parseString(xmlText)
					except:
						print "WARNING: cant parse %s"%sl
					if not slDom is None:
						for ua in slDom.getElementsByTagName("UserAttribute"):
							self.userAttributes.appendChild(ua)
		
						for st in slDom.getElementsByTagName("SceneType"):
							i = 0
							while i < st.attributes.length:
								attr = st.attributes.item(i)
								node.setAttribute(attr.nodeName, attr.nodeValue)
								i = i+1
		else:
			print "WARNING: cant export ", obj.type, ": ",obj.getName()



	def addArmature(self, parentNode, arm, obj):
		#print("adding armature %s" %(arm.name))
		boneNameIndex = []
		for bone in arm.bones.values():
			if bone.hasParent()==0:
				def addBone(self, parent, bone):
					#print "adding bone %s to %s"%(bone.name, parent.getAttribute("name"))
					boneNode = self.doc.createElement("TransformGroup")
					boneNode.setAttribute("name", bone.name)
					self.lastNodeId = self.lastNodeId + 1
					boneNode.setAttribute("nodeId", "%i" %(self.lastNodeId))
					boneNameIndex.append({0:bone.name, 1:self.lastNodeId})
					mmm = Mathutils.Matrix(bone.matrix["ARMATURESPACE"])
					pa = bone.parent
					if not pa is None:
						mmm = mmm - Mathutils.Matrix(pa.matrix["ARMATURESPACE"])
					self.setTranslation(boneNode, mmm.translationPart())
					boneNode.setAttribute("rotation", "0 0 0")
					parent.appendChild(boneNode)
					for b in bone.children:
						addBone(self, boneNode, b)
				addBone(self, parentNode, bone)
		return boneNameIndex
	def addMesh(self, mesh, parentArmBones=None):
		#if not parentArmBones == None:
		#	print "exporting", mesh.name, "armature parented to", parentArmBones
		for its in self.shapes.getElementsByTagName("IndexedTriangleSet"):
			if its.getAttribute("name") == mesh.name:
				#print("  mesh %s is already added" %(mesh.name))
				materialIds = ""
				tangents = false
				for mat in mesh.materials:
					matIndex, t = self.addMaterial(mat)
					tangents = tangents or t
					if materialIds == "":
						materialIds = "%i" %(matIndex)
					else:
						materialIds = "%s, %i" %(materialIds, matIndex)
				if tangents:
					for verts in its.getElementsByTagName("Vertices"):
						verts.setAttribute("tangent", "true")
				return int(its.getAttribute("shapeId")), materialIds
		
		its = self.doc.createElement("IndexedTriangleSet")
		self.lastShapeId = self.lastShapeId + 1
		its.setAttribute("name", mesh.name)
		its.setAttribute("shapeId", "%i" % (self.lastShapeId))
		self.shapes.appendChild(its)
		
		verts = self.doc.createElement("Vertices")
		tris = self.doc.createElement("Triangles")
		subs = self.doc.createElement("Subsets")
		
		faceCount = 0
		vertexCount = 0
		materialCount = 0


		materialIds = ""
		tangents = false
		#print "mesh Mats: ",mesh.materials
				
		if len(mesh.materials) == 0:
			print("WARNING: mesh %s has no material -> cant export properly"%mesh.name)
		for mat in mesh.materials:
			materialCount = materialCount + 1
			matIndex, t = self.addMaterial(mat)
			tangents = tangents or t
			if materialIds == "":
				materialIds = "%i" %(matIndex)
			else:
				materialIds = "%s, %i" %(materialIds, matIndex)
			
			firstVertex = vertexCount
			firstIndex = faceCount
			for face in mesh.faces:
				
				def createI3dVert(self, vIndex):
					v = self.doc.createElement("v")
					v.setAttribute("p", "%f %f %f" % (face.v[vIndex].co.x, face.v[vIndex].co.z, -face.v[vIndex].co.y))
					if exportNormals:
						if face.smooth:
							v.setAttribute("n", "%f %f %f" % (face.v[vIndex].no.x, face.v[vIndex].no.z, -face.v[vIndex].no.y))
						else:
							v.setAttribute("n", "%f %f %f" % (face.no.x, face.no.z, -face.no.y))
					if mesh.faceUV:#todo multiple uv sets!! but how????
						v.setAttribute("t0", "%f %f" % (face.uv[vIndex].x, face.uv[vIndex].y))
					if not parentArmBones is None:
						#print "vertex has weiiiiights!"
						vGroups = getVGroup(face.v[vIndex].index, mesh)
						#print "vGroups in v ", face.v[vIndex].index, "are", vGroups
						boneWeights = ""
						boneIndices = ""
						for g in vGroups:
							#g[0] is the vertexGroup name = bone name
							#g[1] is the weight
							bi = 0
							for pab in parentArmBones:
								if g[0] == pab[0]:
									if boneWeights == "":
										boneWeights = "%f" %g[1]
										boneIndices = "%i" %bi
									else:
										boneWeights = "%s %f" %(boneWeights, g[1])
										boneIndices = "%s %i" %(boneIndices, bi)
								bi = bi + 1
						
						v.setAttribute("bw", boneWeights)
						v.setAttribute("bi", boneIndices)
						#print("yea %i %s %f" %(face.v[vIndex].index, g[0], g[1]))
						#for g in getVGroup(face.v[vIndex].index, mesh):
						#	print "vert%i of %s is in group %s with weight %f"%(face.v[vIndex].index, mesh.name, g[0], g[1])
					return v
				
				
				if face.mat == materialCount-1:
					faceCount = faceCount + 1
					if exportTriangulated and len(face.v)==4: #it's a quad and user chose to triangulate along shortest edge
						faceCount = faceCount + 1
						if (face.v[0].co - face.v[2].co).length < (face.v[1].co - face.v[3].co).length:
							verts.appendChild(createI3dVert(self, 0))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 1))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 2))
							vertexCount=vertexCount+1
							i3dt = self.doc.createElement("t")
							i3dt.setAttribute("vi", "%i %i %i" % (vertexCount - 3, vertexCount - 2, vertexCount - 1))
							tris.appendChild(i3dt)
							verts.appendChild(createI3dVert(self, 0))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 2))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 3))
							vertexCount=vertexCount+1
							i3dt = self.doc.createElement("t")
							i3dt.setAttribute("vi", "%i %i %i" % (vertexCount - 3, vertexCount - 2, vertexCount - 1))
							tris.appendChild(i3dt)
						else:
							verts.appendChild(createI3dVert(self, 0))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 1))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 3))
							vertexCount=vertexCount+1
							i3dt = self.doc.createElement("t")
							i3dt.setAttribute("vi", "%i %i %i" % (vertexCount - 3, vertexCount - 2, vertexCount - 1))
							tris.appendChild(i3dt)
							verts.appendChild(createI3dVert(self, 1))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 2))
							vertexCount=vertexCount+1
							verts.appendChild(createI3dVert(self, 3))
							vertexCount=vertexCount+1
							i3dt = self.doc.createElement("t")
							i3dt.setAttribute("vi", "%i %i %i" % (vertexCount - 3, vertexCount - 2, vertexCount - 1))
							tris.appendChild(i3dt)
					else: 
						verts.appendChild(createI3dVert(self, 0))
						vertexCount=vertexCount+1
						verts.appendChild(createI3dVert(self, 1))
						vertexCount=vertexCount+1
						verts.appendChild(createI3dVert(self, 2))
						vertexCount=vertexCount+1
						i3dt = self.doc.createElement("t")
						if len(face.v)==4:#its a quad and is exported as one
							verts.appendChild(createI3dVert(self, 3))
							vertexCount=vertexCount+1
							i3dt.setAttribute("vi", "%i %i %i %i" % (vertexCount - 4, vertexCount - 3, vertexCount - 2, vertexCount - 1))
						else:#it should be a triangle since blender dosnt support ngons, or the user chose not to triangulate
							i3dt.setAttribute("vi", "%i %i %i" % (vertexCount - 3, vertexCount - 2, vertexCount - 1))
						tris.appendChild(i3dt)
			subset = self.doc.createElement("Subset")
			subset.setAttribute("firstVertex", "%i" % (firstVertex))
			subset.setAttribute("numVertices", "%i" % (vertexCount-firstVertex))
			subset.setAttribute("firstIndex", "%i" % (3 * firstIndex))
			subset.setAttribute("numIndices", "%i" % (3*(faceCount-firstIndex)))
			#subset.setAttribute("numIndices", "%i" % (faceCount-firstIndex))
			subs.appendChild(subset)
		
		tris.setAttribute("count", "%i" % (faceCount))
		verts.setAttribute("count", "%i" % (vertexCount))
		if tangents:
			verts.setAttribute("tangent", "true")
		subs.setAttribute("count", "%i" % (materialCount))
		if exportNormals:
			verts.setAttribute("normal", "true")
		if not parentArmBones is None:
			verts.setAttribute("blendweights", "true")
		if mesh.faceUV:#todo multiple uv sets!! but how????
			verts.setAttribute("uv0", "true")
				
		its.appendChild(verts)
		its.appendChild(tris)
		its.appendChild(subs)
		
		return self.lastShapeId, materialIds
	
	def addMaterial(self, mat):
		tangents = false
		if mat is None:
			if not self.defaultMat:#create a nice pink default material
				self.lastMaterialId = self.lastMaterialId + 1
				m = self.doc.createElement("Material")
				m.setAttribute("name", "Default")
				m.setAttribute("materialId", "%i"%self.lastMaterialId)
				m.setAttribute("diffuseColor", "%f %f %f %f" % (1, 0, 1, 1))
				self.materials.appendChild(m)
				self.defaultMat = self.lastMaterialId
			return self.defaultMat, false
		
		for m in self.materials.getElementsByTagName("Material"):
			if m.getAttribute("name") == mat.getName():
				if len(m.getElementsByTagName("Normalmap")) > 0:
					tangents = true
				return int(m.getAttribute("materialId")), tangents#todo: tangents!!!
		m = self.doc.createElement("Material")
		m.setAttribute("name", mat.name)
		self.lastMaterialId = self.lastMaterialId + 1
		m.setAttribute("materialId", "%i" % self.lastMaterialId)
		
		m.setAttribute("diffuseColor", "%f %f %f %f" % (mat.getRGBCol()[0]*mat.ref, mat.getRGBCol()[1]*mat.ref, mat.getRGBCol()[2]*mat.ref, mat.getAlpha()))
		if mat.getAlpha() < 1:
			m.setAttribute("alphaBlending", "true")
		m.setAttribute("specularColor", "%f %f %f" % (mat.specR*mat.spec, mat.specG*mat.spec, mat.specB*mat.spec))
		m.setAttribute("cosPower", "%i" % (mat.getHardness()))
		
		if mat.getMode() & Material.Modes['NOMIST']:
			m.setAttribute("allowFog", "false")
		
		texturN = 0
		for textur in mat.getTextures():
			texturEnabled = 0
			for t in mat.enabledTextures:
				if t == texturN:
					texturEnabled=1
					break
			if texturEnabled:
				if textur.tex.getImage() is None or textur.tex.getImage().getFilename() is None:
					print("WARNING: cannot export texture named %s, its not an image!" %textur.tex.getName())
				else:
					path = textur.tex.getImage().getFilename()
					backslash = path.rfind("/")
					if not backslash == -1:
						path = path[backslash+1:]#cut eveerything infront of the filename. will this work on windows? todo: test
					
					#print("path %s" %path)
					#path = "assets/"+path
					if textur.mtCol:#Map To Col
						i3dTex = self.doc.createElement("Texture")
						i3dTex.setAttribute("fileId", "%i"%self.addFile(path))
						m.appendChild(i3dTex)
					if textur.mtNor:#Map To Nor
						if textur.mtNor == -1:
							print("WARNING: normalmap %s cannot be inverted by the exporter" %textur.tex.getName())
						i3dTex = self.doc.createElement("Normalmap")
						i3dTex.setAttribute("fileId", "%i"%self.addFile(path))
						m.appendChild(i3dTex)
						tangents = true
					if textur.mtCsp:#Map To Spec
						if textur.mtSpec == -1:
							print("WARNING: specularmap %s cannot be inverted by the exporter" %textur.tex.getName())
						i3dTex = self.doc.createElement("Glossmap")
						i3dTex.setAttribute("fileId", "%i"%self.addFile(path))
						m.appendChild(i3dTex)
					#todo: other maps
			texturN = texturN + 1
		
		#parse material ScriptLink file and merge xml into i3d (if it ends with .i3d)
		for sl in mat.getScriptLinks("FrameChanged") + mat.getScriptLinks("Render") + mat.getScriptLinks("Redraw") + mat.getScriptLinks("ObjectUpdate") + mat.getScriptLinks("ObDataUpdate"):
			if sl.endswith(".i3d"):
				xmlText = ""
				for l in Text.Get(sl).asLines():
					xmlText = xmlText + l
				slDom = None
				try:
					slDom = parseString(xmlText)
				except:
					print "WARNING: cant parse material script link %s"%sl
					slDom = None
				if not slDom is None:
					for n in slDom.getElementsByTagName("Material"):						
						i = 0
						while i < n.attributes.length:#coppy attributes
							attr = n.attributes.item(i)
							if attr.nodeValue.startswith("assets/"):
								m.setAttribute(attr.nodeName, "%i"%self.addFile(attr.nodeValue))
							else:
								m.setAttribute(attr.nodeName, attr.nodeValue)
							i = i+1
						for cn in n.childNodes:#coppy child elements
							if cn.nodeType == cn.ELEMENT_NODE:
								#print cn							
								if not cn.attributes is None:
									i = 0
									while i < cn.attributes.length:
										attr = cn.attributes.item(i)
										if attr.nodeValue.startswith("assets/"):
											attr.nodeValue = "%i"%self.addFile(attr.nodeValue)
										i = i+1
								m.appendChild(cn)
		
		self.materials.appendChild(m)
		return self.lastMaterialId, tangents
	
	#returns fileId
	#if no file with the same name exists the file element is created
	#otherwise the fileId of the existing element is returned
	#todo: coppy image to assets folder?
	def addFile(self, path, relative=true):
		#os.path.relpath(path, exportPath)#dosnt word. python version to old?
		head, path = os.path.split(path)
		path = os.path.join("assets", path)
		#print("fileTo : %s"%path)
		if not relative:
			path = os.path.join(exportPath, path)
		newFileId = 1
		for f in self.files.childNodes:
			if f.getAttribute("filename") == path:
				#print("file %s is already added, it has id %s" %(path, f.getAttribute("fileId")))
				return int(f.getAttribute("fileId"))
			fileId = int(f.getAttribute("fileId"))
			if fileId >= newFileId:
				newFileId = fileId + 1
		f = self.doc.createElement("File")
		f.setAttribute("fileId", "%i" % newFileId)
		f.setAttribute("filename", path)
		if relative:
			f.setAttribute("relativePath", "true")
		self.files.appendChild(f)
		return newFileId
			
	def printToFile(self, filepath):
		out = file(filepath, 'w')
		out.write(self.doc.toprettyxml())
		out.close()
		
#-------END of i3d class------------------------------------------------------------------

#get a list of vertexGroups and asociated weights this vertex belonges to
def getVGroup(vertIndex, mesh):
	groupWeight = []
	#print "getVGroup in %s"%mesh.name
	for group in mesh.getVertGroupNames():
		#print "group %s" %group
		singleElement = mesh.getVertsFromGroup(group, 1, [vertIndex])
		if len(singleElement)==1:
			groupWeight.append({0:group, 1:singleElement[0][1]})
		elif len(singleElement)==0:
			#print "nul?"
			pass
		else:
			print "SCARRY!"
	return groupWeight

#GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI
#  GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI
#    GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI
#  GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI
#GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI      GUI

# Assign event numbers to buttons
evtExport = 1
evtPathChanged = 2
evtBrows = 3
evtExportSelection = 4
evtExportNormals = 5
evtExportTriangulated = 6
evtAddObjExtension = 7
evtAddMatExtension = 8

#toggle button states
exportSelection = false
exportNormals = true
exportTriangulated = true

#global button return values to avoid memory leaks
guiExport = 0
guiBrows = 0
guiExportSelection = 0
guiExportNormals = 0
guiExportTriangulated = 0
guiAddObjExtension = 0
guiAddMatExtension = 0
guiLogo = 0
stop = 0
showHelp = 0
guiPopup = 0

# initial button values
exportPath = Draw.Create(Get("filename")[0:Get("filename").rfind(".")]+".i3d")#creates a text box thing

#mouse x/y (just for fun)
#mouseX = 0
#mouseY = 0

logo = false
try:
	logo = Image.Load(Get("scriptsdir")+"/giants_logo.png")
except:
	logo = false
	

def gui():
	global evtExport, evtPathChanged, evtBrows
	global exportPath
	global guiExport, guiBrows, guiExportSelection, guiExportNormals, guiExportTriangulated, guiAddObjExtension, guiAddMatExtension, guiLogo
	
	guiAddObjExtension = Draw.PushButton("add obj script link", evtAddObjExtension, 10, 155, 150, 25, "add a text file for more i3d object properties and link it to the active object via script links")
	guiAddMatExtension = Draw.PushButton("add mat script link", evtAddMatExtension, 175, 155, 155, 25, "add a text file for more i3d material properties and link it to the active material via script links")
	guiExportSelection = Draw.Toggle("only selected", evtExportSelection, 10, 120, 100, 25, exportSelection, "only export selected objects")
	guiExportTriangulated = Draw.Toggle("triangulate", evtExportTriangulated, 120, 120, 100, 25, exportTriangulated, "convert quads to triangles (shortest edge)")
	guiExportNormals = Draw.Toggle("normals", evtExportNormals, 230, 120, 100, 25, exportNormals, "export vertex normals")
	exportPath = Draw.String("export to: ", evtPathChanged, 10, 85, 260, 25, exportPath.val, 256,"export to %s" %exportPath.val)
	guiBrows = Draw.PushButton("Brows", evtBrows, 280, 85, 50, 25, "open file browser to chose export location")
	if exportSelection:
		guiExport = Draw.PushButton("Export Selection", evtExport, 70, 10, 260, 50, "write i3d to selected file")
	else:
		guiExport = Draw.PushButton("Export Scene", evtExport, 70, 10, 260, 50, "write i3d to selected file")
	if logo:
		BGL.glEnable( BGL.GL_BLEND ) # Only needed for alpha blending images with background.
		BGL.glBlendFunc(BGL.GL_SRC_ALPHA, BGL.GL_ONE_MINUS_SRC_ALPHA)
		guiLogo = Draw.Image(logo, 12, 13)
		BGL.glDisable( BGL.GL_BLEND )

def event(evt, val):  # function that handles keyboard and mouse events
	#global mouseX, mouseY
	global stop, showHelp
	if evt == Draw.ESCKEY or evt == Draw.QKEY:
		stop = Draw.PupMenu("OK?%t|Stop script %x1")
		if stop == 1:
			Draw.Exit()
			return
	if evt in [Draw.LEFTMOUSE, Draw.MIDDLEMOUSE, Draw.RIGHTMOUSE] and val:
		showHelp = Draw.PupMenu("Show Help?%t|Ok%x1")
		if showHelp == 1:
			ShowHelp("i3dExporter.py")

def buttonEvt(evt):
	global evtExport, evtPathChanged, evtBrows, evtExportSelection, exportSelection, exportNormals, exportTriangulated
	global exportPath
	global guiPopup
	if evt == evtExport:
		i3d = I3d()
		sce = bpy.data.scenes.active
		if exportSelection:
			for obj in sce.objects.selected:
				i3d.addObject(obj)
		else:
			for obj in sce.objects:
				i3d.addObject(obj)
		i3d.printToFile(exportPath.val)
		
		print("exported to %s"%exportPath.val)
	if evt == evtPathChanged:
		pass
	if evt == evtBrows:
		Window.FileSelector(selectExportFile, "Ok", exportPath.val)
	if evt == evtExportSelection:
		exportSelection = 1 - exportSelection
		Draw.Redraw(1)
	if evt == evtExportNormals:
		exportNormals = 1 - exportNormals
		Draw.Redraw(1)
	if evt == evtExportTriangulated:
		exportTriangulated = 1 - exportTriangulated
		Draw.Redraw(1)
	if evt == evtAddObjExtension:
		activeObj = bpy.data.scenes.active.objects.active
		slName = "%s.i3d"%activeObj.name
		sl = None
		try:
			sl = Text.Get(slName)
		except:
			sl = None
		if not sl is None:
			guiPopup = Draw.PupMenu("%s already exists. Find it in the Text Editor"%slName)
		else:
			sl = Text.New(slName)
			sl.write("""<!--
this describes some i3d properties of the object it is linked to via Script Links.
the name of this text file must end with ".i3d".
all attributes of the SceneType node are copied to the Object in the final i3d.
"i3dNodeId" is replaced by the id the object gets in the i3d scene.
For the UserAttributes to work the attribute nodeId must be "i3dNodeId".
-->
<i3D>
	<Scene>
		<SceneType static="true" dynamic="false" kinematic="false"/>
	</Scene>
	<UserAttributes>
		<UserAttribute nodeId="i3dNodeId">
			<Attribute name="onCreate" type="scriptCallback" value="print"/>
		</UserAttribute>
	</UserAttributes>
</i3D>""")
			activeObj.addScriptLink(sl.getName(), "FrameChanged")
			guiPopup = Draw.PupMenu("Check ScriptLink panel and Text Editor for %s"%sl.getName())
	if evt == evtAddMatExtension:
		activeObj = bpy.data.scenes.active.objects.active
		activeMat = activeObj.getData().materials[activeObj.activeMaterial-1]
		slName = "%s.i3d"%activeMat.name
		sl = None
		try:
			sl = Text.Get(slName)
		except:
			sl = None
		if not sl is None:
			guiPopup = Draw.PupMenu("%s already exists. Find it in the Text Editor"%slName)
		else:
			sl = Text.New(slName)
			sl.write("""<!--
this describes some i3d properties of the material it is linked to via Script Links.
the name of this text file must end with ".i3d".
all attribute values starting with "assets/" are added to the Files Node and replaced with the id.
in order for file references to work the path must start with "assets/".
-->
<i3D>
	<Materials>
		<Material customShaderId="assets/exampleCustomShader.xml">
			<Custommap name="colorRampTexture" fileId="assets/exampleCustomMap.png"/>
			<CustomParameter name="exampleParameter" value="2 0 0 0"/>	
		</Material>
	</Materials>
</i3D>""")
			activeMat.addScriptLink(sl.getName(), "FrameChanged")
			guiPopup = Draw.PupMenu("Check ScriptLink panel and Text Editor for %s"%sl.getName())
		

def selectExportFile(file):
	global exportPath
	exportPath.val = file
	#print(file)

if __name__ == '__main__':
	Draw.Register(gui, event, buttonEvt)