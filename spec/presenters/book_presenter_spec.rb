# spec/presenters/book_presenter_spec.rb
require "rails_helper"

RSpec.describe BookPresenter do
  let(:book) do
    build_stubbed(:book, title: "Dune", author: "Frank Herbert").tap do |b|
      allow(b).to receive(:serial_number).and_return("000001")
    end
  end

  describe "#as_json" do
    it "returns available book JSON" do
      json = described_class.new(book, current_loan: nil).as_json

      expect(json).to include(
        serial_number: "000001",
        title: "Dune",
        author: "Frank Herbert",
        status: "available",
        current_loan: nil
      )
    end

    it "returns borrowed book JSON with current_loan" do
      loan = build_stubbed(:loan, book: book)
      json = described_class.new(book, current_loan: loan).as_json

      expect(json[:status]).to eq("borrowed")
      expect(json[:current_loan]).to include(:borrowed_at, :due_at, :reader)
    end
  end
end
