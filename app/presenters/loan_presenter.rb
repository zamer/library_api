class LoanPresenter < ApplicationPresenter
  def initialize(loan)
    @loan = loan
  end

  def as_json
    {
      id: @loan.id,
      borrowed_at: @loan.borrowed_at,
      due_at: @loan.due_at,
      returned_at: @loan.returned_at,
      reader: ReaderPresenter.new(@loan.reader).as_json
    }
  end
end
