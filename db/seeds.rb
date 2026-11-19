Reader.find_or_create_by!(email: "john@example.com") do |r|
  r.full_name = "John Doe"
end

Book.find_or_create_by!(title: "The Witcher", author: "Andrzej Sapkowski")
