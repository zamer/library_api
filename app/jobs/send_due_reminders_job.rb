class SendDueRemindersJob < ApplicationJob
  queue_as :default

  def perform
    Loan.due_in_3_days.find_each { |loan| LoanMailer.reminder_3_days(loan).deliver_later }
    Loan.due_on(Date.current).find_each { |loan| LoanMailer.due_today(loan).deliver_later }
  end
end
