class TimeLog < ActiveRecord::Base
  ATTRIBUTES = %w[time day issue_iid project_id user_id comment].freeze

  validates :time, :day, :issue_iid, :project_id, :user_id, presence: true
  validates :time, numericality: { greater_than: 0 }
end
