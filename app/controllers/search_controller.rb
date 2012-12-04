require 'readability'

# class RDig::Search::Searcher
# 	def build_extract(data)
# 		data
# 	end
# end

# class Ferret::Index::IndexReader

#   TFIDF_THRESH = 0.0

#   # return [doc_id, [term, tfidf] ]
#   #  doc_id starts at 0
#   #  tfidf drops values > THRESH
#   #
#   def each_tfidf_vec(field=:id, thresh=TFIDF_THRESH,  &block)

#     doc_freq = {} # [term] => doc_freq
#     terms(field).each { |term, df| doc_freq[term] = df }
#     num_terms = doc_freq.size

#      (0...num_docs).each do |doc_id|
#       tv_terms = term_vector(doc_id, field).terms
#       tf_norm = tv_terms.size

#       tfidf_vec = tv_terms.map do |tv_term|
#         term = tv_term.text
#         tf = tv_term.positions.size
#         df = doc_freq[term]

#         tfidf = (tf.to_f/tf_norm.to_f) * Math.log(num_docs.to_f/df.to_f)

#         [term,tfidf] if tfidf > thresh
#       end

#       #remove nil values (tfidf < thresh)
#       tfidf_vec.compact!

#       yield doc_id, tfidf_vec
#     end
#   end
# end

class SearchController < ApplicationController
  def new
  	# tv = RDig.searcher.ferret_searcher.reader.term_vector(3022, :data)
		# @tv_term = tv.find {|tvt| tvt.term = "bergler"}
		# @tv_term = tv.class

		# vectors = {}
		# counter = 50
		# RDig.searcher.ferret_searcher.reader.each_tfidf_vec(:data) do |doc_id, tfidf_vec|
		# 	vectors[doc_id] = tfidf_vec
		# 	puts "#{doc_id} #{tfidf_vec.inspect}"
		# 	break if counter < 1
		# 	counter = counter - 1
		# end

		# vectors.each do |key, val|
		# 	File.open('vectors.txt', 'a') {|f| f.write "#{key}\n => \n #{val.inspect}" }
		# end


		# REMEMBER! Pages that have not title.

		index = Ferret::Index::Index.new(:path => 'new_index/index')

		pages_indexed = 0

		# crawl this page  
		Anemone.crawl('http://www.concordia.ca', :depth_limit => 5) do | anemone |
		  # only process pages in the article directory 
		  anemone.on_every_page do |page|
		  	next if page.doc.nil?
		  	readable = Readability::Document.new(page.body).content
		  	next if page.doc.at('title').nil?
	      # store the page in the index  
	      index << {  
	        :url => page.url,  
	        :title => page.doc.at('title').text, 
	        :content => page.doc.at('body').text, 
	        :readable => readable
	      }
	      pages_indexed += 1
	      puts "#{page.url} indexed. Total: #{pages_indexed}"
		  end  
		end

		@index = index

		render :index
  end
end
