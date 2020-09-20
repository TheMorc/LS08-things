GetPI(){


	pi := ((4 * atan(1/5)) - (atan(1/239))) * 4

	pi := 3.1415926535898
	return %pi%
}

Deg2Rad(degVal){

	pi := GetPI()
	rad := degVal * (pi / 180)
	if (degVal != 180) and (degVal != 0)
	{
		rad := pi - rad
	}
	return %rad%
}


Rad2Deg(radVal){

	pi := GetPI()
	Loop
	{
		if(radVal >= (2*pi)){
			radVal := radVal - (2*pi)
		}else{
			break
		}
	}
	grad := radVal * (180 / pi)
	grad := 180 - grad
	if(grad < 0){
		grad := 0
	}
	grad := Round(grad,0)
	return %grad%
}

RadRot2DegRot(rotY, rotX = 0, rotZ = 0){
	degRot := Rad2Deg(rotY)
	if(degRot = 180)
	{
		if(abs(rotX) < 3) and (abs(rotZ) < 3)
		{
			degRot := 0
		}
	}

	return %degRot%
}

GetCorrectRotation(xRot, yRot, zRot, absolute = false){
	result :=
	if(absolute){
		xRot *= 1.0
		yRot *= 1.0
		zRot *= 1.0
		result := RadRot2DegRot(yRot, xRot, zRot)
	}else{
		result := Round(yRot)
		Loop
		{
			if(result >= 360){
				result := result - 360.0
			}else{
				break
			}
		}
	}

	result := Round(result)
	return %result%
}


GetNormalizedRotation(oldRotation){
	normalizedRotation :=
	if(oldRotation > 10) and (oldRotation < 80){

		normalizedRotation := 45
	}else{
		if(oldRotation >= 80) and (oldRotation <= 100){

			normalizedRotation := 90
		}else{
			if(oldRotation > 100) and (oldRotation < 170){

				normalizedRotation := 135
			}else{
				if(oldRotation >= 170) and (oldRotation <= 190){

					normalizedRotation := 180
				}else{
					if(oldRotation > 190) and (oldRotation < 260){

						normalizedRotation := 225
					}else{
						if(oldRotation >= 260) and (oldRotation <= 280){

							normalizedRotation := 270
						}else{
							if(oldRotation > 280) and (oldRotation < 350){

								normalizedRotation := 315
							}else{


								normalizedRotation := 0
							}
						}
					}
				}
			}
		}
	}

	return %normalizedRotation%
}

GetBoolean(boolText){
	result := false
	if(boolText = "true") or (boolText = 1) or (boolText = "wahr"){
		result := true
	}
	return %result%
}
