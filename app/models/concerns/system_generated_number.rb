# Number genereted with Postgres sequence.
module SystemGeneratedNumber
  extend ActiveSupport::Concern

  included do
    before_create :assign_system_generated_number
  end

  class_methods do
    def system_generated_number(field)
      @system_generated_number_field = field

      define_method("#{field}=") do |_value|
        # no operation
      end
    end

    def system_generated_number_field
      @system_generated_number_field
    end
  end

  private

  def assign_system_generated_number
    field = self.class.system_generated_number_field
    return unless field

    value = self.class.connection.select_value(
      "SELECT lpad(nextval('#{sequence_name_for(field)}')::text, 6, '0')"
    )
    write_attribute(field, value)
  rescue ActiveRecord::StatementInvalid => e
    errors.add(field, "could not be generated: #{e.message}")
    throw :abort
  end

  def sequence_name_for(field)
    table = self.class.table_name

    "#{table}_#{field}_seq"
  end
end
