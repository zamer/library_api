# spec/models/book_spec.rb
require "rails_helper"

RSpec.describe Book, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:loans).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:author) }
  end

  describe "#current_loan" do
    let(:book) { create(:book) }

    it "returns nil when book has no loans" do
      expect(book.current_loan).to be_nil
    end

    it "returns the active loan" do
      loan = create(:loan, book: book)
      expect(book.current_loan).to eq(loan)
    end

    it "returns nil when all loans are returned" do
      create(:loan, :returned, book: book)
      expect(book.current_loan).to be_nil
    end

    it "returns the most recent active loan" do
      old_loan = create(:loan, book: book, borrowed_at: 2.days.ago)
      new_loan = create(:loan, book: book, borrowed_at: 1.day.ago)
      expect(book.current_loan).to eq(new_loan)
    end
  end

  describe "#borrowed?" do
    let(:book) { create(:book) }

    it "returns true when book has active loan" do
      create(:loan, book: book)
      expect(book.borrowed?).to be true
    end

    it "returns false when book has no active loan" do
      expect(book.borrowed?).to be false
    end
  end

  describe "#available?" do
    let(:book) { create(:book) }

    it "returns true when no active loan" do
      expect(book.available?).to be true
    end

    it "returns false when book is borrowed" do
      create(:loan, book: book)
      expect(book.available?).to be false
    end
  end

  describe "serial_number generation" do
    it "generates serial_number on create" do
      book = create(:book)
      expect(book.serial_number).to match(/\A\d{6}\z/)
    end

    it "generates sequential serial_numbers" do
      book1 = create(:book)
      book2 = create(:book)
      expect(book2.serial_number.to_i).to eq(book1.serial_number.to_i + 1)
    end

    it "ignores manual serial_number assignment" do
      book = Book.new(serial_number: "999999", title: "X", author: "Y")
      book.save!
      expect(book.serial_number).not_to eq("999999")
    end
  end
end
