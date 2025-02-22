require 'faraday'
require 'faraday_middleware'
require 'json'
require 'csv'
require 'uri'
require 'google_drive'
require 'digest/sha1'
require 'dotenv/load'
require 'tempfile'
require_relative 'brawl_data_fetcher'
require_relative 'data_formatter'
require_relative 'google_sheet_manager'

TIMESPAN = ENV['FETCH_DATA_TIMESPAN'].to_i

def execute
  fetcher = BrawlDataFetcher.new
  sheet_manager = GoogleSheetManager.new
  spreadsheet = sheet_manager.fetch_spreadsheet

  spreadsheet.worksheets.each do |worksheet|
    players = worksheet.rows[0].take(3).reject(&:empty?)
    next unless players.size >= 2

    filtered_items = fetcher.request(players.first).select do |item|
      item.dig('battle', 'teams').any? do |team|
        players.all? { |p| team.any? { |player| player['tag'] == p } }
      end
    end

    sheet_manager.write_csv(DataFormatter.format_response(filtered_items, players.first), worksheet)
  end
end

loop do
  execute
  sleep(TIMESPAN)
end