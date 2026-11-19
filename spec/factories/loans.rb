# spec/factories/loans.rb
FactoryBot.define do
  factory :loan do
    association :book
    association :reader
    borrowed_at { Time.current }

    trait :returned do
      returned_at { Time.current }
    end

    trait :due_in_3_days do
      due_at { 3.days.from_now }
    end

    trait :due_today do
      due_at { Time.current }
    end
  end
end
