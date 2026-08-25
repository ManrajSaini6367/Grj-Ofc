enum ContractorStatus { published, unpublished }

class LabourContractor {
  const LabourContractor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.masonRatePerDay,
    required this.beldarRatePerDay,
    required this.coolieRatePerDay,
    required this.masonOtRatePerHour,
    required this.beldarOtRatePerHour,
    required this.coolieOtRatePerHour,
    this.status = ContractorStatus.published,
    this.agreements = const [],
    this.documents = const [],
    this.cancelCheque,
  });

  final String id;
  final String name;
  final String mobile;
  final String address;
  final double masonRatePerDay;
  final double beldarRatePerDay;
  final double coolieRatePerDay;
  final double masonOtRatePerHour;
  final double beldarOtRatePerHour;
  final double coolieOtRatePerHour;
  final ContractorStatus status;
  final List<String> agreements;
  final List<String> documents;
  final String? cancelCheque;
}

const kMockContractors = [
  LabourContractor(
    id: 'CON-2001',
    name: 'Rajesh Labour Contractors',
    mobile: '+91 98765 11122',
    address: 'Site Office, Skyline Towers, Pune',
    masonRatePerDay: 850,
    beldarRatePerDay: 650,
    coolieRatePerDay: 500,
    masonOtRatePerHour: 120,
    beldarOtRatePerHour: 95,
    coolieOtRatePerHour: 75,
  ),
  LabourContractor(
    id: 'CON-2002',
    name: 'Sharma Workforce Agency',
    mobile: '+91 91234 33344',
    address: 'Plot 18, MIDC Area, Nashik',
    masonRatePerDay: 900,
    beldarRatePerDay: 700,
    coolieRatePerDay: 520,
    masonOtRatePerHour: 130,
    beldarOtRatePerHour: 100,
    coolieOtRatePerHour: 80,
    status: ContractorStatus.unpublished,
  ),
  LabourContractor(
    id: 'CON-2003',
    name: 'National Build Labour Co.',
    mobile: '+91 99887 55566',
    address: 'Ring Road, Bengaluru',
    masonRatePerDay: 920,
    beldarRatePerDay: 720,
    coolieRatePerDay: 540,
    masonOtRatePerHour: 135,
    beldarOtRatePerHour: 105,
    coolieOtRatePerHour: 85,
  ),
];
