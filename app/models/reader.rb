class Reader < ApplicationRecord
  include SystemGeneratedNumber

  has_many :loans, dependent: :restrict_with_error

  system_generated_number :card_number

  validates :full_name, presence: true
  validates :email, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.find_by_identifier(card_number: nil, email: nil)
    if card_number.present?
      find_by(card_number: card_number)
    elsif email.present?
      find_by(email: email)
    end
  end
end
