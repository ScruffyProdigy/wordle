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

  def all_guesses
    Enumerator.new do |enum|
      @@all_guesses.each do |guess|
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
    total = result_set.sum {|result, count| result == "GGGGG" ? 0 : count * count}
    Math.sqrt(total / result_set.length)
  end

  def guess_results(&evaluator)
    evaluator ||= method(:method_average)
    Enumerator.new do |enum|
      all_guesses.each do |guess, results|
        enum.yield guess, evaluator.call(results)
      end
    end
  end

  def get_next(display=10, &evaluator)
    evaluator ||= method(:method_average)
    guess_results(&evaluator).min_by(display) {|guess, count| count}
  end

  def do
    get_next.each {|x| puts x}
  end
end

g = Game.new
