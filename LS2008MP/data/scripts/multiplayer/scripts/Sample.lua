--Sample (mod script)
--author: sample name
--v1 - 25.11.2020
--
function MPSampleScriptUpdate()
	original.SampleUpdate = Sample.update
	Sample.update = MPSampleUpdate
end


function MPSampleUpdate(self, dt)
	original.SampleUpdate(self, dt)
end