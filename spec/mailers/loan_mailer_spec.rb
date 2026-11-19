# spec/mailers/loan_mailer_spec.rb
require "rails_helper"

RSpec.describe LoanMailer, type: :mailer do
  let(:book) { create(:book, title: "Dune") }
  let(:reader) { create(:reader, email: "jan@example.com", full_name: "Jan Kowalski") }
  let(:loan) { create(:loan, book: book, reader: reader, due_at: 3.days.from_now) }

  describe "#reminder_3_days" do
    let(:mail) { described_class.reminder_3_days(loan) }

    it "renders the headers" do
      expect(mail.subject).to eq("Reminder: return 'Dune' in 3 days")
      expect(mail.to).to eq([ "jan@example.com" ])
      expect(mail.from).to eq([ "library@example.com" ])
    end

    it "renders the body" do
      body = mail.body.encoded
      expect(body).to include("Dune")
      expect(body).to include(book.serial_number)
      expect(body).to include("Jan Kowalski")
      expect(body).to include("in 3 days")
    end
  end

  describe "#due_today" do
    let(:loan) { create(:loan, book: book, reader: reader, due_at: Time.current) }
    let(:mail) { described_class.due_today(loan) }

    it "renders the headers" do
      expect(mail.subject).to eq("Due today: 'Dune'")
      expect(mail.to).to eq([ "jan@example.com" ])
    end

    it "renders the body" do
      body = mail.body.encoded
      expect(body).to include("Dune")
      expect(body).to include(book.serial_number)
      expect(body).to include("due back today")
    end
  end
end
