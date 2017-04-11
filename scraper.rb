#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  composition = noko.xpath('//h2[.//span[@id="Composition"]]')
  composition.xpath('following-sibling::h2 | following-sibling::h3').slice_before { |e| e.name == 'h2' }.first.each do |maj_or_opp|
    maj_or_opp.xpath('following-sibling::h2 | following-sibling::h3 | following-sibling::h4').slice_before { |e| e.name != 'h4' }.first.each do |grp|
      group = grp.css('.mw-headline').text.split(/\(/).first.tidy
      grp.xpath('following-sibling::ul[1]/li').each do |li|
        person = li.css('a').first
        data = {
          name:     person.text.tidy,
          wikiname: person.attr('class') == 'new' ? '' : person.attr('title'),
          area:     li.text.split(',').last(2).join(', ').sub(')', '').tidy,
          party:    group,
          term:     2012,
        }
        ScraperWiki.save_sqlite(%i(name area party), data)
      end
    end
  end
end

scrape_list('https://fr.wikipedia.org/wiki/Assembl%C3%A9e_territoriale_des_%C3%AEles_Wallis_et_Futuna')
