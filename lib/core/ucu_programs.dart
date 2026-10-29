// Programs offered at Urdaneta City University (ucu.edu.ph, Courses Offered).
// The short name is what is saved and shown. The full name only helps searching.
// Edit this list if the university adds or renames a program.

/// Not shown in the dropdown anymore. Kept so older code still compiles.
const String kOtherProgram = 'Other (type your course)';

const Map<String, String> kUcuUndergraduatePrograms = {
  'BSAC': 'Bachelor of Science in Accountancy',
  'BSBA-FM': 'Business Administration, Major in Financial Management',
  'BSBA-HRM': 'Business Administration, Major in Human Resource Management',
  'BSBA-MM': 'Business Administration, Major in Marketing Management',
  'BSBA-MA': 'Business Administration, Major in Management Accounting',
  'BSOA': 'Bachelor of Science in Office Administration',
  'BACOM': 'Bachelor of Arts in Communication',
  'BEED': 'Bachelor of Elementary Education',
  'BEECE': 'Bachelor of Early Childhood Education',
  'BSNE': 'Bachelor of Special Needs Education',
  'BSEd-English': 'Bachelor of Secondary Education, Major in English',
  'BSEd-Filipino': 'Bachelor of Secondary Education, Major in Filipino',
  'BSEd-Math': 'Bachelor of Secondary Education, Major in Mathematics',
  'BSEd-Science': 'Bachelor of Secondary Education, Major in Science',
  'BSEd-SS': 'Bachelor of Secondary Education, Major in Social Studies',
  'BPEd': 'Bachelor of Physical Education',
  'BEd (CA)': 'Bachelor of Culture and Arts Education',
  'BSP': 'Bachelor of Science in Psychology',
  'BSN': 'Bachelor of Science in Nursing',
  'BSW': 'Bachelor of Science in Social Work',
  'BSM': 'Bachelor of Science in Midwifery',
  'BSPharm': 'Bachelor of Science in Pharmacy',
  'BSHM': 'Bachelor of Science in Hotel Management',
  'BSTM': 'Bachelor of Science in Tourism Management',
  'BSA': 'Bachelor of Science in Architecture',
  'BSCE': 'Bachelor of Science in Civil Engineering',
  'BSEE': 'Bachelor of Science in Electrical Engineering',
  'BSCPE': 'Bachelor of Science in Computer Engineering',
  'BSECE': 'Bachelor of Science in Electronics Engineering',
  'BSIT': 'Bachelor of Science in Information Technology',
  'BLIS': 'Bachelor in Library and Information Science',
  'BSCrim': 'Bachelor of Science in Criminology',
};

const Map<String, String> kUcuGraduatePrograms = {
  'Ed.D.': 'Doctor of Education, Major in Educational Management',
  'MA.Ed.': 'Master of Arts in Education, Major in Educational Management',
  'MA in ECE': 'Master of Arts in Early Childhood Education',
  'MA in SpEd': 'Master of Arts in Special Education',
  'MBA': 'Master in Business Administration',
  'MPA': 'Master in Public Administration',
  'MAN': 'Master of Arts in Nursing',
  'JD': 'Juris Doctor',
};

/// Short name to full name, for every program.
final Map<String, String> kUcuProgramNames = {
  ...kUcuUndergraduatePrograms,
  ...kUcuGraduatePrograms,
};

/// The short names shown in the dropdown.
final List<String> kUcuProgramOptions = kUcuProgramNames.keys.toList();