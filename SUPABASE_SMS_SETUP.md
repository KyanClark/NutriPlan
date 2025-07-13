# Supabase SMS OTP Verification Setup Guide

This guide will help you set up SMS OTP verification using Supabase's built-in phone authentication.

## Prerequisites

1. A Supabase project
2. Phone authentication enabled in Supabase
3. A valid phone number for testing

## Setup Steps

### 1. Enable Phone Authentication in Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Authentication** > **Providers**
4. Find **Phone Auth** and enable it
5. Configure the following settings:
   - **Enable phone confirmations**: Turn this ON
   - **Message template**: Customize the SMS message (optional)
   - **Rate limiting**: Set appropriate limits

### 2. Configure SMS Provider

Supabase supports multiple SMS providers:

#### Option A: Twilio (Recommended)
1. Sign up for a [Twilio account](https://www.twilio.com/)
2. Get your Account SID and Auth Token
3. In Supabase Dashboard, go to **Settings** > **Auth** > **SMS Provider**
4. Select **Twilio** and enter your credentials

#### Option B: MessageBird
1. Sign up for a [MessageBird account](https://messagebird.com/)
2. Get your API key
3. Configure in Supabase as above

#### Option C: Vonage (formerly Nexmo)
1. Sign up for a [Vonage account](https://vonage.com/)
2. Get your API key and secret
3. Configure in Supabase as above

### 3. Test Phone Numbers

For development, you can use test phone numbers:
- **Twilio**: +15005550006 (always succeeds)
- **MessageBird**: +31612345678 (test number)
- **Vonage**: +447911123456 (test number)

### 4. Update Your App

The app is already configured to use Supabase phone authentication. The flow works as follows:

1. User enters email, password, full name, and phone number
2. App navigates to phone verification screen
3. Supabase sends OTP to the provided phone number
4. User enters the 6-digit OTP code
5. Upon successful verification, account is created in Supabase
6. User is redirected to login screen

## How It Works

### Signup Flow:
1. **Form Validation**: Email, password, full name, and phone number validation
2. **Phone Verification**: Supabase sends OTP via SMS
3. **OTP Verification**: User enters the code received via SMS
4. **Account Creation**: After phone verification, email account is created
5. **Email Verification**: User still needs to verify email (optional step)

### Features:
- **Phone Number Validation**: Basic regex validation for phone numbers
- **Auto OTP Sending**: Automatically sends OTP when verification screen loads
- **Manual OTP Entry**: Users can manually enter the 6-digit OTP code
- **Resend Functionality**: 60-second cooldown timer for resending OTP
- **Error Handling**: Comprehensive error messages for various scenarios
- **Single Database**: Everything stays in Supabase

## Testing

### Development Testing:
1. Use test phone numbers provided by your SMS provider
2. These numbers will always receive OTP codes without actual SMS charges
3. Perfect for development and testing

### Production Testing:
1. Use real phone numbers
2. Ensure proper country code format (e.g., +1234567890)
3. Test on different devices and platforms

## Troubleshooting

### Common Issues:

1. **"Invalid phone number format"**
   - Ensure phone number includes country code (e.g., +1234567890)
   - Remove any special characters except +, -, (, )

2. **"Rate limit exceeded"**
   - Wait before trying again
   - Check Supabase rate limiting settings

3. **"SMS provider error"**
   - Check SMS provider credentials in Supabase
   - Verify account balance with SMS provider
   - Check SMS provider logs

### Debug Tips:

1. Check Supabase logs in the dashboard
2. Verify phone authentication is enabled
3. Test with provider's test phone numbers
4. Check network connectivity

## Security Notes

- Phone numbers are stored in Supabase user metadata
- Supabase handles OTP generation and verification
- No sensitive data is stored locally
- OTP codes expire automatically
- Rate limiting prevents abuse

## Production Considerations

1. **Rate Limiting**: Configure appropriate limits in Supabase
2. **Phone Number Validation**: Add more robust validation
3. **Error Handling**: Implement comprehensive error handling
4. **Analytics**: Monitor OTP success/failure rates
5. **Backup Verification**: Consider email verification as backup
6. **SMS Costs**: Monitor SMS costs with your provider

## Cost Considerations

- **Twilio**: ~$0.0075 per SMS (US numbers)
- **MessageBird**: ~$0.05 per SMS
- **Vonage**: ~$0.06 per SMS

Choose based on your target regions and volume.

## Support

For issues related to:
- Supabase setup: Check Supabase documentation
- SMS provider: Check provider's documentation
- App-specific issues: Check the app logs and Supabase Console

## Advantages of Supabase Phone Auth

1. **Single Database**: Everything in one place
2. **No External Dependencies**: No Firebase needed
3. **Built-in Security**: Rate limiting, validation, etc.
4. **Cross-platform**: Works on all platforms
5. **Cost Effective**: Pay only for SMS, no additional service fees
6. **Easy Setup**: Minimal configuration required 