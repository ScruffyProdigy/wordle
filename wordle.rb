def compare(guess, target)
  result = " " * guess.length
  unmatched = Hash.new { |h, k| h[k] = 0 }
  target.each_char do |c|
    unmatched[c] += 1
  end

  guess.each_char.with_index do |c, i|
    if target[i] == c
      result[i] = "G"
      unmatched[c] -= 1
    end
  end
  guess.each_char.with_index do |c, i|
    next if result[i] == "G"
    result[i] = if unmatched[c] > 0
      unmatched[c] -= 1
      "Y"
    else
      "B"
    end
  end

  result
end

def load_words filename
  File.foreach(filename).map {|line| line.strip! }.select {|line| line.length > 0}
end

class Game
  @@all_solutions = load_words("solutions.txt").freeze
  @@all_guesses = (load_words("allowed-guesses.txt") + @@all_solutions).freeze

  attr_reader :solutions

  def initialize
    reset
  end

  def reset
    @solutions = @@all_solutions.dup
    self
  end

  def trim(**guesses)
    guesses.each do |guess, result|
      trim!(guess.to_s, result)
    end
    self
  end

  def trim!(guess, result)
    @solutions.select! {|solution| compare(guess.downcase, solution) == result.upcase }
    self
  end

  def check_guess guess
    guess.downcase!
    results = Hash.new {|h,k| h[k] = 0 }
    @solutions.each do |solution|
      results[compare(guess, solution)] += 1
    end
    results
  end

  def all_guesses(guesses=nil)
    guesses ||= @@all_guesses
    Enumerator.new do |enum|
      guesses.each do |guess|
        results = check_guess(guess)

        next if results.length <= 1 && results["G" * guess.length] == 0

        enum.yield(guess, results)
      end
    end
  end

  def method_highest result_set
    result_set.max_by {|result, count| count}
  end

  def method_average result_set
    total = result_set.sum {|result, count| result.each_char.all? {|c| c == "G"} ? 0 : count * count}
    Math.sqrt(total / result_set.length)
  end

  def guess_list(value=1.0)
    guess_results.select{|a, b| b <= value}.map{|a, b| a}
  end

  def guess_results(guesses=nil, &evaluator)
    evaluator ||= method(:method_average)
    Enumerator.new do |enum|
      all_guesses(guesses).each do |guess, results|
        enum.yield guess, evaluator.call(results)
      end
    end
  end

  def get_next(guesses=nil, display=10, &evaluator)
    evaluator ||= method(:method_average)
    guess_results(guesses, &evaluator).min_by(display) {|guess, count| count}
  end

  def inspect
    "#{@solutions.length}: #{@solutions.join(', ')}"
  end
end

class Cluster
  def initialize count
    @games = []
    count.times do
      @games << Game.new
    end
  end

  def reset
    @games.each &:reset
    self
  end

  def trim!(guess, *results)
    raise "wrong number of results" if @games.length != results.length
    @games.each.with_index do |game, index|
      game.trim!(guess, results[index])
    end
    self
  end

  def trim(**guesses)
    guesses.each do |guess, results|
      trim!(guess.to_s, *results)
    end
    self
  end

  def [](index)
    @games[index]
  end

  def inspect
    @games.map.with_index {|g, i| "#{i} — #{g.inspect}"}.join("\n")
  end

  def map &block
    if block
      @games.map &block
    else
      @games
    end
  end
end
