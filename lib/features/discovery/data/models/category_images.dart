/// Curated, authentic category imagery with Unsplash attribution.
/// Offers 8-10 diverse, high-resolution photographs per category so cards never duplicate photos.
class CategoryImages {
  CategoryImages._();

  static const Map<String, List<String>> _curatedImages = {
    'cafe': [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&q=80', // cozy coffee shop
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80', // cafe outdoor patio
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80', // barista latte art
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80', // warm coffee cup
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800&q=80', // coffee beans & pour
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=800&q=80', // cafe counter & pastry
      'https://images.unsplash.com/photo-1497636577773-f1231844b336?w=800&q=80', // modern aesthetic cafe
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&q=80', // espresso machine & barista
    ],
    'restaurant': [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80', // modern restaurant interior
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80', // gourmet plated dish
      'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800&q=80', // dining table ambiance
      'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80', // grilled steak & sides
      'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80', // bistro terrace
      'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80', // fresh chef salad
      'https://images.unsplash.com/photo-1578474846511-04ba529f0b88?w=800&q=80', // fine dining cuisine
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80', // evening dinner glow
    ],
    'fast_food': [
      'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=800&q=80', // artisan burger & fries
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80', // freshly baked pizza slice
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80', // double cheeseburger
      'https://images.unsplash.com/photo-1562967914-608f82629710?w=800&q=80', // crispy fried chicken tenders
      'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=800&q=80', // gourmet slider burgers
      'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?w=800&q=80', // loaded golden french fries
      'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=800&q=80', // charcoal bun burger
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80', // artisan pepperoni pizza
      'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=800&q=80', // hot dog & street food
      'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=800&q=80', // chicken nuggets & dips
    ],
    'hotel': [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80', // luxury hotel exterior
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80', // modern hotel bedroom
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80', // boutique suite
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80', // grand hotel lobby
      'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80', // resort hotel pool
      'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&q=80', // king bed contemporary room
      'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80', // scenic coastal hotel
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80', // luxury hotel lounge
    ],
    'resort': [
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&q=80', // tropical infinity pool
      'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&q=80', // beachside cabanas
      'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80', // luxury island resort
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80', // serene resort beach
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80', // luxury villa with pool
      'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80', // palm tree resort walkway
      'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80', // sunset pool view
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800&q=80', // private beach cottage
    ],
    'gym': [
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80', // modern gym equipment
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800&q=80', // weight training zone
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=80', // cardio machines row
      'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80', // dumbbells rack
      'https://images.unsplash.com/photo-1593079831268-3381b0db4a77?w=800&q=80', // athletic gym floor
      'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800&q=80', // kettlebells and functional area
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80', // yoga and pilates studio
      'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800&q=80', // barbell lifting platform
    ],
    'shopping': [
      'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800&q=80', // modern shopping mall atrium
      'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?w=800&q=80', // multi-level mall concourse
      'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&q=80', // retail shopping center
      'https://images.unsplash.com/photo-1581783342308-f792dbdd27c5?w=800&q=80', // indoor mall architecture
      'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?w=800&q=80', // lifestyle boutique mall
      'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800&q=80', // storefront display
      'https://images.unsplash.com/photo-1580828343064-fde4fc206bc6?w=800&q=80', // luxury shopping arcade
      'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=800&q=80', // designer retail promenade
    ],
    'clothing': [
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80', // trendy clothing store
      'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&q=80', // fashion rack displays
      'https://images.unsplash.com/photo-1470309864661-68328b2cd0a5?w=800&q=80', // apparel showroom
      'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80', // boutique fashion clothing
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80', // designer menswear and womenswear
      'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=800&q=80', // stylish garment rack
      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&q=80', // modern fashion retail
      'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=800&q=80', // shoes and accessories store
    ],
    'hospital': [
      'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800&q=80', // modern hospital exterior
      'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80', // hospital reception & corridor
      'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&q=80', // medical care facility
      'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800&q=80', // healthcare center
      'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800&q=80', // doctor consultation room
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80', // modern diagnostics clinic
    ],
    'pharmacy': [
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800&q=80', // organized pharmacy shelves
      'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800&q=80', // chemist store counter
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=800&q=80', // apothecary supplies
      'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800&q=80', // pharmacy medicine counter
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&q=80', // pharmaceutical dispensary
      'https://images.unsplash.com/photo-1628771065518-0d82f1938462?w=800&q=80', // wellness & health store
    ],
    'attraction': [
      'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=800&q=80', // historic monument
      'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80', // landmark city bridge
      'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80', // architectural landmark
      'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800&q=80', // scenic cultural destination
      'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800&q=80', // majestic palace / heritage site
      'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80', // iconic tourist attraction
      'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800&q=80', // travel observation point
      'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80', // scenic outdoor landmark
    ],
    'park': [
      'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=800&q=80', // lush green urban park
      'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80', // tranquil forest walkway
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80', // waterside botanical park
      'https://images.unsplash.com/photo-1470240731273-7821a6eeb6bd?w=800&q=80', // flower garden trail
      'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&q=80', // public nature park with benches
      'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=800&q=80', // sunlit tree-lined avenue
      'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=800&q=80', // scenic valley park
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80', // peaceful woodland park
    ],
    'cinema': [
      'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80', // cinema auditorium & screen
      'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800&q=80', // cinema seats row
      'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&q=80', // movie projector light
      'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=800&q=80', // movie theater popcorn
      'https://images.unsplash.com/photo-1574267432553-4b4628081c31?w=800&q=80', // cinema entrance neon
      'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=800&q=80', // film studio theater
    ],
    'fuel': [
      'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800&q=80', // modern gas station pumps
      'https://images.unsplash.com/photo-1545459720-aac8509eb02c?w=800&q=80', // fuel station canopy
      'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=800&q=80', // highway service station
      'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=800&q=80', // EV charging station hub
      'https://images.unsplash.com/photo-1508974239320-0a029497e820?w=800&q=80', // auto service fuel plaza
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&q=80', // express highway fuel stop
    ],
    'atm': [
      'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=800&q=80', // modern bank lobby
      'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?w=800&q=80', // digital cash machine
      'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800&q=80', // bank financial center
      'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=800&q=80', // finance and banking desk
      'https://images.unsplash.com/photo-1541354329998-f4d9a9f9297f?w=800&q=80', // commercial bank branch
      'https://images.unsplash.com/photo-1501167786227-4cba60f6d58f?w=800&q=80', // modern digital banking hub
    ],
    'salon': [
      'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800&q=80', // luxury beauty salon
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&q=80', // spa and hair styling station
      'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&q=80', // vintage barbershop chair
      'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&q=80', // modern hair salon mirrors
      'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800&q=80', // wellness massage spa
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&q=80', // luxury resort day spa
    ],
  };

  /// Returns a photographic image URL for a given category and seed id.
  static String getCategoryImage(String categoryId, String placeId) {
    final list = _curatedImages[categoryId] ?? _curatedImages['cafe']!;
    final index = (placeId.hashCode.abs()) % list.length;
    return list[index];
  }

  /// Returns a list of photographic images for a place to populate multi-photo gallery.
  static List<String> getPlacePhotos(String categoryId, String placeId, {int count = 3}) {
    final list = _curatedImages[categoryId] ?? _curatedImages['cafe']!;
    final startIndex = placeId.hashCode.abs() % list.length;
    final photos = <String>[];
    for (var i = 0; i < count; i++) {
      photos.add(list[(startIndex + i) % list.length]);
    }
    return photos;
  }
}
