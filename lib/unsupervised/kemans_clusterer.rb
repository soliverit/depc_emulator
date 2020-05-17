##
# Includes
##
## Native ##
require "kmeans-clusterer"
## Library ##
require "./lib/ollie_ml_unsupervised_base.rb"
#######################################################
# K-Means clustering (based on gbuesing's git kmeans
#
#######################################################
class KMeans < OllieMlUnsupervisedBase
	ELBOW_MODE			= :auto
	DEFAULT_PARAMETERS 	= {
		clusters: 			6,			# Numeric or :auto for elbowing
		lowClusterCount:	3,
		highClusterCount:	6,
		scorer:				Proc.new{|a, b| a.to_s <=> b.to_s},
		runs: 10
	}
	def initialize data, targets, parameters
		super data, parameters
		@targets 	= targets
		DEFAULT_PARAMETERS.each{|key, value| @parameters[key] ||= value}
	end
	def scaler
		
	end
	def labels
		@parameters[:labels]
	end
	def trainingData
		@trainingData.segregate @targets
	end
	##
	# Training a Clusterer
	##
	def train
		##
		# For convenience the method is standardised such that both
		# elbowing and explicitly defining cluster counts is the
		# same approach. This is done by creating either the range
		# or an array based on the :clusters property. ELBOW_MODE 
		# is :auto.
		##
		if @parameters[:clusters] == ELBOW_MODE
			testSeries = @parameters[:lowClusterCount]..@parameters[:highClusterCount]
		else
			testSeries	= [@parameters[:clusters]]
		end
		##
		# Elbow the series for however many then return the right machine.
		#
		# The "Right" machine is based on the :clusters parameter. If this is
		# :auto then the machine is elbowed to find the optimum number of cluster
		# based on the data within :lowClusterCount <= k <= :highClusterCount. If 
		# an Integer is given then that number is taken as the expected number
		# of clusters.
		##
		graphData = {}
		clusterers 	= testSeries.map{|clusterCount|
			clusterer = KMeansClusterer.run clusterCount, trainingData.data, labels: labels, runs: @parameters[:runs], scale_data: true
			graphData["K=" + clusterer.k.to_s] = (clusterer.error ** 0.5).round(2)
			clusterer
		}#.sort(&@parameters[:scorer])
		@lr = clusterers.first
	end
	def trainingClusters
		@lr.clusters rescue raise "KMeans not trained yet"
	end
	def predictSet rgDataSet
		rgDataSet.injectFeatures({clusterID:0})
		predictions = @lr.predict rgDataSet.segregate(@targets).getDataStructure(false)
		i 			= 0
		rgDataSet.apply{|data|
			data[:clusterID] = predictions[i]
			i += 1
		}
		rgDataSet
	end
end