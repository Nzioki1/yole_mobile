import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AppContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? avatar;

  const AppContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.avatar,
  });

  factory AppContact.fromFlutterContact(Contact contact) {
    final phones = contact.phones;
    final phoneNumber = phones.isNotEmpty ? phones.first.number : '';

    return AppContact(
      id: contact.id,
      name: contact.displayName,
      phoneNumber: phoneNumber,
      avatar: contact.photo != null ? contact.photo.toString() : null,
    );
  }

  // Factory for creating contacts manually
  factory AppContact.manual({
    required String id,
    required String name,
    required String phoneNumber,
  }) {
    return AppContact(id: id, name: name, phoneNumber: phoneNumber);
  }
}

class ContactsService {
  static Future<bool> requestPermission() async {
    try {
      print('Requesting contacts permission...');

      // Request permission using flutter_contacts
      final granted = await FlutterContacts.requestPermission();
      print('FlutterContacts permission result: $granted');

      if (granted) {
        return true;
      }

      // Fallback to permission_handler
      print('Trying permission_handler fallback...');
      final status = await Permission.contacts.request();
      print('Permission_handler result: ${status.isGranted}');

      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      // Fallback to permission_handler
      try {
        final status = await Permission.contacts.request();
        return status.isGranted;
      } catch (fallbackError) {
        print('Fallback permission error: $fallbackError');
        return false;
      }
    }
  }

  static Future<bool> hasPermission() async {
    try {
      print('Checking contacts permission...');

      // Try permission_handler first
      final status = await Permission.contacts.status;
      print('Permission_handler status: ${status.isGranted}');

      if (status.isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  static Future<List<AppContact>> getContacts() async {
    try {
      print('Getting contacts...');

      // First try to get permission
      final permissionGranted = await hasPermission();
      print('Has permission: $permissionGranted');

      if (!permissionGranted) {
        print('Requesting permission...');
        final granted = await requestPermission();
        print('Permission granted: $granted');

        if (!granted) {
          print('Contacts permission denied');
          throw Exception(
            'Contacts permission denied. Please grant contacts permission in settings.',
          );
        }
      }

      // Try to get contacts from device
      print('Fetching contacts from device...');
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      print('Found ${contacts.length} contacts');

      final validContacts = contacts
          .where(
            (contact) =>
                contact.phones.isNotEmpty && contact.displayName.isNotEmpty,
          )
          .map((contact) => AppContact.fromFlutterContact(contact))
          .toList();

      print('Valid contacts: ${validContacts.length}');

      if (validContacts.isNotEmpty) {
        return validContacts;
      } else {
        print('No valid contacts found, using sample contacts');
        return _getSampleContacts();
      }
    } catch (e) {
      print('Error loading contacts: $e');
      // Return sample contacts as fallback
      return _getSampleContacts();
    }
  }

  // Fallback sample contacts
  static List<AppContact> _getSampleContacts() {
    print('Using sample contacts');
    return [
      AppContact.manual(
        id: 'sample_1',
        name: 'John Doe',
        phoneNumber: '+254700123456',
      ),
      AppContact.manual(
        id: 'sample_2',
        name: 'Jane Smith',
        phoneNumber: '+254700654321',
      ),
      AppContact.manual(
        id: 'sample_3',
        name: 'Mike Johnson',
        phoneNumber: '+254700789012',
      ),
      AppContact.manual(
        id: 'sample_4',
        name: 'Sarah Wilson',
        phoneNumber: '+254700345678',
      ),
      AppContact.manual(
        id: 'sample_5',
        name: 'David Brown',
        phoneNumber: '+254700901234',
      ),
    ];
  }

  static Future<List<AppContact>> searchContacts(String query) async {
    try {
      if (!await hasPermission()) {
        throw Exception('Contacts permission not granted');
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      return contacts
          .where(
            (contact) =>
                contact.phones.isNotEmpty &&
                contact.displayName.isNotEmpty &&
                (contact.displayName.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    contact.phones.any(
                      (phone) => phone.number.contains(query),
                    )),
          )
          .map((contact) => AppContact.fromFlutterContact(contact))
          .toList();
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle Kenyan phone numbers
    if (digits.startsWith('254')) {
      return '+$digits';
    } else if (digits.startsWith('0') && digits.length == 10) {
      return '+254${digits.substring(1)}';
    } else if (digits.startsWith('7') && digits.length == 9) {
      return '+254$digits';
    }

    return phoneNumber;
  }
}
