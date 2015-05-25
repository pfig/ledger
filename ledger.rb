#!/usr/bin/env ruby

#
# How to use (with both the source code and ledger file present in the current
# directory):
#
# - From the command line:
#
#     ruby ledger.rb ledger.csv
#
#   (this will simply print the underlying data structures)
#
# - In irb or from code:
#     >> $:.unshift '.'
#     >> require "ledger"
#     >> ledger = Ledger.new "ledger.csv"
#     >> ledger.balance_for "john"
#     >> ledger.statement_on "2015-01-17", "john"
#     >> day = Date.new("2015-01-17")
#     >> ledger.statement_on day, "john"
#
#   Additionally, the auxiliary instance methods Ledger.dump, Ledger.entries,
#   and Ledger.balances can be used to inspect the data.
#
#
# I made the assumption that the ledger data would fit comfortably in memory,
# otherwise this would need modifying to accomodate CSV.foreach or the
# equivalent streaming method in other IO-based modules (e.g., File.each_line).
#
require "csv"
require "date"
require "json"

class Ledger

  attr_reader :balances
  attr_reader :entries

  def initialize(filename)
    @balances = {}
    @entries = {}
    begin
      @entries = CSV.read(filename)
        .map { |tx|
          @balances[tx[1]] = (@balances[tx[1]] || 0) - tx[3].to_f
          @balances[tx[2]] = (@balances[tx[2]] || 0) + tx[3].to_f
          {
            tx_date: Date.parse(tx[0]),
            tx_from: tx[1],
            tx_to: tx[2],
            tx_amount: tx[3].to_f } }
        .group_by { |tx| tx[:tx_date] }
        .each { |tx_date, entries|
          entries.map! { |tx| {
            tx_from: tx[:tx_from],
            tx_to: tx[:tx_to],
            tx_amount: tx[:tx_amount] } } }
    rescue Exception => e
      $stderr.puts e
    end
  end

  def balance_for(entity)
    begin
      @balances[entity]
    rescue Exception
      nil
    end
  end

  def statement_on(date, entity = nil)
    normalised_date = date
    unless normalised_date.respond_to?("year")
      begin
        normalised_date = Date.parse(date)
      rescue Exception => e
        $stderr.puts e
        return nil
      end
    end

    dates = @entries
      .select { |tx_dt,tx| tx_dt < normalised_date }
      .values
      .flatten

    out_amount = dates
      .select { |tx| tx[:tx_from] == entity }
      .map { |tx| tx[:tx_amount] }
      .reduce(0.0) { |total, amount| total + amount }
      .round(2)

    in_amount = dates
      .select { |tx| tx[:tx_to] == entity }
      .map { |tx| tx[:tx_amount] }
      .reduce(0.0) { |total, amount| total + amount }
      .round(2)

    in_amount - out_amount
  end

  def dump
    puts JSON.pretty_generate(@entries)
    puts JSON.pretty_generate(@balances)
  end

end

def help
  puts "
  Process a ledger file in CSV format.

  Usage: #{__FILE__} target.csv
  "
end

if __FILE__ == $0
  unless ARGV.size > 0
    help
    exit
  end

  ledger = Ledger.new(ARGV.shift)
  ledger.dump
end
