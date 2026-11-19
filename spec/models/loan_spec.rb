# spec/requests/loans_spec.rb
require "rails_helper"

RSpec.describe "Loans API", type: :request do
  let(:book) { create(:book) }
  let(:reader) { create(:reader, email: "jan@example.com") }

  describe "POST /books/:book_id/loans" do
    it "creates loan by card_number" do
      post "/books/#{book.serial_number}/loans",
           params: { card_number: reader.card_number }, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["id"]).to be_present
      expect(json["reader"]["card_number"]).to eq(reader.card_number)
      expect(json["due_at"]).to be_present
      expect(json["returned_at"]).to be_nil
    end

    it "creates loan by email" do
      post "/books/#{book.serial_number}/loans",
           params: { email: reader.email }, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["id"]).to be_present
      expect(json["reader"]["card_number"]).to eq(reader.card_number)
    end

    it "sets due_at to borrowed_at + 30 days" do
      post "/books/#{book.serial_number}/loans",
           params: { card_number: reader.card_number }, as: :json

      json = JSON.parse(response.body)
      borrowed_at = Time.parse(json["borrowed_at"])
      due_at = Time.parse(json["due_at"])
      expect(due_at).to be_within(1.second).of(borrowed_at + 30.days)
    end

    it "returns 404 when book not found" do
      post "/books/999999/loans",
           params: { card_number: reader.card_number }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Book not found")
    end

    it "returns 404 when reader not found" do
      post "/books/#{book.serial_number}/loans",
           params: { card_number: "999999" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Reader not found")
    end

    it "returns 409 when book is already borrowed" do
      create(:loan, book: book)

      post "/books/#{book.serial_number}/loans",
           params: { card_number: reader.card_number }, as: :json

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["error"]).to eq("Book is already borrowed")
    end

    it "returns 400 when no identifier provided" do
      post "/books/#{book.serial_number}/loans", params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to include("card_number or email")
    end

    it "prioritizes card_number over email" do
      other_reader = create(:reader, email: "other@example.com")

      post "/books/#{book.serial_number}/loans",
           params: { card_number: reader.card_number, email: other_reader.email },
           as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["reader"]["card_number"]).to eq(reader.card_number)
    end
  end

  describe "PATCH /loans/:id/return" do
    let(:loan) { create(:loan, book: book, reader: reader) }

    it "returns the book" do
      patch "/loans/#{loan.id}/return"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["returned_at"]).to be_present
      expect(loan.reload.returned_at).to be_present
    end

    it "makes book available again" do
      patch "/loans/#{loan.id}/return"
      get "/books/#{book.serial_number}"
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("available")
    end

    it "returns 404 for unknown loan" do
      patch "/loans/999999/return"
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Loan not found")
    end

    it "returns 409 when already returned" do
      loan.update!(returned_at: Time.current)

      patch "/loans/#{loan.id}/return"

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["error"]).to eq("Loan already returned")
    end
  end
end
