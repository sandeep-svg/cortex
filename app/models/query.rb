class Query < ApplicationRecord
  belongs_to :provider, optional: true
  belongs_to :document, optional: true
  belongs_to :user, optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: "completed") }
end
