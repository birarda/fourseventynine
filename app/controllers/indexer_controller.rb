class Ferret::Index::IndexReader

  TFIDF_THRESH = 0.0

  # return [doc_id, [term, tfidf] ]
  #  doc_id starts at 0
  #  tfidf drops values > THRESH
  #
  def each_tfidf_vec(field=:id, thresh=TFIDF_THRESH,  &block)

    doc_freq = {} # [term] => doc_freq
    terms(field).each { |term, df| doc_freq[term] = df }
    num_terms = doc_freq.size

     (0...num_docs).each do |doc_id|
      tv_terms = term_vector(doc_id, field).terms
      tf_norm = tv_terms.size

      tfidf_vec = tv_terms.map do |tv_term|
        term = tv_term.text
        tf = tv_term.positions.size
        df = doc_freq[term]

        tfidf = (tf.to_f/tf_norm.to_f) * Math.log(num_docs.to_f/df.to_f)

        [term,tfidf] if tfidf > thresh
      end

      #remove nil values (tfidf < thresh)
      # tfidf_vec.compact!
      tfidf_vec.each do |value|
        value = 0 if value.nil?
      end

      yield doc_id, tfidf_vec
    end
  end
end

class IndexerController < ApplicationController
  def index
    # tv = RDig.searcher.ferret_searcher.reader.term_vector(3022, :data)
    # @tv_term = tv.find {|tvt| tvt.term = "bergler"}
    # @tv_term = tv.class

    # REMEMBER! Pages that have not title.

    index = Ferret::Index::Index.new(:path => 'new_index/index')

    pages_indexed = 0
    indexed = {}

    Spidr.site('http://www.concordia.ca') do |spider|
      spider.every_html_page do |page|

        # skip if duplicate entry
        next if indexed[page.url]
        indexed[page.url] = 1

        next if page.at('body').nil?

        page.at('body').search('//script').remove
        body = page.at('body').text

        index << {  
          :url => page.url,  
          :title => page.title, 
          :content => body
        }
        
        pages_indexed += 1
        puts "#{page.url} indexed. Total: #{pages_indexed}"
      end
    end
    
    dictionary = {}
    
    index.reader.terms(:content).each do |term, doc_freq|
      dictionary[term] = 0
    end

    doc_vectors = {}

    # counter = 50

    index.reader.each_tfidf_vec(:content) do |doc_id, tfidf_vec|
      File.open('test.txt', 'a') {|f| f.write "#{doc_id}\n => \n #{tfidf_vec.sort {|x, y| x[1] <=> y[1]}.inspect}\n" }

      vector = dictionary

      tfidf_vec.each do |term, score|
        vector[term] = score
      end

      doc_vectors[doc_id] = vector.sort
      # break if counter < 1
      # counter = counter - 1
    end

    vectors_array = []
    doc_vectors.each do |key, val|
      vectors_array[key] = val.collect {|x| x[1]}
    end

    kmeans = KMeans.new(vectors_array, :centroids => 10)

    puts kmeans.inspect

    # doc_vectors.each do |key, val|
    #   File.open('vectors.txt', 'a') {|f| f.write "#{key}\n => \n #{val.inspect}\n" }
    # end

    # puts vectors_array[0].inspect

    @index = index

    render :index
  end
end
