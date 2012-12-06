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

    # crawl this page  
    Anemone.crawl('http://www.concordia.ca', :depth_limit => 1) do | anemone |
      # only process pages in the article directory 

      anemone.on_every_page do |page|
        next if page.doc.nil?
        next if page.doc.at('title').nil?
        
        page.doc.at('body').xpath('//script').remove
        body = page.doc.at('body').text

        body_md5 = Digest::MD5.hexdigest(body)

        # skip if duplicate entry
        next if indexed[body_md5]
        indexed[body_md5] = 1

        index << {  
          :url => page.url,  
          :title => page.doc.at('title').text, 
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

    kmeans = KMeans.new(vectors_array, :centroids => 3)

    # puts kmeans.inspect

    cluster_indices = {}

    puts kmeans.inspect

    count = 0

    # create the clusters using k-means
    kmeans.view.each do |cluster|
      next if cluster.empty?
      cluster_indices[count] = [Ferret::Index::Index.new(:path => "clusters/#{count}"), '']
      puts "Creating index for cluster #{count}..."
      p cluster
      cluster.each do |doc_id|
        puts "adding #{doc_id}"
        cluster_indices[count][0] << {
          :url => index[doc_id][:url],
          :title => index[doc_id][:title],
          :content => index[doc_id][:content]
        }
      end
      count += 1
    end

    # find the most frequent term in each cluster
    cluster_indices.each do|key, val|
      terms = {}
    
      val[0].reader.terms(:content).each do |term, doc_freq|
        terms[term] = doc_freq
      end

      val[1] = terms.max_by {|k,v| v}.first
      puts "the most frequent term is #{val[1]}"
    end

    # doc_vectors.each do |key, val|
    #   File.open('vectors.txt', 'a') {|f| f.write "#{key}\n => \n #{val.inspect}\n" }
    # end

    # puts vectors_array[0].inspect

    @index = index

    render :index
  end
end
