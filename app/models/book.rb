class Book < ApplicationRecord
  include SystemGeneratedNumber

  has_many :loans, dependent: :destroy

  system_generated_number :serial_number

  validates :title, :author, presence: true

  def current_loan
    loans.where(returned_at: nil).order(borrowed_at: :desc).first
  end

  def borrowed?
    current_loan.present?
  end

  def available?
    !borrowed?
  end
end
