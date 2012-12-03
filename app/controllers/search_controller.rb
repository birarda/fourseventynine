class RDig::Search::Searcher
	def build_extract(data)
		data
	end
end

class SearchController < ApplicationController
  def new
  	tv = RDig.searcher.ferret_searcher.reader.term_vector(3022, :data)
		@tv_term = tv.find {|tvt| tvt.term = "bergler"}
		# @tv_term = tv.class


	  search_results = RDig.searcher.search(params[:query])
		@results = search_results[:list]
		@hitcount = search_results[:hitcount]

		render :index
  end
end
