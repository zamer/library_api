# spec/factories/readers.rb
FactoryBot.define do
  factory :reader do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
  end
end
