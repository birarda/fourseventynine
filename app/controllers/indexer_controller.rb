require 'readability'

class IndexerController < ApplicationController
  def index
    # tv = RDig.searcher.ferret_searcher.reader.term_vector(3022, :data)
    # @tv_term = tv.find {|tvt| tvt.term = "bergler"}
    # @tv_term = tv.class

    # vectors = {}
    # counter = 50
    # RDig.searcher.ferret_searcher.reader.each_tfidf_vec(:data) do |doc_id, tfidf_vec|
    #   vectors[doc_id] = tfidf_vec
    #   puts "#{doc_id} #{tfidf_vec.inspect}"
    #   break if counter < 1
    #   counter = counter - 1
    # end

    # vectors.each do |key, val|
    #   File.open('vectors.txt', 'a') {|f| f.write "#{key}\n => \n #{val.inspect}" }
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
  end
end
