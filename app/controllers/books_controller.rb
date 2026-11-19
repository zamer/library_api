class BooksController < ApplicationController
  before_action :set_book, only: %i[show destroy]

  BOOKS_SORTABLE = {
    "serial_number" => :serial_number,
    "title" => :title,
    "author" => :author,
    "created_at" => :created_at
  }.freeze

  LOANS_SORTABLE = {
    "borrowed_at" => :borrowed_at,
    "due_at" => :due_at,
    "returned_at" => :returned_at
  }.freeze

  # GET /books
  def index
    books = Book.all
    books = filter_by_status(books, params[:status])
    books = apply_sort(books, allowed: BOOKS_SORTABLE, default_sort: :serial_number, default_order: "asc")
    books = paginate(books)

    page = books.to_a
    active_loans = Loan.active.includes(:reader).where(book_id: page.map(&:id)).index_by(&:book_id)

    render json: {
      data: page.map { |b| BookPresenter.new(b, current_loan: active_loans[b.id]).as_json },
      meta: pagination_meta(books)
    }
  end

  # GET /books/:id
  def show
    loans = @book.loans.includes(:reader)
    loans = apply_sort(loans, allowed: LOANS_SORTABLE, default_sort: :borrowed_at, default_order: "desc")
    loans = paginate(loans)

    render json: BookPresenter.new(@book).as_json.merge(
      loans: loans.map { |l| LoanPresenter.new(l).as_json },
      loans_meta: pagination_meta(loans)
    )
  end

  # POST /books
  def create
    if params.dig(:book, :serial_number).present?
      return render json: {
        error: "serial_number is generated automatically and cannot be provided"
      }, status: :bad_request
    end

    book = Book.new(book_params)
    if book.save
      render json: BookPresenter.new(book, current_loan: nil).as_json, status: :created
    else
      render json: { errors: book.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /books/:id
  def destroy
    if @book.loans.active.exists?
      return render json: { error: "Cannot delete a currently borrowed book" },
                    status: :conflict
    end
    @book.destroy
    head :no_content
  end

  private

  def set_book
    @book = Book.find_by(serial_number: params[:id])
    render json: { error: "Book not found" }, status: :not_found unless @book
  end

  def book_params
    params.require(:book).permit(:title, :author)
  end

  def filter_by_status(collection, status)
    case status.to_s
    when "available"
      collection.where.not(id: Loan.active.select(:book_id))
    when "borrowed"
      collection.where(id: Loan.active.select(:book_id))
    else
      collection
    end
  end
end
