# spec/jobs/send_due_reminders_job_spec.rb
require "rails_helper"

RSpec.describe SendDueRemindersJob, type: :job do
  include ActiveJob::TestHelper

  let(:book) { create(:book) }
  let(:reader) { create(:reader) }

  before { ActiveJob::Base.queue_adapter = :test }

  it "sends reminder_3_days for loans due in 3 days" do
    loan = create(:loan, book: book, reader: reader, due_at: 3.days.from_now)

    expect {
      described_class.perform_now
    }.to have_enqueued_mail(LoanMailer, :reminder_3_days).with(loan)
  end

  it "sends due_today for loans due today" do
    loan = create(:loan, book: book, reader: reader, due_at: Time.current)

    expect {
      described_class.perform_now
    }.to have_enqueued_mail(LoanMailer, :due_today).with(loan)
  end

  it "does not send reminders for returned loans" do
    create(:loan, book: book, reader: reader, due_at: 3.days.from_now, returned_at: 1.day.ago)

    expect {
      described_class.perform_now
    }.not_to have_enqueued_mail(LoanMailer)
  end

  it "does not send reminders for loans due in 5 days" do
    create(:loan, book: book, reader: reader, due_at: 5.days.from_now)

    expect {
      described_class.perform_now
    }.not_to have_enqueued_mail(LoanMailer)
  end
end
