class TimeParser
  DURATION_FORMAT = /(-?)(\d?\.?\d+)(\w?)/i
  TOKENS = {
    s: (1),
    m: (60),
    h: (60 * 60),
    d: (60 * 60 * 8)
  }.with_indifferent_access.freeze

  attr_reader :time, :sign

  def initialize(input)
    @input = input
    @time = 0
    parse
  end

  def to_d
    time / TOKENS[:d]
  end

  def to_h
    time / TOKENS[:h]
  end

  def to_m
    time / TOKENS[:m]
  end

  private

  def parse
    @input.scan(DURATION_FORMAT).each do |sign, amount, measure|
      @sign ||= sign
      add_time(amount.to_f * TOKENS.fetch(measure, TOKENS[:h]))
    end
  end

  def add_time(seconds)
    @time += (sign == '-') ? -seconds : seconds
  end
end
