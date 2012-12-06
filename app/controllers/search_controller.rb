class SearchController < ApplicationController
 	def index
 	end

 	def results
    @page = params.has_key?(:page) ? params[:page].to_i : 1
    offset = (@page - 1) * 10
    @query = params[:query]
    @cluster = params.has_key?(:cluster) ? params[:cluster].to_i : nil
    
    if @cluster.nil?
 	    @index = Ferret::Index::Index.new(:path => 'new_index/index')
    else
      @index = Ferret::Index::Index.new(:path => "clusters/#{@cluster}")
    end

    @results = @index.search @query, {:offset => offset}
    
    File.open('cluster_indices', 'r') do |file|
      @clusters = YAML::load(file.read)
    end

    File.open('doc_cluster_index', 'r') do |file|
      @doc_cluster_index = YAML::load(file.read)
    end
 	end
end
