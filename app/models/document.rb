class Document < ApplicationRecord
  has_one_attached :file
  has_many :chunks, dependent: :destroy
  has_many :queries, dependent: :nullify

  validates :file, presence: true

  STATUSES = %w[queued processing completed failed].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: "completed") }

  def filename
    file.filename.to_s
  end

  def file_size_human
    return "-" unless file_size
    ActiveSupport::NumberHelper.number_to_human_size(file_size)
  end

  def processed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end
end
