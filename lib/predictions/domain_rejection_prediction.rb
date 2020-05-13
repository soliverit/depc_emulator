#################################################
# Domain rejection Prediction 					#
#												#
# Essentially a normal prediction but with 		#
# expected domain boundaries for the prediction #
# in addition to the expected value. Obviously,	#
# this needs to be used in a withError			#
# PredictionSet or at least with the domain		#
# and expected value Hash						#
#												#
# The recurring theme is obviously make 		#
# everything just work which unfortunately		#
# means, to quote Dutch "You need some god damn #
# faith, Arthur[user]!"							#
#################################################
class DomainRejectionPrediction < Prediction
	def initialize input, prediction, expected = nil
		if expected
			case expected.class.name
			when "Float"
				@expected = expected
				expected = {expected: expected, domainLowerBound: expected * 0.7, domainUpperBound: expected * 1.3}
			when "Integer"
				@expected = expected
				expected = {expected: expected, domainLowerBound: expected * 0.9, domainUpperBound: expected * 1.1}
			end
			if expected.class != Hash
				puts expected.to_json
			end
			raise "DomainRejectionPrediction::InvalidExpectationException" if expected.class != Hash
			raise "DomainRejectionPrediction::MissingDomainInfoException" if ! (expected[:domainLowerBound] && expected[:domainUpperBound])
			raise "DomainRejectionPrediction::InvalidTargetHashSize" if expected.keys.length != 3
		end
		expected.keys.each{|key|
			case key
			when :domainLowerBound
				@domainLowerBound = expected[key]
			when :domainUpperBound
				@domainUpperBound = expected[key]
			else
				@expected = expected[key]
			end
		}
		super(input, prediction, @expected)
	end
	##
	# OVERRIDDEN!
	#
	# Classify as a reject if the prediction is not within the expected domain
	#	WARNING!!! This forces the default ID for prediction value
	##
	def reject?
		prediction(0) < @domainLowerBound || prediction(0) > @domainUpperBound
	end
end
