# Production Setup Guide

## Environment Configuration

### 1. Environment Variables Setup

The application uses environment variables to securely manage Supabase credentials. Follow these steps:

#### Create `.env` file
Copy the `.env.example` file to create your `.env` file:
```bash
cp .env.example .env
```

#### Configure Credentials
Edit the `.env` file and add your Supabase credentials:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Important:** 
- Never commit the `.env` file to version control (already in `.gitignore`)
- Keep your credentials secure and rotate them periodically
- Use different credentials for development, staging, and production environments

### 2. Install Dependencies

Run the following command to install all required packages:
```bash
flutter pub get
```

### 3. Verify Configuration

The app will automatically validate environment variables on startup. If any required variables are missing or empty, you'll see a clear error message on the screen.

## Pre-Production Checklist

### Security
- [ ] Environment variables are properly configured
- [ ] `.env` file is in `.gitignore`
- [ ] Supabase Row Level Security (RLS) policies are enabled
- [ ] API keys are rotated and secured
- [ ] Authentication flows are tested

### Code Quality
- [ ] All lint warnings are addressed
- [ ] No hardcoded credentials in codebase
- [ ] Error handling is implemented for all critical paths
- [ ] Loading states are shown for async operations

### Testing
- [ ] Test login/signup flows
- [ ] Test user and admin dashboards
- [ ] Test pathway assignments and quiz functionality
- [ ] Test on multiple devices (iOS, Android, Web)
- [ ] Test offline behavior and error scenarios

### Performance
- [ ] Images and assets are optimized
- [ ] Database queries are efficient with proper indexes
- [ ] App startup time is acceptable
- [ ] Memory usage is monitored

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Environment-Specific Configurations

For different environments (dev, staging, prod), create separate `.env` files:
- `.env.development`
- `.env.staging`
- `.env.production`

Load the appropriate file based on your build configuration.

## Monitoring and Logging

### Production Logging
Consider implementing:
- Crash reporting (e.g., Sentry, Firebase Crashlytics)
- Analytics tracking (e.g., Firebase Analytics, Mixpanel)
- Performance monitoring
- User feedback mechanisms

### Error Handling
The app includes:
- Graceful error screens for configuration issues
- Validation of environment variables on startup
- User-friendly error messages

## Deployment

### App Store (iOS)
1. Configure signing in Xcode
2. Build release version
3. Upload to App Store Connect
4. Submit for review

### Google Play (Android)
1. Generate signed APK/Bundle
2. Upload to Google Play Console
3. Complete store listing
4. Submit for review

### Web Hosting
1. Build web version
2. Deploy to hosting service (Firebase Hosting, Netlify, Vercel)
3. Configure custom domain
4. Enable HTTPS

## Maintenance

### Regular Tasks
- Monitor error logs and crash reports
- Update dependencies regularly
- Review and rotate API keys
- Backup database regularly
- Monitor app performance metrics

### Updates
When updating the app:
1. Test thoroughly in staging environment
2. Update version number in `pubspec.yaml`
3. Create release notes
4. Deploy to production
5. Monitor for issues post-deployment

## Support

For issues or questions:
- Check Supabase dashboard for API status
- Review application logs
- Test with different network conditions
- Verify environment variables are correctly set

## Security Best Practices

1. **Never expose sensitive data in logs**
2. **Use HTTPS for all API calls** (Supabase does this by default)
3. **Implement proper authentication checks**
4. **Validate all user inputs**
5. **Keep dependencies updated**
6. **Use Supabase RLS policies** for data access control
7. **Implement rate limiting** where appropriate
8. **Regular security audits**
