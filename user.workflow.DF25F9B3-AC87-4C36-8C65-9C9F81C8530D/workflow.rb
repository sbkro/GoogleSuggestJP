# workflow.rb
# Author:: sbkro
# Copyright:: sbkro.apps 2013
# License:: New BSD License

require 'uri'
require 'net/http'
require 'rexml/document'
require 'kconv'

include REXML

# URL of google
SUGGEST_URL = "www.google.co.jp"

# URL of Google Suggest API
API_URL     = "/complete/search?hl=ja&output=toolbar&q="

#
# Get to suggetion words using Google Suggest API.
# This method dones as follow.
#
#  1. Get xml data from Google Suggest API.
#  2. Parse xml data.
#
# _query_ :: query string
# return :: suggestion words
def get_suggestion_words query
	array = Array.new
	res_xml = nil

	Net::HTTP.version_1_2
	Net::HTTP.start(SUGGEST_URL, 80) { |http|
		res_xml = http.get(API_URL + URI.escape(query)).body.toutf8
	}

	Document.new(res_xml).elements.each('toplevel/CompleteSuggestion/') { |e1|
		e1.elements.each('suggestion') { |e2|
			array.push(e2.attributes['data'])
		}
	}

	array.push query.toutf8 if array.size == 0

	array
end


#
# This method make filefilter xml using suggest words.
# Return data format is as follow.
#
#  <items>
#    <item uid="|word|" arg="|word|" valid="yes" autocomplete="">
#      <title>|word|</title>
#      <subtitle>Googleで「|word|」を検索します。</subtitle>
#      <icon>icon.png</icon>
#    <item>
#  </items>
#
# _word_list_ :: suggestion words
# return :: string data of filefilter xml.
#
def get_filefilter word_list
	xml = Document.new
	xml << XMLDecl.new("1.0", "UTF-8")

	tag_items = Element.new("items")
	xml.add_element(tag_items)

	word_list.each { |word|
		tag_item     = Element.new("item")
		tag_title    = Element.new("title")
		tag_subtitle = Element.new("subtitle")
		tag_icon     = Element.new("icon")

		# Settings for item
		tag_item.attributes["uid"] = word
		tag_item.attributes["arg"] = word
		tag_item.attributes["valid"] = "yes"
		tag_item.attributes["autocomplete"] = ""

		# Settings for title
		tag_title.text = word

		# Settins for subtitle
		tag_subtitle.text = "Googleで「" + word + "」を検索します。"

		# Settings for icon
		tag_icon.text = "icon.png"

		tag_item.add_element(tag_title)
		tag_item.add_element(tag_subtitle)
		tag_item.add_element(tag_icon)
		tag_items.add_element(tag_item)
	}

	xml
end
