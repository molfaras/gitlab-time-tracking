class TimeNote
  DATE_FORMAT = '%Y-%m-%d'

  attr_reader :time, :day, :comment

  def initialize(time:, day:, comment:)
    @time = time
    @day = day
    @comment = comment
  end

  def call
    comment.present? ? spend_time_note + comment_note : spend_time_note
  end

  private

  def spend_time_note
    "/spend #{time} #{day}"
  end

  def comment_note
    "\n> **#{day}:**\n#{comment}"
  end
end
