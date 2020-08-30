require 'json'
require 'pry'
require 'russian'
require 'fuzzystringmatch'
require 'nokogiri'

require_relative 'tr.rb'

MOST_POPULAR = File.read('./10k.txt')

puts MOST_POPULAR.length

path = '/home/yu/games/Caves of Qud'
assets = 'game/CoQ_Data/StreamingAssets/Base/'

file_paths = Dir.glob("#{path}/#{assets}/**/*.{txt,xml,json}")
# file_paths = Dir.glob("#{path}/#{assets}/**/*.{xml}")

puts file_paths

dict = Dict.new

def traverse_str(str, dict)
  return str unless str.is_a? String

  str = str.dup
  list = str.split(/\W+/).map(&:downcase)

  list = list.reject {|w| /\d/.match?(w) }
  list = list.reject {|w| MOST_POPULAR.include?(w) }
  list = list.reject {|w| w.include?('_') }
  list.uniq!

  list.each do |word|
    regexp = /(#{word})/i

    next str unless str

    next str unless str.is_a? String
    next str unless str.match? regexp

    result = dict.get(word)
    next str unless result
    next str if result.empty?
    result = Russian.translit(result)

    result = result.gsub('"', '')
    result = result.gsub('\'', '4')

    puts "#{word}: #{result}"

    regexp = /(^|\ |"|\|)(#{word})(\ |\.|\,|}|")/i
    str.gsub!(regexp, "\\1\\2 (#{result})\\3")
  end

  str
end

def traverse_json(obj, dict)
  if obj.is_a? Array
    return obj.map do |o|
      traverse_json(o, dict)
    end
  end
  if obj.is_a? Hash
    result = {}
    obj.keys.map do |key|
      result[key] = traverse_json(obj[key], dict)
    end
    return result
  end

  traverse_str(obj, dict)
end

def traverse_xml(xml, dict)
  if xml.class == Nokogiri::XML::Comment
    return xml
  end

  if xml.class == Nokogiri::XML::Document
    traverse_xml(xml.children, dict)

    return xml
  end

  if xml.class == Nokogiri::XML::Element
    traverse_xml(xml.children, dict)
    traverse_xml(xml.attributes, dict)

    return xml
  end

  if Nokogiri::XML::NodeSet == xml.class
    return xml.each {|n| traverse_xml(n, dict)}
  end

  if Hash == xml.class
    xml.keys.each do |key|
      if %w[Short BehaviorDescription DisplayName].include? key
        begin
          xml[key].value = traverse_str(xml[key].value, dict)
        rescue
          binding.pry
        end
      end
    end
    return xml
  end

  if xml.class == Nokogiri::XML::Text
    xml.content = traverse_str(xml.content, dict)
    return xml
  end

  traverse_str(xml, dict)
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
  next if file_path.include? 'Options'
  next if file_path.include? 'Population'
  next if file_path.include? 'Worlds'
  next if file_path.include? 'ZoneTemplates'
  next if file_path.include? 'Bodies'
  next if file_path.include? 'GlobalConfig'
  next if file_path.include? 'SultanDungeonSpice'
  next if file_path.include? 'HistorySpice'

  puts "Start: #{file_path}"

  file_content = begin
    File.read(file_path)
  rescue => e
    next
  end

  xml = if file_path.include?('xml')
    Nokogiri::XML::Document.parse(file_content)
  end

  json = begin
           JSON.parse(file_content)
         rescue => e
           puts e
         end

  str = file_content

  if json
    json = traverse_json(json, dict)
  elsif xml
    traverse_xml(xml, dict)
  else
    str = traverse_str(file_content, dict)
  end

  if json
    file_content = json.to_json
  elsif xml
    file_content = xml.to_xml
  else
    file_content = str
  end

  File.write(file_path, file_content)

  puts "End: #{file_path}"
end
