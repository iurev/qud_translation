require 'json'
require 'pry'
require 'russian'
require_relative 'tr.rb'

most_popular = File.read('./10k.txt')

puts most_popular.length

path = '/home/yu/games/Caves of Qud'
assets = 'game/CoQ_Data/StreamingAssets/Base/'

file_paths = Dir.glob("#{path}/#{assets}/**/*.{txt,xml,json}")

puts file_paths

# files = [
#     'QudCorpus.txt',
#     'QudCorpus1.txt',
#     'QudCorpus2.txt',
#     'Text.txt',
#     'Conversations.xml',
#     'Books.xml'
# ]

words = []

file_paths.each do |file_path|
  next if file_path.include? 'Keymap'
  next if file_path.include? 'template'
  next if file_path.include? 'ObjectDump'
  next if file_path.include? 'BuildingTiles'
  next if file_path.include? 'GlobalConfig'

  next unless file_path.include? 'Bodies'

  puts "Start: #{file_path}"
  # file_path = "/home/yu/games/Caves of Qud/game/CoQ_Data/StreamingAssets/Base/#{file_name}"

  file_content = nil

  begin
    file_content = File.read(file_path)
  rescue => e
    next
  end

  freq = file_content.split(/\W+/).map(&:downcase).inject(Hash.new(0)) { |h,v| h[v] += 1; h }

  list = freq.keys.sort {|a, b| freq[a] <=> freq[b] }

  list.reverse!
  list = list.reject {|w| /\d/.match?(w) }
  list = list.reject {|w| most_popular.include?(w) }
  list = list.reject {|w| w.include?('_') }

  words = words.concat(list)

  list.each.with_index do |word, index|
    puts "#{index} / #{list.count}"
    next if word.nil? || word.empty?
    result = Dict.new.get(word)
    next unless result
    next if result.empty?
    result = Russian.translit(result)
    result = result.gsub('"', '')
    result = result.gsub('\'', '4')

    puts "#{word} {{C|#{result}}}"

    "<bodyparttype Type=\"Fungal outcrop\" ({{C|obnazhenie}}) LimbBlueprintProperty=\"SeveredFungalOutcropBlueprint\" Category=\"Fungal\" />"

    # if file_path.include? 'xml'
    #   regexp = /(^| |:"| ")#{word}( |\.|\,|")/i
    # else
    # end
    regexp = /(^| |:"| ")#{word}( |\.|\,|"|$)/i

    file_content.gsub!(regexp, "\\1#{word}\\2 ({{C|#{result}}})")
  end

  File.write(file_path, file_content)

  puts "End: #{file_path}"
end

