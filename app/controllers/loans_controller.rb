class LoansController < ApplicationController
  def create
    book = Book.find_by(serial_number: params[:book_id])
    return render json: { error: "Book not found" }, status: :not_found unless book

    if book.borrowed?
      return render json: { error: "Book is already borrowed" }, status: :conflict
    end

    if params[:card_number].blank? && params[:email].blank?
      return render json: { error: "Either card_number or email is required" },
                    status: :bad_request
    end

    reader = Reader.find_by_identifier(
      card_number: params[:card_number],
      email: params[:email]
    )
    return render json: { error: "Reader not found" }, status: :not_found unless reader

    loan = Loan.new(book: book, reader: reader, borrowed_at: Time.current)
    if loan.save
      render json: LoanPresenter.new(loan).as_json, status: :created
    else
      render json: { errors: loan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def return
    loan = Loan.find_by(id: params[:id])
    return render json: { error: "Loan not found" }, status: :not_found unless loan

    if loan.returned?
      return render json: { error: "Loan already returned" }, status: :conflict
    end

    loan.update!(returned_at: Time.current)
    render json: LoanPresenter.new(loan).as_json
  end
end
