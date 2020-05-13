class TunerParameter
	attr_reader :key, :lower, :upper
	def initialize key, lower, upper, int=false
		@key		= key
		@lower		= lower
		@upper		= upper
		@integer	= int
	end
	def mutate
		@integer ? (@lower + (@upper - @lower) * rand).to_i : @lower + (@upper - @lower) * rand
	end
end