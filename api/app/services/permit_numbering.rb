# Permit numbers are the department's external identifier and run in a single
# sequence per calendar year, matching the paper series the counter still keeps.
class PermitNumbering
  PREFIX = 'BP'.freeze

  def self.next_number
    year = Time.zone.now.year
    latest = PermitApplication
             .where("permit_number LIKE ?", "#{PREFIX}-#{year}-%")
             .maximum(:permit_number)

    sequence = latest ? latest.split('-').last.to_i : 0
    format("#{PREFIX}-%<year>d-%<sequence>05d", year: year, sequence: sequence + 1)
  end
end
