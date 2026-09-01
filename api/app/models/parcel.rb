class Parcel < ApplicationRecord
  has_many :permit_applications, dependent: :restrict_with_exception

  validates :apn, :street_address, :postal_code, :district, :zone_code, presence: true

  def self.resolve(address)
    return nil if address.blank?

    where('lower(street_address) = ?', address.to_s.strip.downcase).first
  end

  def self.search_by_address(fragment)
    where('street_address ILIKE ?', "%#{sanitize_sql_like(fragment.to_s.strip)}%")
      .order(:street_address)
      .limit(20)
  end

  def display_address
    "#{street_address}, #{city} #{postal_code}"
  end
end
