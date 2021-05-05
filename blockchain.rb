require 'json'
require 'digest/sha2'

class Blockchain
  # rubocop:disable Layout/TrailingWhitespace
  class << self
    # defining all class-level methods on Blockchain singleton class
    def chain
      @chain ||= [
        {
          index: 0,
          timestamp: Time.now,
          transactions: [],
          proof: 100,
          previous_hash: '0'
        }
      ]
    end

    def current_transactions
      @current_transactions ||= []
    end

    def new_block(proof, previous_hash = nil)
      # create a new Block in the Blockchain
      # @param [Integer] :proof The proof given by the Proof of Work algorithm
      # @param [String] :previous_hash Hash of previous Block
      # @return [Hash] new "block"

      block = {
        index: chain.length + 1,
        timestamp: Time.now,
        transactions: current_transactions,
        proof: proof,
        previous_hash: previous_hash || hash(chain.last)
      }

      # reset current list of transactions
      @current_transactions = []

      @chain << block
      block
    end

    def new_transaction(sender, recipient, amount)
      @current_transactions << { sender: sender, recipient: recipient, amount: amount }
      # increment index
      chain.last[:index] + 1
    end

    def hash(block)
      # ensure keys are sorted for consistency
      block_string = JSON.generate(block.sort.to_h)
      Digest::SHA256.hexdigest block_string
    end

    # # #
    # proof of work stuff -- Mining for coins
    # POW (Proof Of Work) algorithm -- the goal of this is to discover a number which solves a problem
    #   * The number must be _difficult to find but easy to verify_ by everyone on the network
    # # #
    def proof_of_work(last_proof)
      # Find a number p' such that `hash(p * p')` contains 4 leading zeros, where p is the previous p' (from the last block)
      # "p" is the previous proof and "p'" is the new proof
      # @param [Integer] last_proof
      # @return [Integer]
      #
      proof = 0
      proof += 1 until validate_proof(last_proof, proof)

      proof
    end

    def validate_proof(last_proof, proof)
      # Validates the Proof: Does `hash(last_p, p)` contain 4 leading 0s?
      # @param [Integer] :last_proof the previous solution
      # @param [Integer] :proof current proof
      # @return [Boolean]

      guess = "#{last_proof}#{proof}".encode
      hash = Digest::SHA256.hexdigest guess
      hash[0...4] == '0000'
    end
  end
  # rubocop:enable Layout/TrailingWhitespace
end
