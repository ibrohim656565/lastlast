import 'package:flutter/material.dart';

/// Mirrors the `incident_type` enum from docs/API_CONTRACT.md exactly
/// (lowercase snake_case strings on the wire).
enum IncidentType {
  flood,
  landslide,
  earthquake,
  fire,
  avalanche,
  other;

  String get wireValue => name;

  static IncidentType fromWire(String value) => IncidentType.values.firstWhere(
        (e) => e.wireValue == value,
        orElse: () => IncidentType.other,
      );

  IconData get icon {
    switch (this) {
      case IncidentType.flood:
        return Icons.water;
      case IncidentType.landslide:
        return Icons.landslide;
      case IncidentType.earthquake:
        return Icons.vibration;
      case IncidentType.fire:
        return Icons.local_fire_department;
      case IncidentType.avalanche:
        return Icons.ac_unit;
      case IncidentType.other:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.flood:
        return const Color(0xFF1565C0);
      case IncidentType.landslide:
        return const Color(0xFF6D4C41);
      case IncidentType.earthquake:
        return const Color(0xFF6A1B9A);
      case IncidentType.fire:
        return const Color(0xFFCE1126);
      case IncidentType.avalanche:
        return const Color(0xFF00838F);
      case IncidentType.other:
        return const Color(0xFF616161);
    }
  }
}

/// Mirrors the `incident_status` enum. Order matters: it is the only
/// forward direction admins may move a report through (see API contract).
enum IncidentStatus {
  new_,
  verified,
  dispatched,
  resolved;

  String get wireValue {
    switch (this) {
      case IncidentStatus.new_:
        return 'new';
      case IncidentStatus.verified:
        return 'verified';
      case IncidentStatus.dispatched:
        return 'dispatched';
      case IncidentStatus.resolved:
        return 'resolved';
    }
  }

  static IncidentStatus fromWire(String value) {
    switch (value) {
      case 'new':
        return IncidentStatus.new_;
      case 'verified':
        return IncidentStatus.verified;
      case 'dispatched':
        return IncidentStatus.dispatched;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.new_;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case IncidentStatus.new_:
        return const Color(0xFF9E9E9E);
      case IncidentStatus.verified:
        return const Color(0xFF0033A0);
      case IncidentStatus.dispatched:
        return const Color(0xFFF57C00);
      case IncidentStatus.resolved:
        return const Color(0xFF2E7D32);
    }
  }
}

/// Mirrors `safe_point_type`.
enum SafePointType {
  shelter,
  hospital,
  police,
  emergencyCenter;

  String get wireValue {
    switch (this) {
      case SafePointType.shelter:
        return 'shelter';
      case SafePointType.hospital:
        return 'hospital';
      case SafePointType.police:
        return 'police';
      case SafePointType.emergencyCenter:
        return 'emergency_center';
    }
  }

  static SafePointType fromWire(String value) {
    switch (value) {
      case 'shelter':
        return SafePointType.shelter;
      case 'hospital':
        return SafePointType.hospital;
      case 'police':
        return SafePointType.police;
      case 'emergency_center':
        return SafePointType.emergencyCenter;
      default:
        return SafePointType.shelter;
    }
  }

  IconData get icon {
    switch (this) {
      case SafePointType.shelter:
        return Icons.home_work;
      case SafePointType.hospital:
        return Icons.local_hospital;
      case SafePointType.police:
        return Icons.local_police;
      case SafePointType.emergencyCenter:
        return Icons.emergency;
    }
  }
}

/// Mirrors `media_type`.
enum MediaType {
  photo,
  video;

  String get wireValue => name;

  static MediaType fromWire(String value) =>
      value == 'video' ? MediaType.video : MediaType.photo;
}

/// Mirrors `language` (also used for `preferred_language`).
enum AppLanguage {
  tg,
  ru,
  en;

  String get wireValue => name;

  static AppLanguage fromWire(String value) => AppLanguage.values.firstWhere(
        (e) => e.wireValue == value,
        orElse: () => AppLanguage.en,
      );

  String get nativeLabel {
    switch (this) {
      case AppLanguage.tg:
        return 'Тоҷикӣ';
      case AppLanguage.ru:
        return 'Русский';
      case AppLanguage.en:
        return 'English';
    }
  }
}

/// Emergency contact categories from the API contract.
enum EmergencyContactCategory {
  police,
  ambulance,
  fire,
  gas,
  rescueService,
  other;

  String get wireValue {
    switch (this) {
      case EmergencyContactCategory.police:
        return 'police';
      case EmergencyContactCategory.ambulance:
        return 'ambulance';
      case EmergencyContactCategory.fire:
        return 'fire';
      case EmergencyContactCategory.gas:
        return 'gas';
      case EmergencyContactCategory.rescueService:
        return 'rescue_service';
      case EmergencyContactCategory.other:
        return 'other';
    }
  }

  static EmergencyContactCategory fromWire(String value) {
    switch (value) {
      case 'police':
        return EmergencyContactCategory.police;
      case 'ambulance':
        return EmergencyContactCategory.ambulance;
      case 'fire':
        return EmergencyContactCategory.fire;
      case 'gas':
        return EmergencyContactCategory.gas;
      case 'rescue_service':
        return EmergencyContactCategory.rescueService;
      default:
        return EmergencyContactCategory.other;
    }
  }

  IconData get icon {
    switch (this) {
      case EmergencyContactCategory.police:
        return Icons.local_police;
      case EmergencyContactCategory.ambulance:
        return Icons.local_hospital;
      case EmergencyContactCategory.fire:
        return Icons.local_fire_department;
      case EmergencyContactCategory.gas:
        return Icons.propane_tank;
      case EmergencyContactCategory.rescueService:
        return Icons.support;
      case EmergencyContactCategory.other:
        return Icons.info;
    }
  }
}

/// Real standard emergency numbers used in Tajikistan. Used only as an
/// on-device fallback when `/api/v1/emergency-contacts` is unreachable.
class FallbackEmergencyContact {
  const FallbackEmergencyContact({
    required this.category,
    required this.name,
    required this.phone,
  });

  final EmergencyContactCategory category;
  final String name;
  final String phone;
}

const List<FallbackEmergencyContact> kFallbackEmergencyContacts = [
  FallbackEmergencyContact(
    category: EmergencyContactCategory.fire,
    name: 'Fire Service',
    phone: '101',
  ),
  FallbackEmergencyContact(
    category: EmergencyContactCategory.police,
    name: 'Police',
    phone: '102',
  ),
  FallbackEmergencyContact(
    category: EmergencyContactCategory.ambulance,
    name: 'Ambulance',
    phone: '103',
  ),
  FallbackEmergencyContact(
    category: EmergencyContactCategory.gas,
    name: 'Gas Emergency',
    phone: '104',
  ),
];
