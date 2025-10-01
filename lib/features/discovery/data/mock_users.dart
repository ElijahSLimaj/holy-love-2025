import 'models/user_profile.dart';

class MockUsers {
  static List<UserProfile> get sampleProfiles => [
        UserProfile(
          id: '1',
          firstName: 'Sarah',
          lastName: 'Johnson',
          age: 26,
          location: 'Austin, TX',
          photoUrls: [
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
          ],
          bio:
              'Elementary school teacher who loves hiking, worship music, and coffee dates. Looking for someone to share life\'s adventures and grow in faith together! 🌟',
          denomination: 'Non-denominational',
          churchAttendance: 'Weekly',
          favoriteVerse: 'For I know the plans I have for you, declares the Lord... - Jeremiah 29:11',
          faithStory:
              'My faith has been the anchor through every season. I love serving in children\'s ministry and believe God has someone special planned for me.',
          interests: [
            'Hiking',
            'Worship Music',
            'Coffee',
            'Reading',
            'Photography',
            'Volunteering',
            'Cooking',
            'Bible Study'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 5,
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
          occupation: 'Elementary Teacher',
          education: 'Bachelor\'s in Education',
          languages: ['English', 'Spanish'],
          height: '5\'6"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ENFP',
        ),
        UserProfile(
          id: '2',
          firstName: 'Emily',
          lastName: 'Rodriguez',
          age: 24,
          location: 'Denver, CO',
          photoUrls: [
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
          ],
          bio:
              'Nurse practitioner with a heart for serving others. Love mountain adventures, worship nights, and deep conversations over coffee.',
          denomination: 'Catholic',
          churchAttendance: 'Weekly',
          favoriteVerse: 'Be strong and courageous... - Joshua 1:9',
          faithStory:
              'My faith guides everything I do, from caring for patients to building relationships. I believe God has beautiful plans for my future.',
          interests: [
            'Hiking',
            'Worship Music',
            'Volunteering',
            'Photography',
            'Cooking',
            'Travel',
            'Prayer',
            'Reading'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 8,
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          occupation: 'Nurse Practitioner',
          education: 'Master\'s in Nursing',
          languages: ['English', 'Spanish'],
          height: '5\'4"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ISFJ',
        ),
        UserProfile(
          id: '3',
          firstName: 'Emma',
          lastName: 'Rodriguez',
          age: 24,
          location: 'Miami, FL',
          photoUrls: [
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
          ],
          bio:
              'Nurse with a heart for missions. Love salsa dancing, beach walks, and serving at the local food bank. Seeking a godly man to serve alongside! 💃',
          denomination: 'Catholic',
          churchAttendance: 'Multiple times per week',
          favoriteVerse: 'Proverbs 31:25',
          faithStory:
              'Grew up in a strong Catholic family. My faith guides every decision I make, especially in relationships.',
          interests: [
            'Salsa Dancing',
            'Beach Walks',
            'Nursing',
            'Missions',
            'Spanish Culture',
            'Volunteering',
            'Fitness'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 8,
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
          occupation: 'Registered Nurse',
          education: 'Bachelor\'s in Nursing',
          languages: ['English', 'Spanish'],
          height: '5\'4"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ESFJ',
        ),
        UserProfile(
          id: '4',
          firstName: 'Hannah',
          lastName: 'Thompson',
          age: 25,
          location: 'Nashville, TN',
          photoUrls: [
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
          ],
          bio:
              'Music teacher who loves leading worship and serving in children\'s ministry. When not at church, you\'ll find me playing piano, hiking, or trying new coffee shops.',
          denomination: 'Baptist',
          churchAttendance: 'Weekly',
          favoriteVerse: 'Love is patient, love is kind... - 1 Corinthians 13:4',
          faithStory:
              'Music has always been my way of worshipping God. I love teaching kids and helping them discover their gifts for His glory.',
          interests: [
            'Worship Music',
            'Piano',
            'Hiking',
            'Coffee',
            'Teaching',
            'Children\'s Ministry',
            'Reading'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 15,
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 4)),
          occupation: 'Music Teacher',
          education: 'Bachelor\'s in Music Education',
          languages: ['English'],
          height: '5\'7"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ENFJ',
        ),
        UserProfile(
          id: '5',
          firstName: 'Grace',
          lastName: 'Kim',
          age: 27,
          location: 'Seattle, WA',
          photoUrls: [
            'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=400',
            'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
            'https://images.unsplash.com/photo-1485875437342-9b39470b3d95?w=400',
          ],
          bio:
              'Graphic designer with a passion for creativity and community. Love art museums, farmers markets, and quiet mornings with Jesus and coffee ☕',
          denomination: 'Methodist',
          churchAttendance: 'Weekly',
          favoriteVerse: 'Isaiah 43:19',
          faithStory:
              'Art has always been how I connect with God. I see His creativity everywhere and love expressing that through my work.',
          interests: [
            'Graphic Design',
            'Art',
            'Coffee',
            'Farmers Markets',
            'Photography',
            'Journaling',
            'Pottery'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 7,
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          occupation: 'Graphic Designer',
          education: 'Bachelor\'s in Fine Arts',
          languages: ['English', 'Korean'],
          height: '5\'5"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ISFP',
        ),
        UserProfile(
          id: '6',
          firstName: 'Olivia',
          lastName: 'Williams',
          age: 27,
          location: 'Atlanta, GA',
          photoUrls: [
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
          ],
          bio:
              'Physical therapist who believes in healing both body and soul. Love yoga, cooking, and mentoring young women at church. Seeking my godly man! 🌸',
          denomination: 'Pentecostal',
          churchAttendance: 'Weekly',
          favoriteVerse: 'And we know that in all things God works... - Romans 8:28',
          faithStory:
              'My faith gives me strength to help others heal and overcome challenges. I love serving in women\'s ministry.',
          interests: [
            'Yoga',
            'Cooking',
            'Mentoring',
            'Fitness',
            'Bible Study',
            'Volunteering',
            'Worship Music'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 11,
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
          occupation: 'Physical Therapist',
          education: 'Doctorate in Physical Therapy',
          languages: ['English'],
          height: '5\'8"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ESFJ',
        ),
        UserProfile(
          id: '7',
          firstName: 'Hannah',
          lastName: 'Davis',
          age: 25,
          location: 'Denver, CO',
          photoUrls: [
            'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
            'https://images.unsplash.com/photo-1499952127939-9bbf5af6c51c?w=400',
            'https://images.unsplash.com/photo-1521146764736-56c929d59c83?w=400',
          ],
          bio:
              'Marketing coordinator who loves the mountains! Skiing, hiking, and campfire worship nights are my jam. Seeking an adventure buddy for life! ⛰️',
          denomination: 'Lutheran',
          churchAttendance: 'Weekly',
          favoriteVerse: 'Psalm 121:1-2',
          faithStory:
              'I find God in the mountains and in community. Love leading worship nights and small groups.',
          interests: [
            'Skiing',
            'Hiking',
            'Camping',
            'Worship',
            'Marketing',
            'Photography',
            'Adventure Sports'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 9,
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 10)),
          occupation: 'Marketing Coordinator',
          education: 'Bachelor\'s in Marketing',
          languages: ['English'],
          height: '5\'7"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ENFP',
        ),
        UserProfile(
          id: '8',
          firstName: 'Sophia',
          lastName: 'Anderson',
          age: 29,
          location: 'Phoenix, AZ',
          photoUrls: [
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
          ],
          bio:
              'Children\'s ministry director with a heart for the next generation. Love desert sunsets, board games, and deep conversations about life and faith.',
          denomination: 'Assemblies of God',
          churchAttendance: 'Weekly',
          favoriteVerse: 'She is clothed with strength and dignity... - Proverbs 31:25',
          faithStory:
              'Called to children\'s ministry in college. Love seeing young hearts discover their purpose in God and building His kingdom.',
          interests: [
            'Children\'s Ministry',
            'Desert Hiking',
            'Board Games',
            'Teaching',
            'Crafts',
            'Mentoring',
            'Photography'
          ],
          relationshipGoal: 'Marriage',
          distanceKm: 20,
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 6)),
          occupation: 'Children\'s Ministry Director',
          education: 'Bachelor\'s in Early Childhood Education',
          languages: ['English', 'Spanish'],
          height: '5\'5"',
          hasChildren: false,
          wantsChildren: true,
          drinks: false,
          smokes: false,
          personalityType: 'ENFJ',
        ),
      ];

  // Helper method to get a shuffled list for discovery
  static List<UserProfile> getDiscoveryProfiles() {
    final profiles = List<UserProfile>.from(sampleProfiles);
    profiles.shuffle();
    return profiles;
  }

  // Helper method to get profiles by distance
  static List<UserProfile> getProfilesByDistance({int maxDistance = 50}) {
    return sampleProfiles
        .where((profile) => profile.distanceKm <= maxDistance)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  // Helper method to get online profiles
  static List<UserProfile> getOnlineProfiles() {
    return sampleProfiles.where((profile) => profile.isOnline).toList();
  }
}
