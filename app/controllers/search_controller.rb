class SearchController < ApplicationController
 	def index
 	end

 	def results
    page = params.has_key?(:page) ? params[:page].to_i : 0
    @offset = page * 10
 		@index = Ferret::Index::Index.new(:path => 'new_index/index')
 	end
end
