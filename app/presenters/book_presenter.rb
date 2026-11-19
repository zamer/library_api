class BookPresenter < ApplicationPresenter
  def initialize(book, current_loan: :not_provided)
    @book = book
    @current_loan = current_loan == :not_provided ? book.current_loan : current_loan
  end

  def as_json
    {
      serial_number: @book.serial_number,
      title: @book.title,
      author: @book.author,
      status: @current_loan ? "borrowed" : "available",
      current_loan: @current_loan && LoanPresenter.new(@current_loan).as_json
    }
  end
end
