/// Programs offered at Urdaneta City University, shown in the Course dropdown.
/// Edit this list if the university adds or renames a program.
const String kOtherProgram = 'Other (type your course)';

const List<String> kUcuUndergraduatePrograms = [
  'BSAC - Bachelor of Science in Accountancy',
  'BSBA - Bachelor of Science in Business Administration',
  'BSOA - Bachelor of Science in Office Administration',
  'BACOM - Bachelor of Arts in Communication',
  'BEED - Bachelor of Elementary Education',
  'BEECE - Bachelor of Early Childhood Education',
  'BSNE - Bachelor of Special Needs Education',
  'BSEd - Bachelor of Secondary Education',
  'BPEd - Bachelor of Physical Education',
  'BEd (CA) - Bachelor of Culture and Arts Education',
  'BSP - Bachelor of Science in Psychology',
  'BSN - Bachelor of Science in Nursing',
  'BSW - Bachelor of Science in Social Work',
  'BSM - Bachelor of Science in Midwifery',
  'BSPharm - Bachelor of Science in Pharmacy',
  'BSHM - Bachelor of Science in Hospitality Management',
  'BSTM - Bachelor of Science in Tourism Management',
  'BSA - Bachelor of Science in Architecture',
  'BSCPE - Bachelor of Science in Computer Engineering',
  'BSEE - Bachelor of Science in Electrical Engineering',
  'BSCE - Bachelor of Science in Civil Engineering',
  'BSECE - Bachelor of Science in Electronics Engineering',
  'BSIT - Bachelor of Science in Information Technology',
  'BLIS - Bachelor of Library and Information Science',
  'BSCrim - Bachelor of Science in Criminology',
];

const List<String> kUcuGraduatePrograms = [
  'Ed.D. - Doctor of Education',
  'MA.Ed. - Master of Arts in Education',
  'MA in ECE - Master of Arts in Early Childhood Education',
  'MA in SpEd - Master of Arts in Special Education',
  'MBA - Master in Business Administration',
  'MPA - Master in Public Administration',
  'MAN - Master of Arts in Nursing',
  'JD - Juris Doctor',
];

final List<String> kUcuProgramOptions = [
  ...kUcuUndergraduatePrograms,
  ...kUcuGraduatePrograms,
  kOtherProgram,
];