module RacersHelper

	def toRacer(value)
		unless value.class == Racer
			Racer.new(value)
		end
	end

end
