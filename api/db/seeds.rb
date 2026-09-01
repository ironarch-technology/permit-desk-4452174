# Development fixtures: the parcels the counter uses for training, two portal
# accounts, and a handful of applications spread across the pipeline.

PARCELS = [
  ['041-220-118', '1420 Kestrel Lane',       '19714', 'central',   'R-1',  'M. Okonkwo'],
  ['041-220-119', '1424 Kestrel Lane',       '19714', 'central',   'R-1',  'D. Halvorsen'],
  ['038-104-052', '77 Weatherby Road',       '19716', 'north',     'R-2',  'Weatherby Trust'],
  ['052-611-004', '2900 Old Mill Turnpike',  '19722', 'south',     'C-2',  'Old Mill Holdings LLC'],
  ['052-611-009', '2914 Old Mill Turnpike',  '19722', 'south',     'C-2',  'Vance Property Co'],
  ['061-330-771', '18 Sequoia Court',        '19718', 'west',      'R-1',  'A. Baptiste'],
  ['061-330-772', '22 Sequoia Court',        '19718', 'west',      'R-1',  'R. Nakamura'],
  ['027-882-140', '505 Harbormaster Way',    '19711', 'waterfront','MU-3', 'Mountport Harbor Commission'],
  ['027-882-141', '509 Harbormaster Way',    '19711', 'waterfront','MU-3', 'Tidewater Partners'],
  ['044-190-306', '860 Ashgrove Avenue',     '19715', 'central',   'R-3',  'Ashgrove Commons HOA'],
  ['044-190-307', '864 Ashgrove Avenue',     '19715', 'central',   'R-3',  'L. Ferreira'],
  ['019-455-023', '3 Pennyroyal Bend',       '19719', 'north',     'AG-1', 'Pennyroyal Farm Inc']
].freeze

PARCELS.each do |apn, address, postal, district, zone, owner|
  Parcel.find_or_create_by!(apn: apn) do |parcel|
    parcel.street_address = address
    parcel.postal_code = postal
    parcel.district = district
    parcel.zone_code = zone
    parcel.owner_name = owner
  end
end

applicant = Account.find_or_create_by!(email: 'r.nakamura@example.com') do |account|
  account.full_name = 'Rina Nakamura'
  account.role = 'applicant'
  account.phone = '302-555-0148'
  account.password = 'portal-demo-2025'
end

contractor = Account.find_or_create_by!(email: 'ops@baywoodbuilders.example') do |account|
  account.full_name = 'Baywood Builders'
  account.role = 'applicant'
  account.phone = '302-555-0912'
  account.password = 'portal-demo-2025'
end

Account.find_or_create_by!(email: 't.arriaga@mountport.gov.example') do |account|
  account.full_name = 'Tomas Arriaga'
  account.role = 'technician'
  account.phone = '302-555-0100'
  account.password = 'counter-demo-2025'
end

def stage(account, parcel_apn, attrs, state, timeline)
  parcel = Parcel.find_by!(apn: parcel_apn)
  application = account.permit_applications.find_or_initialize_by(reference: attrs.fetch(:reference))
  return application if application.persisted?

  application.assign_attributes(attrs.merge(parcel: parcel, state: state))
  application.save!

  timeline.each_with_index do |(from, to, actor, source, reason), index|
    application.transitions.create!(
      from_state: from,
      to_state: to,
      actor: actor,
      source_system: source,
      reason: reason,
      occurred_at: (timeline.length - index).days.ago
    )
  end

  application
end

stage(
  applicant, '061-330-772',
  {
    reference: 'PA-2026-K3M9QT',
    work_type: 'reroof',
    scope_of_work: 'Tear off and replace asphalt shingle roof, like for like, no structural change.',
    declared_valuation_cents: 18_400_00,
    applicant_name: 'Rina Nakamura',
    applicant_email: 'r.nakamura@example.com',
    applicant_phone: '302-555-0148',
    submitted_at: 6.days.ago
  },
  'plan_review',
  [
    ['draft', 'submitted', 'account:1', 'permit-desk', 'submitted by applicant'],
    ['submitted', 'zoning_check', 'permit-desk', 'permit-desk', 'zoning check dispatched'],
    ['zoning_check', 'plan_review', 'zoning-service', 'zoning', 'permissible under R-1']
  ]
)

stage(
  contractor, '052-611-004',
  {
    reference: 'PA-2026-B7WD22',
    work_type: 'commercial_tenant_improvement',
    scope_of_work: 'Interior fit-out of 4,200 sq ft ground floor retail unit. New partitions, ' \
                   'lighting, and accessible restroom. No change to building envelope.',
    declared_valuation_cents: 412_000_00,
    applicant_name: 'Baywood Builders',
    applicant_email: 'ops@baywoodbuilders.example',
    applicant_phone: '302-555-0912',
    contractor_license_number: 'DE-CON-448120',
    contractor_license_expires_on: Date.current + 400,
    submitted_at: 21.days.ago
  },
  'corrections_required',
  [
    ['draft', 'submitted', 'account:2', 'permit-desk', 'submitted by applicant'],
    ['submitted', 'zoning_check', 'permit-desk', 'permit-desk', 'zoning check dispatched'],
    ['zoning_check', 'plan_review', 'zoning-service', 'zoning', 'permissible under C-2'],
    ['plan_review', 'corrections_required', 'plan-reviewer', 'review', '2 correction item(s)']
  ]
).tap do |application|
  next if application.correction_items.any?

  application.correction_items.create!(
    cycle: 0, code: 'ACC-04',
    narrative: 'Restroom clear floor space at the water closet is dimensioned at 54 inches. ' \
               'Provide 60 inches minimum and revise plan sheet A-3.',
    citation: 'ICC A117.1 604.3.1'
  )
  application.correction_items.create!(
    cycle: 0, code: 'EGR-11',
    narrative: 'Exit sign locations are not shown on the reflected ceiling plan. Add locations ' \
               'and photometric coverage for the rear corridor.',
    citation: 'IBC 1013.1'
  )
end

stage(
  applicant, '041-220-118',
  {
    reference: 'PA-2025-Y8LQ04',
    work_type: 'solar_photovoltaic',
    scope_of_work: 'Roof-mounted 7.2 kW photovoltaic array, 18 panels, existing main panel retained.',
    declared_valuation_cents: 31_500_00,
    applicant_name: 'Rina Nakamura',
    applicant_email: 'r.nakamura@example.com',
    applicant_phone: '302-555-0148',
    submitted_at: 95.days.ago,
    permit_number: 'BP-2025-00417',
    issued_at: 70.days.ago,
    valid_until: 110.days.from_now
  },
  'issued',
  [
    ['draft', 'submitted', 'account:1', 'permit-desk', 'submitted by applicant'],
    ['submitted', 'zoning_check', 'permit-desk', 'permit-desk', 'zoning check dispatched'],
    ['zoning_check', 'plan_review', 'zoning-service', 'zoning', 'permissible under R-1'],
    ['plan_review', 'fees_assessed', 'plan-reviewer', 'review', 'plan review approved'],
    ['fees_assessed', 'issued', 'cashiering-service', 'cashiering', 'payment PMT-88213']
  ]
)

stage(
  contractor, '027-882-141',
  {
    reference: 'PA-2026-N4RC81',
    work_type: 'residential_addition',
    scope_of_work: 'Two-storey rear addition, 640 sq ft, on existing slab. New foundation to ' \
                   'match. Parcel record shows a lot line revision that was never recorded.',
    declared_valuation_cents: 268_000_00,
    applicant_name: 'Baywood Builders',
    applicant_email: 'ops@baywoodbuilders.example',
    applicant_phone: '302-555-0912',
    contractor_license_number: 'DE-CON-448120',
    contractor_license_expires_on: Date.current + 400,
    submitted_at: 3.days.ago,
    zoning_check_handle: 'zc-8841207',
    zoning_result: 'indeterminate'
  },
  'zoning_hold',
  [
    ['draft', 'submitted', 'account:2', 'permit-desk', 'submitted by applicant'],
    ['submitted', 'zoning_check', 'permit-desk', 'permit-desk', 'zoning check dispatched'],
    ['zoning_check', 'zoning_hold', 'zoning-service', 'zoning', 'parcel records conflict on lot line']
  ]
)

applicant.permit_applications.find_or_create_by!(reference: 'PA-2026-D2HF55') do |application|
  application.state = 'draft'
  application.parcel = Parcel.find_by!(apn: '044-190-307')
  application.work_type = 'residential_alteration'
  application.scope_of_work = 'Kitchen remodel, relocate sink and dishwasher.'
  application.declared_valuation_cents = 42_000_00
  application.applicant_name = 'Rina Nakamura'
  application.applicant_email = 'r.nakamura@example.com'
  application.applicant_phone = '302-555-0148'
end

puts "parcels=#{Parcel.count} accounts=#{Account.count} applications=#{PermitApplication.count}"
