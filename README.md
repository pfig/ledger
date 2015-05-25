# Ledger

How to use (with both the source code and ledger file present in the current
directory):

- From the command line:

    `ruby ledger.rb ledger.csv`

  (this will simply print the underlying data structures)

- In irb or from code:
  ```ruby
     > $:.unshift '.'
     > require "ledger"
     > ledger = Ledger.new "ledger.csv"
     > ledger.balance_for "john"
     > ledger.statement_on "2015-01-17", "john"
     > day = Date.new("2015-01-17")
     > ledger.statement_on day, "john"
  ```
  Additionally, the auxiliary instance methods `Ledger.dump`,
  `Ledger.entries`, and `Ledger.balances` can be used to inspect the data.
