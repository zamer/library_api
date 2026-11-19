# app/controllers/concerns/paginatable.rb
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  private

  def paginate(collection)
    collection.page(params[:page]).per(per_page_param)
  end

  def per_page_param
    value = params[:per_page].to_i
    return DEFAULT_PER_PAGE if value <= 0

    [ value, MAX_PER_PAGE ].min
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      per_page: collection.limit_value,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
