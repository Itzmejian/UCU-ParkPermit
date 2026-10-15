/// When true, only @ucu.edu.ph emails can register. Any valid email is
/// accepted now, so this is false.
const bool kRequireUcuEmail = false;
const String kUcuEmailDomain = 'ucu.edu.ph';

/// Email verification code.
const int kOtpLength = 6;
const int kOtpResendSeconds = 30;

/// TESTING ONLY: the code the app accepts until Supabase sends real codes.
/// Remove these two lines when the backend is connected.
const String kDevOtp = '123456';
const bool kShowDevOtpHint = true;

/// TESTING ONLY: shows a status switcher on the Home tab so every state can
/// be previewed. Set to false (or remove) when the backend is connected.
const bool kShowDevTools = true;