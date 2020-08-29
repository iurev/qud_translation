require 'rexml/document'
include REXML
path = '/home/yu/games/Caves of Qud'
assets = 'game/CoQ_Data/StreamingAssets/Base/'
xmlfile = File.read("#{path}/#{assets}/Books.xml")
xmldoc = Document.new(xmlfile)
binding.pry
