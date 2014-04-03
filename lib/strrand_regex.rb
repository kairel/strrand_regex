class StrrandRegex
  Upper  = Array('A'..'Z')
  Lower  = Array('a'..'z')
  Digit  = Array('0'..'9')
  Punct  = [33..47, 58..64, 91..96, 123..126].map { |r| r.map { |val| val.chr } }.flatten
  Any    = Upper | Lower | Digit | Punct
  Salt   = Upper | Lower | Digit | ['.', '/']
  Binary = (0..255).map { |val| val.chr }

  # These are the regex-based patterns.
  Pattern = {
    # These are the regex-equivalents.
    '.'  => Any,
    '\d' => Digit,
    '\D' => Upper | Lower | Punct,
    '\w' => Upper | Lower | Digit | ['_'],
    '\W' => Punct.reject { |val| val == '_' },
    '\s' => [' ', "\t"],
    '\S' => Upper | Lower | Digit | Punct,

    # These are translated to their double quoted equivalents.
    '\t' => ["\t"],
    '\n' => ["\n"],
    '\r' => ["\r"],
    '\f' => ["\f"],
    '\a' => ["\a"],
    '\e' => ["\e"]
  }

  #
  # Singleton method version of random_regex.
  #
  def self.random_regex(patterns)
    StrrandRegex.new.random_regex(patterns)
  end

  #
  # _max_ is default length for creating random string
  #
  def initialize(max = 10)
    @max   = max
    @regch = {
      "\\" => method(:regch_slash),
      '.'  => method(:regch_dot),
      '['  => method(:regch_bracket),
      '*'  => method(:regch_asterisk),
      '+'  => method(:regch_plus),
      '?'  => method(:regch_question),
      '{'  => method(:regch_brace)
    }
  end

  #
  # Returns a random string that will match 
  # the regular expression passed in the list argument.
  #
  def random_regex(patterns)
    return _random_regex(patterns) unless patterns.instance_of?(Array)

    result = []
    patterns.each do |pattern|
      result << _random_regex(pattern)
    end
    result
  end

  private

  def _random_regex(pattern)
    string = []
    string_result = []
    chars  = pattern.split(//)
    non_ch = /[\$\^\*\(\)\+\{\}\]\|\?]/  # not supported chars

    while ch = chars.shift
      if @regch.has_key?(ch)
        @regch[ch].call(ch, chars, string)
      else
        warn "'#{ch}' not implemented. treating literally." if ch =~ non_ch
        string << [ch]
      end
    end

    result = ''
    string.each do |ch|
      result << ch[rand(ch.size)]
    end
    result.chars.to_a.shuffle.join
  end
  
  #-
  # The folloing methods are defined for regch.
  # These characters are treated specially in random_regex.
  #+

  def regch_slash(ch, chars, string)
    raise 'regex not terminated' if chars.empty?

    tmp = chars.shift
    if tmp == 'x'
      # This is supposed to be a number in hex, so
      # there had better be at least 2 characters left.
      tmp = chars.shift + chars.shift
      string << tmp.hex.chr
    elsif tmp =~ /[0-7]/
      warn 'octal parsing not implemented. treating literally.'
      string << tmp
    elsif Pattern.has_key?(ch + tmp)
      string << Pattern[ch + tmp]
    else
      warn "'\\#{tmp}' being treated as literal '#{tmp}'"
      string << tmp
    end
  end

  def regch_dot(ch, chars, string)
    string << Pattern[ch]
  end

  def regch_bracket(ch, chars, string)
    tmp = []

    while ch = chars.shift and ch != ']'
      if ch == '-' and !chars.empty? and !tmp.empty?
        max  = chars.shift
        min  = tmp.last
        tmp << min = min.succ while min < max
      else
        warn "${ch}' will be treated literally inside []" if ch =~ /\W/
        tmp << ch
      end
    end
    raise 'unmatched []' if ch != ']'

    string << tmp
  end

  def regch_asterisk(ch, chars, string)
    chars = '{0,}'.split('').concat(chars)
  end

  def regch_plus(ch, chars, string)
    chars = '{1,}'.split('').concat(chars)
  end

  def regch_question(ch, chars, string)
    chars = '{0,1}'.split('').concat(chars)
  end

  def regch_brace(ch, chars, string)
    # { isn't closed, so treat it literally.
    return string << ch unless chars.include?('}')

    tmp = ''
    while ch = chars.shift and ch != '}'
      raise "'#{ch}' inside {} not supported" unless ch =~ /[\d,]/
      tmp << ch
    end

    tmp = if tmp =~ /,/
      raise "malformed range {#{tmp}}" unless tmp =~ /^(\d*),(\d*)$/

      min = $1.length.nonzero? ? $1.to_i : 0
      max = $2.length.nonzero? ? $2.to_i : @max
      raise "bad range {#{tmp}}" if min > max

      min == max ? min : min + rand(max - min + 1)
    else
      tmp.to_i
    end

    if tmp.nonzero?
      last = string.last
      (tmp - 1).times { string << last }
    else
      string.pop
    end
  end
end
