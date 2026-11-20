class Todo < ApplicationRecord
  attribute :completed, :boolean, default: false
  validates :title, presence: true, length: { maximum: 120 }
  scope :incomplete, -> { where(completed: false) }
  scope :complete, -> { where(completed: true) }
end
