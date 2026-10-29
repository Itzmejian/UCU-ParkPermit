// Colleges and offices of Urdaneta City University, for the employee
// Department / Office dropdown.
// TO CONFIRM: only CTE and the Graduate School (IGAS) were confirmed from
// ucu.edu.ph. Check the rest with the university and edit this file.

const String kOtherDepartment = 'Other (type it)';

/// Must match the "Instructor / Faculty" option of the Employee Type list.
const String kFacultyType = 'Instructor / Faculty';

/// For instructors and faculty. The short name is saved.
const Map<String, String> kUcuColleges = {
  'CTE': 'College of Teacher Education',
  'IGAS': 'Institute of Graduate and Advanced Studies (Graduate School)',
  'CBA': 'College of Business and Accountancy',
  'CAS': 'College of Arts and Sciences',
  'CON': 'College of Nursing',
  'COM': 'College of Midwifery',
  'COP': 'College of Pharmacy',
  'CHTM': 'College of Hospitality and Tourism Management',
  'CEA': 'College of Engineering and Architecture',
  'CCS': 'College of Computer Studies',
  'CCJE': 'College of Criminal Justice Education',
  'COL': 'College of Law',
};

/// For staff. The full name is saved.
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