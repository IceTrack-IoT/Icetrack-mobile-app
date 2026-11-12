import 'package:url_launcher/url_launcher.dart';

/// Opens the Google Maps directions URL built by the backend (`navigation_url`)
/// in the Maps app, or in the browser when Maps is not installed (US-47).
Future<bool> openNavigation(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Builds a directions URL from coordinates when the site has no `navigation_url`.
String directionsUrl(double latitude, double longitude) =>
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

/// Opens the phone dialer with the site contact's number.
Future<bool> callPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  return launchUrl(Uri(scheme: 'tel', path: digits));
}
