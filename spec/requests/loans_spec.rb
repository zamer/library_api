# spec/requests/loans_spec.rb
require "rails_helper"

RSpec.describe "Loans API", type: :request do
  let(:book) { create(:book) }
  let(:reader) { create(:reader, card_number: "000001", email: "jan@example.com") }

  describe "POST /books/:book_id/loans" do
    it "creates loan by card_number" do
      post "/books/#{book.serial_number}/loans",
           params: { card_number: reader.card_number }, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["id"]).to be_present
      expect(json["reader"]["card_number"]).to eq(reader.card_number)
      expect(json["due_at"]).to be_present
    end

    it "creates loan by email" do
      post "/books/#{book.serial_number}/loans",
           params: { email: reader.email }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "returns 404 when book not found" do
      post "/books/999999/loans", params: { card_number: reader.card_number }, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when reader not found" do
      post "/books/#{book.serial_number}/loans", params: { card_number: "999999" }, as: :json
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
    end
  end

  describe "PATCH /loans/:id/return" do
    let(:loan) { create(:loan, book: book, reader: reader) }

    it "returns the book" do
      patch "/loans/#{loan.id}/return"
      expect(response).to have_http_status(:ok)
      expect(loan.reload.returned_at).to be_present
    end

    it "returns 404 for unknown loan" do
      patch "/loans/999999/return"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 409 when already returned" do
      loan.update!(returned_at: Time.current)
      patch "/loans/#{loan.id}/return"
      expect(response).to have_http_status(:conflict)
    end
  end
end
