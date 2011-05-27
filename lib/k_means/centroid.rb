class Centroid
  
  class << self
    def create_centroids(amount, nodes)
      ranges = create_ranges(nodes, nodes[0].position.size)
      (1..amount).map do
        position = ranges.inject([]) do |array, range|
          array << rand_between(range[0], range[1])
        end
        new(position)
      end
    end
    
    private
    
    def create_ranges(nodes, dimensions)
      ranges = Array.new(dimensions) {[0.0, 0.0]}
      nodes.each do |node|
        node.position.each_with_index do |position, index|
          # Bottom range
          ranges[index][0] = position if position < ranges[index][0]
          # Top range
          ranges[index][1] = position if position > ranges[index][1]
        end
      end
      ranges
    end
  end
  
  attr_accessor :position, :nodes
  
  def initialize(position)
    @position = position
    @mean_distance = -1
    @nodes = []
    @weight = -1
  end
  
  def mean_node_distance
  	return @mean_distance if @mean_distance >= 0
  	
  	total_dist, total_nodes = 0.0, 0.0
  	
  	@nodes.each do |node|
  		total_dist += node.best_distance * node.count
  		total_nodes += node.count
  	end
  	
  	if total_nodes > 0
  		@mean_distance = total_dist/total_nodes
	else
  		@mean_distance = -1.0/0
	end	 
  	 
  	@weight = total_nodes
  	@mean_distance
  end
  
  def weight 
  	return @weight unless @weight < 0
  	@weight = 0
  	@nodes.each do |node|
  		@weight += node.count 
  	end
  	
  	@weight
  end
  
  # Finds the average distance of all the nodes assigned to
  # the centroid and then moves the centroid to that position
  def reposition(nodes, centroids)
    return if nodes.empty?
    averages = [0.0] * nodes[0].position.size
    total_nodes = 0
    nodes.each do |node|
      node.position.each_with_index do |position, index|
        averages[index] += position *node.count
      end
      total_nodes += node.count
    end
    @position = averages.map {|x| x / total_nodes}
  end
  
end
