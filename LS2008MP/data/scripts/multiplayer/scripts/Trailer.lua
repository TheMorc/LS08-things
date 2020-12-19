--Trailer (original game script) MP script
--
function MPTrailerScriptUpdate()
	original.trailerAttachTrailer = Trailer.attachTrailer
	original.toggleTipState = Trailer.toggleTipState
	original.onStartTip = Trailer.onStartTip
	original.trailerhandleDetachTrailerEvent = Trailer.handleDetachTrailerEvent
	Trailer.attachTrailer = MPtrailerAttachTrailer
	Trailer.toggleTipState = MPtoggleTipState
	Trailer.onStartTip = MPonStartTip
	Trailer.handleDetachTrailerEvent = MPtrailerhandleDetachTrailerEvent
end


function MPtrailerAttachTrailer(self, trailer)
	--original.trailerAttachTrailer(self, trailer) a weird thing happens here for some reason
	--so it gets executed from handleUDPmessage
	
	for i=1, #g_currentMission.trailers do
		for j=1, #g_currentMission.trailers do
      		if g_currentMission.trailers[i] == trailer and g_currentMission.trailers[j] == self then
    			MPSend("bc1;trailerAttachTrailer;"..j..";"..i)
        	end 	
        end
    end
end
function MPtoggleTipState(self)
	original.toggleTipState(self)
    for i=1, #g_currentMission.trailers do
      	if g_currentMission.trailers[i] == self then
    		MPSend("bc1;toggleTipState;"..MPplayerName..";"..i)
		end
	end
end
function MPonStartTip(self)
	original.onStartTip(self)
	g_currentMission.allowSteerableMoving = true;
    g_currentMission.fixedCamera = false;
end
function MPtrailerhandleDetachTrailerEvent(self)
	for i=1, #g_currentMission.trailers do
      	if g_currentMission.trailers[i] == self then
    		MPSend("bc1;trailerDetachTrailer;"..i)
        end 
    end
    
	return original.trailerhandleDetachTrailerEvent(self)
end