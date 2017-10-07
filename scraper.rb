#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraped'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

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
        data = {
          name:     li.text.split('(').first.tidy,
          area:     li.css('a').to_a.last(2).map(&:text).join(", "),
          party:    group,
        }
        puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
        ScraperWiki.save_sqlite(%i(name area party), data)
      end
    end
  end
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('https://fr.wikipedia.org/wiki/Assembl%C3%A9e_territoriale_des_%C3%AEles_Wallis_et_Futuna')
