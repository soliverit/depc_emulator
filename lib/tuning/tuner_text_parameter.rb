class TunerSetParameter
	attr_reader :key
	def initialize key, options
		@key		= key
		@options 	= options
	end
	def mutate
		@options.shuffle.first
	end
	def options
		@options.dup
	end
end