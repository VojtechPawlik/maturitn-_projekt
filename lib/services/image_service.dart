import 'dart:math';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Simulace výběru obrázku z galerie s dialogy
  Future<String?> pickImageFromGallery() async {
    try {
      // Zobrazit dialog jako by se otevírala galerie
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Pro testování - vraťme různé cesty podle času
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (timestamp % 3 == 0) {
        // Simulujeme že uživatel zrušil výběr
        return null;
      }
      
      // Simulujeme že uživatel vybral obrázek
      await Future.delayed(const Duration(milliseconds: 800));
      final fileName = 'gallery_image_${Random().nextInt(10000)}.jpg';
      return 'profile_images/$fileName';
    } catch (e) {
      return null;
    }
  }

  // Simulace pořízení fotky kamerou s dialogy  
  Future<String?> takePhotoWithCamera() async {
    try {
      // Zobrazit dialog jako by se otevírala kamera
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Pro testování - vraťme různé výsledky
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (timestamp % 4 == 0) {
        // Simulujeme že uživatel zrušil focení
        return null;
      }
      
      // Simulujeme že uživatel pořídil fotku
      await Future.delayed(const Duration(milliseconds: 1200));
      final fileName = 'camera_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return 'profile_images/$fileName';
    } catch (e) {
      return null;
    }
  }

  // Smazat profilový obrázek
  Future<bool> deleteProfileImage(String imagePath) async {
    try {
      // Pro testování jen vraťme true
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Zkontrolovat zda soubor existuje
  Future<bool> imageExists(String imagePath) async {
    try {
      // Pro testování vraťme true pokud path není prázdný
      return imagePath.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}