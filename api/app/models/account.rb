class Account < ApplicationRecord
  has_secure_password

  ROLES = %w[applicant technician].freeze

  has_many :permit_applications, dependent: :restrict_with_exception

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :full_name, presence: true
  validates :role, inclusion: { in: ROLES }

  def technician?
    role == 'technician'
  end
end
