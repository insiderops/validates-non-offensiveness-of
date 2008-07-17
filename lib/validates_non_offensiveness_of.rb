module ValidatesNonOffensivenessOf # nodoc
  def self.offensive_words?(attr_name, value)
    word_scan = {}
    word_scan[attr_name]=scan_for_offensive_words(value.to_s)
    if !word_scan[attr_name].empty?
      error_string = ""      
      word_scan.sort_by(&:to_s).reverse.each do |field, ranges|
        error_string += "<div>"
        error_string += escape_and_highlight_ranges(value, ranges)
        error_string += "</div>"        
      end
      error_string
    else
      false      
    end
  end

  def self.scan_for_offensive_words(s)
    s = s.downcase
    unless @offensive_words_regex
      offensive_words_yaml = YAML::load_file(File.dirname(__FILE__) +'/offensive_words.yml')
      w = offensive_words_yaml.collect { |w| w.gsub(/\s+/, '\\s+') }.join('|')
      @offensive_words_regex = Regexp.new("\\b(#{w})\\b")
    end
    ranges = []
    scanner = StringScanner.new(s)
    until scanner.eos? || scanner.scan_until(@offensive_words_regex).nil?
      ranges.push((scanner.pos-scanner.matched_size) ... scanner.pos)
    end
    ranges
  end
  
  def self.escape_and_highlight_ranges(s, ranges)
    sorted_ranges = ranges.sort_by(&:first)
    start = 0
    result = []
    ranges.each do |range|
      result.push(sanitize(s[start ... range.first]))      
      result.push("<b><span style='color:red'>#{sanitize(s[range])}</span></b>")      
      start = range.last
    end
    result.push(sanitize(s[start .. -1]))
    result.join
  end  

  def self.sanitize(s)
    s
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      # Prevent offensive words from being saved
      def validates_non_offensiveness_of(*attr_names)
        validates_each(attr_names) do |record, attr_name, value|
          offensive_words = ValidatesNonOffensivenessOf::offensive_words?(attr_name, value)
          record.errors.add(attr_name, offensive_words) if offensive_words
        end      
      end
    end   
  end
end
