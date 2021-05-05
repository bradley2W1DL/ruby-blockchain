require 'rubygems'
require 'sinatra'
require 'securerandom'
require_relative 'blockchain'

configure do
  enable :sessions
end
#
# helpers do
#   def username
#     session[:identity] ? session[:identity] : 'Hello stranger'
#   end
# end

identifier = SecureRandom.hex(10)

before do
  @transactions = Blockchain.current_transactions
  @chain = Blockchain.chain

  manage_flash
end

after do
  session[:redirect] = redirect?
end

# before '/secure/*' do
#   unless session[:identity]
#     session[:previous_url] = request.path
#     @error = 'Sorry, you need to be logged in to visit ' + request.path
#     halt erb(:login_form)
#   end
# end

get '/' do
  erb :home
end

post '/transaction/new' do
  missing_params = %w[sender recipient amount] - params.keys
  if missing_params.any?
    session[:error] = "Missing required param: #{missing_params.join(', ')}"
    halt redirect '/'
  elsif params.values.select(&:empty?).any?
    session[:error] = "No empty values aloud"
    halt redirect '/'
  end
  index = Blockchain.new_transaction(params[:sender], params[:recipient], params[:amount])
  @transactions = Blockchain.current_transactions
  session[:notice] = "Transaction will be added to Block #{index}...eventually"
  redirect '/'
end

post '/mine' do
  # run the POW algorithm to get the next proof...
  last_block = Blockchain.chain.last
  last_proof = last_block[:proof]
  new_proof = Blockchain.proof_of_work(last_proof)

  # We should receive a reward for finding the proof.
  # The sender is "0" to signify that this node has mined a new coin.
  Blockchain.new_transaction('0', identifier, 1)

  # forge the new block by adding it to the chain
  previous_hash = Blockchain.hash(last_block)
  block = Blockchain.new_block(new_proof, previous_hash)
  session[:notice] = "Node number #{block[:index] + 1} added to the chain!"

  redirect '/'
end

get '/chain' do
  @full_chain = Blockchain.chain
  @length = @full_chain.length

  erb :chain
end

def manage_flash
  # count = session[:req_count] || 0
  unless session[:redirect]
    # session[:req_count] = 0
    session[:error] = nil
    session[:notice] = nil
  end
end

