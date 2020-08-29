require 'json'
require 'pry'
require 'russian'
require 'fuzzystringmatch'

require_relative 'tr.rb'

most_popular = File.read('./10k.txt')

puts most_popular.length

path = '/home/yu/games/Caves of Qud'
assets = 'game/CoQ_Data/StreamingAssets/Base/'

# file_paths = Dir.glob("#{path}/#{assets}/**/*.{txt,xml,json}")
file_paths = Dir.glob("#{path}/#{assets}/**/*.{json}")

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

dict = Dict.new

def traverse(obj, dict, word)
  regexp = /(#{word})/i

  if obj.is_a? Array
    return obj.map do |key|
      traverse(obj[key], dict, word)
    end
  end
  if obj.is_a? Hash
    result = {}
    obj.keys.map do |key|
      result[key] = traverse(obj[key], dict, word)
    end
    return result
  end

  str = obj

  return str unless str
  return str unless line.match? regexp

  result = dict.get(word)
  return str unless result
  return str if result.empty?
  result = Russian.translit(result)

  result = result.gsub('"', '')
  result = result.gsub('\'', '4')

  line.gsub(regexp, "\\1 *#{result}")
end

file_paths.each do |file_path|
  next if file_path.include? 'Keymap'
  next if file_path.include? 'template'
  next if file_path.include? 'ObjectDump'
  next if file_path.include? 'BuildingTiles'
  next if file_path.include? 'GlobalConfig'
  next if file_path.include? 'Display'
  next if file_path.include? 'Colors'
  next if file_path.include? 'Commands'
  next if file_path.include? 'Mods'
  next if file_path.include? 'ObjectBlueprints'
  next if file_path.include? 'Options'
  next if file_path.include? 'Population'
  next if file_path.include? 'Worlds'
  next if file_path.include? 'ZoneTemplates'
  next if file_path.include? 'Bodies'
  next if file_path.include? 'GlobalConfig'
  next if file_path.include? 'SultanDungeonSpice'
  next if file_path.include? 'HistorySpice'

  # next unless file_path.include? 'Books'

  puts "Start: #{file_path}"

  file_content = begin
    File.read(file_path)
  rescue => e
    next
  end

  list = file_content.split(/\W+/).map(&:downcase)

  # list = ['alchemist']

  list = list.reject {|w| /\d/.match?(w) }
  list = list.reject {|w| most_popular.include?(w) }
  list = list.reject {|w| w.include?('_') }
  list.uniq!

  lines = file_content.split("\n")
  json = begin
           JSON.parse(file_content)
         rescue => e
           puts e
  end

  list.each.with_index do |word, index|
    puts "#{index} / #{list.count}"
    next if word.nil? || word.empty?

    if file_path.include? 'xml'
      regexp = /(^|\ )(#{word})(\ |\.|\,)/i
    else
      regexp = /(^|\ |:"|\ ")(#{word})(\ |\.|\,|"|$)/i
    end

    if json.present?
      json = traverse(json, dict, word)
    else
      lines.map! do |line|
        next line unless line
        next line unless line.match? regexp
        if file_path.include? 'xml'
          next line if line.include?("\"")
        end

        result = dict.get(word)
        next line unless result
        next line if result.empty?
        result = Russian.translit(result)

        result = result.gsub('"', '')
        result = result.gsub('\'', '4')

        puts "#{word} {{C|#{result}}}"

        line.gsub(regexp, "\\1\\2 *#{result}\\3")
      end
    end
  end

  if json
    file_content = json.to_json
  else
    file_content = lines.join("\n")
  end

  File.write(file_path, file_content)

  puts "End: #{file_path}"
end

