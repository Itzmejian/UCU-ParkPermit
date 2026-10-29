/// When true, only @ucu.edu.ph emails can register. Any valid email is
/// accepted now, so this is false.
const bool kRequireUcuEmail = false;
const String kUcuEmailDomain = 'ucu.edu.ph';

/// Email verification code.
const int kOtpLength = 6;
const int kOtpResendSeconds = 60;

/// TESTING ONLY (prototype mode): the code accepted while the app is not
/// connected to Supabase.
const String kDevOtp = '123456';
const bool kShowDevOtpHint = true;

/// TESTING ONLY: shows a status switcher on the Home tab so every state can
/// be previewed. Set to false (or remove) when the backend is connected.
const bool kShowDevTools = true;