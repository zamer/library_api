# spec/requests/books_spec.rb
require "rails_helper"

RSpec.describe "Books API", type: :request do
  describe "GET /books" do
    let!(:books) { create_list(:book, 3) }

    it "returns paginated list of books" do
      get "/books"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(3)
      expect(json["meta"]).to include(
        "current_page" => 1,
        "per_page" => 20,
        "total_pages" => 1,
        "total_count" => 3
      )
    end

    it "respects per_page param" do
      get "/books", params: { per_page: 2 }
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
      expect(json["meta"]["per_page"]).to eq(2)
    end

    it "caps per_page at 100" do
      get "/books", params: { per_page: 9999 }
      json = JSON.parse(response.body)
      expect(json["meta"]["per_page"]).to eq(100)
    end

    it "returns empty data for page beyond total" do
      get "/books", params: { page: 999 }
      json = JSON.parse(response.body)
      expect(json["data"]).to be_empty
    end

    it "sorts by title ascending" do
      create(:book, title: "Zebra")
      create(:book, title: "Apple")
      get "/books", params: { sort: "title", order: "asc" }
      json = JSON.parse(response.body)
      titles = json["data"].map { |b| b["title"] }
      expect(titles).to eq(titles.sort)
    end

    it "ignores invalid sort column" do
      get "/books", params: { sort: "hacker_column" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by status=available" do
      book = create(:book)
      create(:loan, book: book)  # borrowed
      get "/books", params: { status: "available" }
      json = JSON.parse(response.body)
      statuses = json["data"].map { |b| b["status"] }
      expect(statuses).to all(eq("available"))
    end

    it "filters by status=borrowed" do
      book = create(:book)
      create(:loan, book: book)
      get "/books", params: { status: "borrowed" }
      json = JSON.parse(response.body)
      statuses = json["data"].map { |b| b["status"] }
      expect(statuses).to all(eq("borrowed"))
    end
  end

  describe "GET /books/:id" do
    let(:book) { create(:book) }

    it "returns book details with paginated loans" do
      create_list(:loan, 3, book: book)
      get "/books/#{book.serial_number}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["serial_number"]).to eq(book.serial_number)
      expect(json["loans"].size).to eq(3)
      expect(json["loans_meta"]).to include(
        "current_page" => 1,
        "total_count" => 3
      )
    end

    it "returns 404 for unknown book" do
      get "/books/999999"
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Book not found")
    end
  end

  describe "POST /books" do
    let(:valid_params) { { book: { title: "Dune", author: "Frank Herbert" } } }

    it "creates a book with generated serial_number" do
      post "/books", params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["serial_number"]).to match(/\A\d{6}\z/)
      expect(json["title"]).to eq("Dune")
      expect(json["status"]).to eq("available")
    end

    it "rejects manual serial_number" do
      post "/books", params: { book: { serial_number: "999999", title: "X", author: "Y" } }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to include("serial_number")
    end

    it "returns 422 for invalid params" do
      post "/books", params: { book: { title: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "DELETE /books/:id" do
    let(:book) { create(:book) }

    it "deletes available book" do
      delete "/books/#{book.serial_number}"
      expect(response).to have_http_status(:no_content)
      expect(Book.exists?(book.id)).to be false
    end

    it "returns 409 when book is borrowed" do
      create(:loan, book: book)
      delete "/books/#{book.serial_number}"
      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["error"]).to include("borrowed")
    end
  end
end
