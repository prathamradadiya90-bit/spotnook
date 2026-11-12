import 'package:flutter/material.dart';

/// Place category definition with icon mappings for both OSM and Google Places.
class PlaceCategory {
  final String id;
  final String name;
  final IconData icon;
  final String osmKey;
  final String osmValue;
  final String googleType;
  final String defaultKeyword;

  const PlaceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.osmKey,
    required this.osmValue,
    required this.googleType,
    required this.defaultKeyword,
  });

  /// Comprehensive list of standard place categories.
  static const List<PlaceCategory> standardCategories = [
    PlaceCategory(
      id: 'all',
      name: 'All',
      icon: Icons.explore_outlined,
      osmKey: 'amenity',
      osmValue: '',
      googleType: '',
      defaultKeyword: '',
    ),
    PlaceCategory(
      id: 'cafe',
      name: 'Cafes',
      icon: Icons.local_cafe_outlined,
      osmKey: 'amenity',
      osmValue: 'cafe',
      googleType: 'cafe',
      defaultKeyword: 'cafe',
    ),
    PlaceCategory(
      id: 'restaurant',
      name: 'Restaurants',
      icon: Icons.restaurant_outlined,
      osmKey: 'amenity',
      osmValue: 'restaurant',
      googleType: 'restaurant',
      defaultKeyword: 'restaurant',
    ),
    PlaceCategory(
      id: 'fast_food',
      name: 'Fast Food',
      icon: Icons.fastfood_outlined,
      osmKey: 'amenity',
      osmValue: 'fast_food',
      googleType: 'fast_food_restaurant',
      defaultKeyword: 'fast food',
    ),
    PlaceCategory(
      id: 'hotel',
      name: 'Hotels',
      icon: Icons.hotel_outlined,
      osmKey: 'tourism',
      osmValue: 'hotel',
      googleType: 'hotel',
      defaultKeyword: 'hotel',
    ),
    PlaceCategory(
      id: 'resort',
      name: 'Resorts',
      icon: Icons.beach_access_outlined,
      osmKey: 'tourism',
      osmValue: 'resort',
      googleType: 'resort',
      defaultKeyword: 'resort',
    ),
    PlaceCategory(
      id: 'gym',
      name: 'Gyms & Fitness',
      icon: Icons.fitness_center_outlined,
      osmKey: 'leisure',
      osmValue: 'fitness_centre',
      googleType: 'gym',
      defaultKeyword: 'gym',
    ),
    PlaceCategory(
      id: 'shopping',
      name: 'Shopping Malls',
      icon: Icons.shopping_bag_outlined,
      osmKey: 'shop',
      osmValue: 'mall',
      googleType: 'shopping_mall',
      defaultKeyword: 'mall',
    ),
    PlaceCategory(
      id: 'clothing',
      name: 'Clothing',
      icon: Icons.checkroom_outlined,
      osmKey: 'shop',
      osmValue: 'clothes',
      googleType: 'clothing_store',
      defaultKeyword: 'clothing store',
    ),
    PlaceCategory(
      id: 'hospital',
      name: 'Hospitals',
      icon: Icons.local_hospital_outlined,
      osmKey: 'amenity',
      osmValue: 'hospital',
      googleType: 'hospital',
      defaultKeyword: 'hospital',
    ),
    PlaceCategory(
      id: 'pharmacy',
      name: 'Pharmacies',
      icon: Icons.medical_services_outlined,
      osmKey: 'amenity',
      osmValue: 'pharmacy',
      googleType: 'pharmacy',
      defaultKeyword: 'pharmacy',
    ),
    PlaceCategory(
      id: 'attraction',
      name: 'Attractions',
      icon: Icons.attractions_outlined,
      osmKey: 'tourism',
      osmValue: 'attraction',
      googleType: 'tourist_attraction',
      defaultKeyword: 'tourist attraction',
    ),
    PlaceCategory(
      id: 'park',
      name: 'Parks',
      icon: Icons.park_outlined,
      osmKey: 'leisure',
      osmValue: 'park',
      googleType: 'park',
      defaultKeyword: 'park',
    ),
    PlaceCategory(
      id: 'cinema',
      name: 'Cinemas',
      icon: Icons.movie_outlined,
      osmKey: 'amenity',
      osmValue: 'cinema',
      googleType: 'movie_theater',
      defaultKeyword: 'cinema',
    ),
    PlaceCategory(
      id: 'fuel',
      name: 'Fuel Pumps',
      icon: Icons.local_gas_station_outlined,
      osmKey: 'amenity',
      osmValue: 'fuel',
      googleType: 'gas_station',
      defaultKeyword: 'petrol pump',
    ),
    PlaceCategory(
      id: 'atm',
      name: 'ATMs & Banks',
      icon: Icons.atm_outlined,
      osmKey: 'amenity',
      osmValue: 'atm',
      googleType: 'atm',
      defaultKeyword: 'atm',
    ),
    PlaceCategory(
      id: 'salon',
      name: 'Salons & Spas',
      icon: Icons.spa_outlined,
      osmKey: 'shop',
      osmValue: 'beauty',
      googleType: 'beauty_salon',
      defaultKeyword: 'salon',
    ),
    PlaceCategory(
      id: 'business',
      name: 'Business & IT',
      icon: Icons.business_outlined,
      osmKey: 'office',
      osmValue: 'company',
      googleType: 'corporate_office',
      defaultKeyword: 'office',
    ),
    PlaceCategory(
      id: 'education',
      name: 'Education',
      icon: Icons.school_outlined,
      osmKey: 'amenity',
      osmValue: 'school',
      googleType: 'school',
      defaultKeyword: 'school',
    ),
  ];

  static PlaceCategory findById(String id) {
    return standardCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => standardCategories.first,
    );
  }
}

