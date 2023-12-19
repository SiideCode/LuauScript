local daPos = {}
daPos.__index = daPos

function daPos:new(startPos:number, endPos:number, line:number, fileRef:string?)
	local posInstance = {}

	setmetatable(posInstance, self)

	posInstance.startPos = startPos
	posInstance.endPos = endPos
	posInstance.line = line
	posInstance.fileRef = fileRef

	return posInstance
end

return daPos