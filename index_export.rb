require 'ferret'
require 'JSON'
require 'CSV'

@index = Ferret::Index::Index.new(:path => '/Volumes/LACIESHARE/new_index/index')
  

CSV.open("index_export.csv", "wb") do |csv|
  @index.reader.terms(:content).each do |term, doc_freq|
    document_id_position_hash = {}
    tde = @index.reader.term_positions_for(:content, term)
    
    tde.each do |doc_id, freq|
      position_array = []
      tde.each_position {|pos| position_array << pos}
      document_id_position_hash[doc_id] = position_array
    end

    csv << [term, document_id_position_hash.to_json]
  end
end
