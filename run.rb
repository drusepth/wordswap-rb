class WordswapService
  def self.metric_scores(sentence)
    {
      reading_level:   {
        label: "Reading level",
        value: DactylMetric.reading_level(sentence),
        method: ->(s) { DactylMetric.reading_level(s) }
      },

      number_of_words: word_count(sentence)
      #number_of_syllables: (FOR POETRY IDE)
    }
  end

  def self.maximal_swap(sentence, fitness_proc, recursive_score=0)
    replacements = []
    current_sentence_score = recursive_score

    sentence.split(' ').map.with_index do |word, i|
      puts "Replacing: #{word}"

      sanitized_word = word.downcase.gsub(/[\.,\?!]/, '')
      
      potential_replacements = thesaurus_results(sanitized_word)
      puts "Potential replacements: "
      potential_replacements.each do |replacement|
        new_sentence = begin
          dup_sentence = sentence.split(' ').dup
          dup_sentence[i] = replacement
          dup_sentence.join(' ')
        end
        new_sentence_score = fitness_proc.call(new_sentence)

        puts "[#{replacement}] - #{new_sentence}\n\tScore: #{new_sentence_score}"

        if new_sentence_score == current_sentence_score
          puts "Adding possible replacement #{word}=>#{replacement} of score #{new_sentence_score}"

          # Append to possible best-score options
          replacements << [i, word, replacement]
        elsif new_sentence_score > current_sentence_score
          # We have a new record, so clear the current possible options and add this one
          # todo minimal_swap flip > here
          puts "Clearing replacements for everything less than #{current_sentence_score}"
          replacements = [[i, word, replacement]]

          # Set new record
          current_sentence_score = new_sentence_score
        end
      end
    end.join(' ')

    puts "Replacements\n\t"
    puts replacements.inspect

    # Resolve replacements by picking 1 at random of best choices
    # tbd suggest all and let a consumer/user pick
    replacement = replacements.sample
    sentence_dup = sentence.dup.split(' ')
    sentence_dup[replacement[0]] = replacement[2]
    sentence_dup = sentence_dup.join(' ')

    previous_fitness = fitness_proc.call(sentence)
    new_fitness      = fitness_proc.call(sentence_dup)

    puts "Previous fitness = #{previous_fitness}"
    if new_fitness > previous_fitness # maximizing
      # If we made an improvement with this swap, then we want to run the function
      # again with the new sentence -- until no new improvements are made. 
      sentence, _, score = maximal_swap(sentence_dup, fitness_proc, new_fitness)

      if score >= new_fitness
        # If our recursion found a better solution, return that
        [sentence, fitness_proc, score]
      else
        # If this is the best solution, return the sentence we made
        [sentence_dup, fitness_proc, new_fitness]
      end
    else
      # If we didn't make an improvement to the score with this sentence,
      # just return it.
      [sentence_dup, fitness_proc, new_fitness]
    end
  end

  def self.minimal_swap(sentence, fitness_proc)
    # tbd
  end

  def self.words(sentence)
    sentence.split(' ')
  end

  def self.word_count(sentence)
    words(sentence).count
  end

  def self.thesaurus_results(word)
    # hit API or DB or something
    [word] + case word.downcase
    when 'quick'
      ['fast', 'speedy', 'super-fast', 'blazingly fast', 'Gonzales']
    when 'fox'
      ['foxy dogboy']
    when 'the'
      ['A']
    else
      []
    end
  end
end

class DactylMetric
  def self.reading_level(sentence)
    sentence.split(' ').count
  end
end

puts "Enter a sentence to input:"
sentence = gets.chomp
sentence = "The quick, brown fox jumped over the lazy-ass dog." if sentence.empty?

puts "Metric scores: "
puts WordswapService.metric_scores(sentence).inspect

puts "Doing the swap for: more words"
new_sentence, fitness, score = WordswapService.maximal_swap(sentence, ->(s) { DactylMetric.reading_level(s) })

puts "Original sentence: " + sentence.to_s + " (score=" + fitness.call(sentence).to_s + ")"
puts "New sentence: " + new_sentence.to_s + " (score=" + score.to_s + ")"

# maximizers/minimizers: [syllables, rhymes, reading level, sentiment, understandability, profanity filter]