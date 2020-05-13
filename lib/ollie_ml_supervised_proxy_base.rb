require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Proxy model bases
#################################################################
class OllieMlSupervisedProxyBase < OllieMlSupervisedBase
	def initialize data, target, parameters
		super data, target, parameters
	end
end
