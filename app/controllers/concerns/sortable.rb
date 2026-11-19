# app/controllers/concerns/sortable.rb
module Sortable
  extend ActiveSupport::Concern

  private

  # collection — ActiveRecord::Relation
  # allowed — Hash: { "param_value" => "column_name" }
  # default_sort — String, default_order — "asc"/"desc"
  def apply_sort(collection, allowed:, default_sort:, default_order: "asc")
    sort = params[:sort].to_s
    order = params[:order].to_s.downcase

    column = allowed[sort] || default_sort
    direction = %w[asc desc].include?(order) ? order : default_order

    collection.order(column => direction)
  end
end
