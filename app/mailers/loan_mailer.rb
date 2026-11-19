class LoanMailer < ApplicationMailer
  default from: "library@example.com"

  def reminder_3_days(loan)
    @loan = loan
    @reader = loan.reader
    @book = loan.book
    mail(to: @reader.email, subject: "Reminder: return '#{@book.title}' in 3 days")
  end

  def due_today(loan)
    @loan = loan
    @reader = loan.reader
    @book = loan.book
    mail(to: @reader.email, subject: "Due today: '#{@book.title}'")
  end
end
