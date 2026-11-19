class Loan < ApplicationRecord
  LOAN_DURATION = 30.days
  REMINDER_WINDOW = 3.days

  belongs_to :book
  belongs_to :reader

  validates :borrowed_at, :due_at, presence: true

  before_validation :set_due_date, on: :create

  scope :active, -> { where(returned_at: nil) }
  scope :due_on, ->(date) { active.where(due_at: date.all_day) }
  scope :due_in_3_days, -> { active.where(due_at: 3.days.from_now.all_day) }

  def active?
    returned_at.nil?
  end

  def returned?
    !active?
  end

  private

  def set_due_date
    self.borrowed_at ||= Time.current
    self.due_at ||= borrowed_at + LOAN_DURATION
  end
end
