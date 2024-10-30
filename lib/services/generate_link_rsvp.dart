import 'dart:convert';
import '../services/api_service.dart';

Future<String> generateRsvpLink(String guestQr, String userId) async {
  // Mendapatkan URL API secara asinkron
  final String apiUrl = await ApiService.ipAddress();

  // Encode guestQr untuk memastikan karakter khusus di-encode dengan benar
  String encodedGuestQr = Uri.encodeComponent(guestQr);

  // Buat URL dengan format yang diinginkan
  String url = '$apiUrl/rsvp?guest_qr=$encodedGuestQr&user_id=$userId';

  return url;
}
