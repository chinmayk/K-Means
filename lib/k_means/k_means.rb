require 'ext/object'

class KMeans

  attr_reader :centroids, :nodes

  def initialize(data, options={})
    distance_measure = options[:distance_measure] || :euclidean_distance
    @distance_measure = distance_measure
    @nodes = Node.create_nodes(data, options[:counts], distance_measure)
    @centroids = options[:custom_centroids] ||
      Centroid.create_centroids(options[:centroids] || 4, @nodes)
    @verbose = options[:verbose]

    perform_cluster_process(options)
  end

  def inspect
    @centroid_pockets.inspect
  end

  def view
    @centroid_pockets
  end

  private

	def perform_cluster_process_classic()
		iterations, updates = 0, 1
	    while updates > 0 && iterations < 100
	      iterations += 1
	      verbose_message("Iteration #{iterations}")
	      updates = 0
	      updates += update_nodes
	      reposition_centroids
	    end
	    place_nodes_into_pockets
	end

  def perform_cluster_process(options)
  	
  	centroids = []
  	
  	num_iterations = options[:custom_centroids].nil? ? 8 : 1
  	
  	for i in 1..num_iterations
	    iterations, updates = 0, 1
	    reset_nodes!
	    while updates > 0 && iterations < 200
	      iterations += 1
	      verbose_message("Iteration #{iterations}")
	      updates = 0
	      updates += update_nodes
	      reposition_centroids
	    end
	    
	    if updates > 0
	      puts "K-Means did not converge! Continuing with finding quality anyway"
	    end
	    place_nodes_into_pockets
	    quality = davies_bouldin_index(@centroids)
	    unless quality == 1.0/0
	    	centroids << {:centroids => @centroids.dup, :db_index => quality}
	    	puts "#{davies_bouldin_index(@centroids)} with #{@centroids.length} clusters"
	    else
	    	puts "Redoing iteration because quality is too low"
	    	redo
	    end
	    #For next iteration
	    @centroids = options[:custom_centroids] ||
      		Centroid.create_centroids(options[:centroids] || 4, @nodes) 
   	end
   	
   	@centroids = (centroids.min_by {|c| c[:db_index]})[:centroids]
   	
   	puts "Chose centroids with DB index = #{davies_bouldin_index(@centroids)}"
  end

  # Davies–Bouldin index: http://en.wikipedia.org/wiki/Cluster_analysis#Evaluation_of_clustering
  def davies_bouldin_index(centroids)
  	num_centroids = centroids.length
  	
  	db_index = 0
  	
  	non_empty_cluster_indexes = []
  	centroids.each_with_index do |centroid, index|
  		non_empty_cluster_indexes << index unless centroid.mean_node_distance < 0
  	end
  	
  	if non_empty_cluster_indexes.empty?
  		return +1.0/0	#Return -Infinity if all clusters are empty. Should not happen in real life.
  	end
  	
  	non_empty_cluster_indexes.each do |i|
  		local_index = -1.0/0 #Set to -infinity
  		non_empty_cluster_indexes.each do |j|
  			next if i == j
  			centroid_dist = centroids[i].position.send(@distance_measure, centroids[j].position)
  			sum_mean_nodes = centroids[i].mean_node_distance + centroids[j].mean_node_distance
  			#puts "#{centroid_dist}, #{sum_mean_nodes}" if sum_mean_nodes < 0 || centroid_dist < 0
  			
  			#sum_mean_nodes is less than zero if either cluster doesn't have assigned nodes. In that case, skip?
  			if sum_mean_nodes < 0
  				"sum_mean_nodes still zero"
  			end
  			db_measure = Float(sum_mean_nodes)/centroid_dist
  			#puts "db_measure = #{db_measure} for sum_mean_nodes= #{sum_mean_nodes} and centroid_dist= #{centroid_dist}"
  			local_index = db_measure if local_index < db_measure 
  			puts "#{db_measure}, sum_mean_nodes = #{sum_mean_nodes} when i = #{i} and j = #{j}" if local_index <= 0
  		end
  		
  		db_index += local_index
  	end
  	puts "db_index stays at #{db_index}" if db_index <= 0
  	return Float(db_index)/non_empty_cluster_indexes.length
  end
  
  def reset_nodes!
  	@nodes.each{|n| n.reset!}
  end

  # This creates an array of arrays
  # Each internal array represents a centroid
  # and each in the array represents the nodes index
  def place_nodes_into_pockets
    centroid_pockets = Array.new(@centroids.size) {[]}
    @centroids.each_with_index do |centroid, centroid_index|
      @nodes.each_with_index do |node, node_index|
        if node.closest_centroid == centroid
          centroid_pockets[centroid_index] << node_index
          #Store closest nodes in the centroid object
          centroid.nodes << node
        end
      end
    end
    @centroid_pockets = centroid_pockets
  end

  def update_nodes
    sum = 0
    @nodes.each do |node|
      sum += node.update_closest_centroid(@centroids)
    end
    sum
  end

  def reposition_centroids
    centroid_positions = @centroids.map(&:position)
    @centroids.each do |centroid|
      nodes = []
      @nodes.each {|n| nodes << n if n.closest_centroid == centroid}
      centroid.reposition(nodes, centroid_positions)
    end
  end

  def verbose_message(message)
    puts message if @verbose
  end

end
