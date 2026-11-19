class ApplicationPresenter
  def self.collection(models, **options)
    models.map { |m| new(m, **options).as_json }
  end
end
