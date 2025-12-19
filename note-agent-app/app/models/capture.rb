class Capture < ApplicationRecord
  belongs_to :user
  belongs_to :template, optional: true

  # Explicitly declare the attribute type for enum
  attribute :status, :integer, default: 0

  # Set JSON defaults at the application level
  attribute :tags, :json, default: []
  attribute :metadata, :json, default: {}

  # Status enum matching your pipeline
  enum :status, {
    pending: 0,
    processing: 1,
    summarizing: 2,
    enriching: 3,
    formatting: 4,
    published: 5,
    failed: 6
  }, prefix: true

  validates :content, presence: true
  validates :content_type, presence: true
  validates :status, presence: true

  # Scopes for filtering
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Default values
  after_initialize :set_defaults, if: :new_record?

  def successful?
    status_published?
  end

  def processing?
    status_processing? || status_summarizing? || status_enriching? || status_formatting?
  end

  private

  def set_defaults
    self.tags ||= []
    self.metadata ||= {}
    self.obsidian_folder ||= "Captures"
  end
end
