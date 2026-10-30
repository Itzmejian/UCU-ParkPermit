// Colleges and offices of Urdaneta City University, for the employee
// Department / Office dropdown.
// Colleges: official list from UCU. Offices: draft, confirm with the university.

const String kOtherDepartment = 'Other (type it)';

/// Must match the "Instructor / Faculty" option of the Employee Type list.
const String kFacultyType = 'Instructor / Faculty';

/// For instructors and faculty. The short name is saved.
const Map<String, String> kUcuColleges = {
  'COL': 'College of Law',
  'COP': 'College of Pharmacy',
  'CHS': 'College of Health Sciences',
  'CAS': 'College of Arts and Sciences',
  'CCJE': 'College of Criminal Justice Education',
  'CTE': 'College of Teacher Education',
  'CHUS': 'College of Human Sciences',
  'CEA': 'College of Engineering and Architecture',
  'CBMA': 'College of Business Management and Accountancy',
  'CITE': 'College of Information and Technology Education',
  'CHTM': 'College of Hospitality and Tourism Management',
  'GS': 'Graduate School',
};

/// For staff. The full name is saved. DRAFT: confirm with the university.
const List<String> kUcuOffices = [
  'Office of the President',
  'Office of the Vice President for Academic Affairs',
  "Registrar's Office",
  'Admission Office',
  'Accounting Office',
  "Cashier's Office",
  'Budget Office',
  'Human Resource Office',
  'Library',
  'Guidance and Counseling Office',
  'Medical and Dental Clinic',
  'Office of Student Affairs',
  'Campus Security Office',
  'MIS / IT Office',
  'Research Office',
  'Extension Office',
  'Supply and Property Office',
  'General Services Office',
];

bool isFacultyType(String employeeType) => employeeType == kFacultyType;

/// The options for the chosen employee type. Empty if no type is chosen yet.
List<String> departmentOptions(String employeeType) {
  if (employeeType.trim().isEmpty) return const <String>[];
  return [
    ...(isFacultyType(employeeType) ? kUcuColleges.keys : kUcuOffices),
    kOtherDepartment,
  ];
}

/// Full names shown under the short college names. None for offices.
Map<String, String>? departmentSubtitles(String employeeType) {
  return isFacultyType(employeeType) ? kUcuColleges : null;
}