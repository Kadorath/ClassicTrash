if playdate.math == nil then
	playdate.math = {}
end


function playdate.math.lerp(min, max, t)
	return min + (max - min) * t
end

function playdate.math.gate(value, threshold)
	if math.abs(value) < threshold then
		return 0
	else
		return value
	end
end

function playdate.math.clamp(min, max, value)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end