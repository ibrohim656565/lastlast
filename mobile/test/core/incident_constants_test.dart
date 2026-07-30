import 'package:flutter_test/flutter_test.dart';
import 'package:safetj/core/constants/incident_constants.dart';

void main() {
  group('IncidentType wire mapping', () {
    test('every value round-trips through its wire string', () {
      for (final IncidentType type in IncidentType.values) {
        expect(IncidentType.fromWire(type.wireValue), type);
      }
    });

    test('wire values match the lowercase snake_case enum from the API contract', () {
      expect(IncidentType.flood.wireValue, 'flood');
      expect(IncidentType.landslide.wireValue, 'landslide');
      expect(IncidentType.earthquake.wireValue, 'earthquake');
      expect(IncidentType.fire.wireValue, 'fire');
      expect(IncidentType.avalanche.wireValue, 'avalanche');
      expect(IncidentType.other.wireValue, 'other');
    });

    test('unknown wire values fall back to other rather than throwing', () {
      expect(IncidentType.fromWire('tsunami'), IncidentType.other);
      expect(IncidentType.fromWire(''), IncidentType.other);
    });
  });

  group('IncidentStatus wire mapping', () {
    test('every value round-trips through its wire string', () {
      for (final IncidentStatus status in IncidentStatus.values) {
        expect(IncidentStatus.fromWire(status.wireValue), status);
      }
    });

    test('wire values match the API contract exactly', () {
      expect(IncidentStatus.new_.wireValue, 'new');
      expect(IncidentStatus.verified.wireValue, 'verified');
      expect(IncidentStatus.dispatched.wireValue, 'dispatched');
      expect(IncidentStatus.resolved.wireValue, 'resolved');
    });

    test('unknown wire values fall back to new rather than throwing', () {
      expect(IncidentStatus.fromWire('archived'), IncidentStatus.new_);
    });
  });

  group('SafePointType wire mapping', () {
    test('every value round-trips, including the multi-word emergency_center', () {
      for (final SafePointType type in SafePointType.values) {
        expect(SafePointType.fromWire(type.wireValue), type);
      }
      expect(SafePointType.emergencyCenter.wireValue, 'emergency_center');
    });
  });

  group('EmergencyContactCategory wire mapping', () {
    test('every value round-trips, including the multi-word rescue_service', () {
      for (final EmergencyContactCategory category in EmergencyContactCategory.values) {
        expect(EmergencyContactCategory.fromWire(category.wireValue), category);
      }
      expect(EmergencyContactCategory.rescueService.wireValue, 'rescue_service');
    });
  });

  group('kFallbackEmergencyContacts', () {
    test('contains the four standard Tajikistan emergency numbers', () {
      final Map<String, String> byPhone = {
        for (final c in kFallbackEmergencyContacts) c.phone: c.name,
      };
      expect(byPhone['101'], isNotNull); // Fire
      expect(byPhone['102'], isNotNull); // Police
      expect(byPhone['103'], isNotNull); // Ambulance
      expect(byPhone['104'], isNotNull); // Gas
      expect(kFallbackEmergencyContacts.length, 4);
    });
  });
}
