require 'typhoeus'
require 'json'

class Dict
  KEY = 'dict.1.1.20200827T171118Z.001659c8431dc4eb.2750e9e9c57545e74b5aff826f35e719657a76e4'.freeze

  def get(word)
    cached(word) || from_request(word)
  end

  private

  def cached(word)
    file = nil
    begin
      file = File.read('./cache.json')
    rescue => _e
      File.write('./cache.json', '{}')
      file = File.read('./cache.json')
    end
    content = JSON.parse(file)
    return unless content[word]
    definition(content[word]) || ''
  end

  def from_request(word)
    result = request word
    definition(result)
  end

  def definition(result)
    begin
      result['def'][0]['tr'][0]['text']
    rescue => _e
      nil
    end
  end

  def request(word)
    result = JSON.parse(Typhoeus.get(url(word)).body)

    file = File.read('./cache.json')
    content = JSON.parse(file)
    content[word] = result
    File.write('./cache.json', content.to_json)

    result
  end

  def url(word)
    "https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=#{KEY}&lang=en-ru&flags=4&text=#{word}"
  end
end

puts Dict.new.get('hyena')

