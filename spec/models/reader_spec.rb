# spec/models/reader_spec.rb
require "rails_helper"

RSpec.describe Reader, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:loans).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { create(:reader) }

    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe ".find_by_identifier" do
    let!(:reader) { create(:reader, email: "jan@example.com") }

    it "finds by card_number" do
      expect(described_class.find_by_identifier(card_number: reader.card_number)).to eq(reader)
    end

    it "finds by email" do
      expect(described_class.find_by_identifier(email: "jan@example.com")).to eq(reader)
    end

    it "prioritizes card_number over email" do
      result = described_class.find_by_identifier(
        card_number: reader.card_number,
        email: "other@example.com"
      )
      expect(result).to eq(reader)
    end

    it "returns nil when no identifier given" do
      expect(described_class.find_by_identifier).to be_nil
    end

    it "returns nil when not found" do
      expect(described_class.find_by_identifier(card_number: "999999")).to be_nil
    end
  end

  describe "card_number generation" do
    it "generates card_number on create" do
      reader = create(:reader)
      expect(reader.card_number).to match(/\A\d{6}\z/)
    end
  end
end
