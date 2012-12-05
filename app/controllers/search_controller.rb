class SearchController < ApplicationController
 	def index

 	end

 	def new
 		@index = Ferret::Index::Index.new(:path => 'new_index/index')
 		@query = params[:query]
 	end
end
