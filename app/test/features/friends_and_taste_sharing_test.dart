import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/friends/domain/friend.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/shared/utils/phone_dial_code.dart';

void main() {
  group('Username Validation & UserProfile Tests', () {
    test('validates acceptable usernames correctly', () {
      expect(UserProfile.validateUsername('flavien'), isNull);
      expect(UserProfile.validateUsername('caro_12'), isNull);
      expect(UserProfile.validateUsername('dimitri_vins'), isNull);
      expect(UserProfile.validateUsername('abc'), isNull);
    });

    test('rejects invalid usernames with clear messages', () {
      expect(UserProfile.validateUsername(''), isNotNull);
      expect(UserProfile.validateUsername(null), isNotNull);
      expect(UserProfile.validateUsername('ab'), contains('au moins 3'));
      expect(UserProfile.validateUsername('flavien.daussy'), contains('tirets bas'));
      expect(UserProfile.validateUsername('flavien!'), contains('tirets bas'));
      expect(UserProfile.validateUsername('this_username_is_way_too_long_to_be_valid_in_the_system'), contains('30 caractères'));
    });

    test('UserProfile handle getter formats with @ prefix', () {
      const user = UserProfile(
        id: 'u1',
        displayName: 'Flavien D.',
        username: 'flavien',
        phoneNumber: '+33612345678',
        email: 'flavien@chatmelier.app',
      );
      expect(user.handle, equals('@flavien'));
    });

    test('UserProfile JSON serialization preserves all fields', () {
      final map = {
        'id': 'u123',
        'display_name': 'Caro',
        'username': 'caro_wine',
        'phone_number': '+33698765432',
        'email': 'caro@chatmelier.app',
        'default_currency': 'EUR',
        'taste_profile': {
          'favorite_grapes': ['Chardonnay', 'Chenin'],
          'favorite_regions': ['Bourgogne', 'Loire'],
        },
      };

      final profile = UserProfile.fromJson(map);
      expect(profile.id, equals('u123'));
      expect(profile.displayName, equals('Caro'));
      expect(profile.username, equals('caro_wine'));
      expect(profile.handle, equals('@caro_wine'));
      expect(profile.phoneNumber, equals('+33698765432'));
      expect(profile.tasteProfileData?['favorite_grapes'], contains('Chardonnay'));

      final json = profile.toJson();
      expect(json['username'], equals('caro_wine'));
      expect(json['phone_number'], equals('+33698765432'));
    });
  });

  group('TastingEntry Co-tasting & Ownership Tests', () {
    test('originDescription reports cellar ownership', () {
      final entry = TastingEntry(
        id: 't1',
        wineId: 'w1',
        wineName: 'Cornas Domaine Clape',
        bottleOwnerName: 'Flavien',
        isExternal: false,
        coTasters: ['Caro', 'Dimitri'],
        consumedAt: DateTime.now(),
      );

      expect(entry.originDescription, equals('Cave de Flavien'));
      expect(entry.coTasters.length, equals(2));
      expect(entry.coTasters, contains('Caro'));
    });

    test('originDescription reports external restaurant/bar location', () {
      final entry = TastingEntry(
        id: 't2',
        wineId: 'w2',
        wineName: 'Morgon Marcel Lapierre',
        locationName: 'Chez Dimitri',
        isExternal: true,
        coTasters: ['Dimitri'],
        consumedAt: DateTime.now(),
      );

      expect(entry.originDescription, equals('Hors-cave (Chez Dimitri)'));
      expect(entry.isExternal, isTrue);
    });

    test('TastingEntry JSON roundtrip preserves coTasters and location', () {
      final map = {
        'id': 't3',
        'wine_id': 'w3',
        'rating': 4.5,
        'co_tasters': ['Flavien', 'Caro'],
        'bottle_owner_name': 'Flavien',
        'location_name': 'Restaurant Le Bistrot',
        'is_external': true,
        'consumed_at': '2026-08-26T18:00:00.000Z',
        'wines': {
          'id': 'w3',
          'name': 'Chablis Grand Cru',
          'vintage': 2020,
        },
      };

      final entry = TastingEntry.fromJson(map);
      expect(entry.wineName, equals('Chablis Grand Cru'));
      expect(entry.vintage, equals(2020));
      expect(entry.rating, equals(4.5));
      expect(entry.coTasters, equals(['Flavien', 'Caro']));
      expect(entry.isExternal, isTrue);
      expect(entry.locationName, equals('Restaurant Le Bistrot'));
      expect(entry.originDescription, equals('Hors-cave (Restaurant Le Bistrot)'));
    });
  });

  group('Sommelier Friends Taste Card Formatting Tests', () {
    test('formatFriendsForSommelier injects complete taste cards for AI', () {
      final service = TasteProfileService();

      final friends = <Friend>[
        const Friend(
          id: 'f1',
          friendUserId: 'u-flavien',
          displayName: 'Flavien',
          username: 'flavien',
          tasteProfile: TasteProfile(
            id: 'u-flavien',
            name: 'Flavien',
            favoriteTypes: ['Rouge puissant', 'Rouge de garde'],
            favoriteRegions: ['Vallée du Rhône (Cornas, Côte-Rôtie)', 'Bandol'],
            favoriteGrapes: ['Syrah', 'Mourvèdre'],
            dislikedCharacteristics: ['Vins trop boisés'],
            avgTanninPreference: 0.85,
            avgAcidityPreference: 0.50,
            avgBodyPreference: 0.90,
            questionnairesCompleted: 6,
          ),
        ),
        const Friend(
          id: 'f2',
          friendUserId: 'u-caro',
          displayName: 'Caro',
          username: 'caro',
          tasteProfile: TasteProfile(
            id: 'u-caro',
            name: 'Caro',
            favoriteTypes: ['Blanc sec', 'Champagne & Bulles'],
            favoriteRegions: ['Bourgogne Blanc', 'Sancerre'],
            favoriteGrapes: ['Chardonnay', 'Chenin'],
            dislikedCharacteristics: ['Rouges très tanniques'],
            avgTanninPreference: 0.20,
            avgAcidityPreference: 0.80,
            avgBodyPreference: 0.55,
            questionnairesCompleted: 4,
          ),
        ),
      ];

      final promptBlock = service.formatFriendsForSommelier(friends);

      // Verify Flavien's profile is fully articulated in the prompt block
      expect(promptBlock, contains('Ami(e): Flavien (@flavien)'));
      expect(promptBlock, contains('Syrah'));
      expect(promptBlock, contains('Vallée du Rhône'));
      expect(promptBlock, contains('Vins trop boisés'));

      // Verify Caro's profile is fully articulated
      expect(promptBlock, contains('Ami(e): Caro (@caro)'));
      expect(promptBlock, contains('Chardonnay'));
      expect(promptBlock, contains('Bourgogne Blanc'));
      expect(promptBlock, contains('Rouges très tanniques'));
    });
  });

  group('International Phone Dial Code & Validation Tests', () {
    test('Default country is France (FR, +33) and UK is supported (GB, +44)', () {
      expect(PhoneDialCodeHelper.defaultCountry.isoCode, equals('FR'));
      expect(PhoneDialCodeHelper.defaultCountry.dialCode, equals('+33'));
      expect(PhoneDialCodeHelper.defaultCountry.flag, equals('🇫🇷'));

      expect(PhoneDialCodeHelper.ukCountry.isoCode, equals('GB'));
      expect(PhoneDialCodeHelper.ukCountry.dialCode, equals('+44'));
      expect(PhoneDialCodeHelper.ukCountry.flag, equals('🇬🇧'));
    });

    test('formatInternational strips leading zeros and formats with dial code', () {
      // France: 06 12 34 56 78 -> +33 612345678
      final frFormatted = PhoneDialCodeHelper.formatInternational(
        dialCode: '+33',
        nationalNumber: '06 12 34 56 78',
      );
      expect(frFormatted, equals('+33 612345678'));

      // UK: 07911 123456 -> +44 7911123456
      final ukFormatted = PhoneDialCodeHelper.formatInternational(
        dialCode: '+44',
        nationalNumber: '07911 123456',
      );
      expect(ukFormatted, equals('+44 7911123456'));

      // Without leading zero: 612345678 -> +33 612345678
      final direct = PhoneDialCodeHelper.formatInternational(
        dialCode: '+33',
        nationalNumber: '612345678',
      );
      expect(direct, equals('+33 612345678'));
    });

    test('parseExisting correctly parses +33, +44, +39 and default fallback', () {
      final (frCountry, frNum) = PhoneDialCodeHelper.parseExisting('+33 6 12 34 56 78');
      expect(frCountry.isoCode, equals('FR'));
      expect(frCountry.dialCode, equals('+33'));
      expect(frNum, equals('6 12 34 56 78'));

      final (ukCountry, ukNum) = PhoneDialCodeHelper.parseExisting('+447911123456');
      expect(ukCountry.isoCode, equals('GB'));
      expect(ukCountry.dialCode, equals('+44'));
      expect(ukNum, equals('7911123456'));

      final (itCountry, itNum) = PhoneDialCodeHelper.parseExisting('+393123456789');
      expect(itCountry.isoCode, equals('IT'));
      expect(itCountry.dialCode, equals('+39'));
      expect(itNum, equals('3123456789'));
    });

    test('validateInternational & UserProfile.validatePhoneNumber require dial code (+)', () {
      // Valid international formats
      expect(PhoneDialCodeHelper.validateInternational('+33612345678'), isNull);
      expect(PhoneDialCodeHelper.validateInternational('+44 7911 123456'), isNull);
      expect(UserProfile.validatePhoneNumber('+33612345678'), isNull);
      expect(UserProfile.validatePhoneNumber(null), isNull); // Optional
      expect(UserProfile.validatePhoneNumber(''), isNull); // Optional

      // Missing dial code (+)
      expect(PhoneDialCodeHelper.validateInternational('0612345678'), contains('indicatif national'));
      expect(UserProfile.validatePhoneNumber('0612345678'), contains('indicatif national'));
      expect(UserProfile.validatePhoneNumber('07911123456'), contains('indicatif national'));

      // Too short
      expect(PhoneDialCodeHelper.validateInternational('+3312'), contains('trop court'));
      expect(UserProfile.validatePhoneNumber('+3312'), contains('au moins 7 chiffres'));
    });

    test('UserProfile.fromJson seamlessly extracts fallback metadata from avatar_url meta URI', () {
      final json = {
        'id': 'u_meta_1',
        'display_name': 'Jean Dupont',
        'avatar_url': 'meta://u=jeannot&p=%2B33611223344&e=jean%40test.fr',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, equals('u_meta_1'));
      expect(profile.displayName, equals('Jean Dupont'));
      expect(profile.username, equals('jeannot'));
      expect(profile.handle, equals('@jeannot'));
      expect(profile.phoneNumber, equals('+33611223344'));
      expect(profile.email, equals('jean@test.fr'));
      expect(profile.avatarUrl, isNull); // Cleared because it was a meta URI
    });

    test('UserProfile.fromJson extracts handle embedded in display_name format', () {
      final json = {
        'id': 'u_meta_2',
        'display_name': 'Flavien (@flavien)',
        'avatar_url': null,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, equals('u_meta_2'));
      expect(profile.displayName, equals('Flavien'));
      expect(profile.username, equals('flavien'));
      expect(profile.handle, equals('@flavien'));
    });
  });

  group('Friend & Cellar Sharing Permission Tests', () {
    test('Friend domain model reports cellar access and write permissions correctly', () {
      const friendViewer = Friend(
        id: 'f1',
        friendUserId: 'u_leo',
        displayName: 'Léo',
        username: 'leo',
        tasteProfile: TasteProfile(id: 'u_leo', name: 'Léo'),
        status: 'accepted',
        cellarAccessRole: 'viewer',
        friendCellarId: 'c_leo',
        friendCellarName: 'Cave de Léo',
      );

      expect(friendViewer.isAccepted, isTrue);
      expect(friendViewer.hasCellarAccess, isTrue);
      expect(friendViewer.canWriteCellar, isFalse);

      const friendEditor = Friend(
        id: 'f2',
        friendUserId: 'u_dimitri',
        displayName: 'Dimitri',
        username: 'dimitri',
        tasteProfile: TasteProfile(id: 'u_dimitri', name: 'Dimitri'),
        status: 'accepted',
        cellarAccessRole: 'editor',
      );

      expect(friendEditor.isAccepted, isTrue);
      expect(friendEditor.hasCellarAccess, isTrue);
      expect(friendEditor.canWriteCellar, isTrue);

      const friendPending = Friend(
        id: 'f3',
        friendUserId: 'u_caro',
        displayName: 'Caro',
        username: 'caro',
        tasteProfile: TasteProfile(id: 'u_caro', name: 'Caro'),
        status: 'pending',
        cellarAccessRole: 'none',
      );

      expect(friendPending.isAccepted, isFalse);
      expect(friendPending.hasCellarAccess, isFalse);
    });

    test('Friend.fromJson / toJson roundtrip preserves all cellar sharing properties', () {
      final json = {
        'id': 'f_roundtrip',
        'friend_id': 'u_roundtrip',
        'status': 'accepted',
        'is_outgoing': false,
        'cellar_access_role': 'editor',
        'friend_cellar_id': 'cellar_123',
        'friend_cellar_name': 'Cave Principale',
        'profiles': {
          'id': 'u_roundtrip',
          'display_name': 'Jean Sommelier',
          'username': 'jean_somm',
          'taste_profile': {
            'favorite_grapes': ['Syrah', 'Mourvèdre'],
            'favorite_regions': ['Rhône', 'Bandol'],
          },
        },
      };

      final friend = Friend.fromJson(json);
      expect(friend.displayName, equals('Jean Sommelier'));
      expect(friend.username, equals('jean_somm'));
      expect(friend.handle, equals('@jean_somm'));
      expect(friend.cellarAccessRole, equals('editor'));
      expect(friend.canWriteCellar, isTrue);
      expect(friend.friendCellarId, equals('cellar_123'));
      expect(friend.tasteProfile.favoriteGrapes, contains('Syrah'));

      final outJson = friend.toJson();
      expect(outJson['cellar_access_role'], equals('editor'));
      expect(outJson['friend_cellar_id'], equals('cellar_123'));
    });
  });
}

