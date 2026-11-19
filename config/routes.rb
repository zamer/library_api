Rails.application.routes.draw do
  resources :books, only: %i[index show create destroy], param: :id do
    resources :loans, only: :create
  end

  patch "loans/:id/return", to: "loans#return", as: :return_loan
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
