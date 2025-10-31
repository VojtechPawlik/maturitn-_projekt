import 'dart:io';
import 'dart:math';

class RealImageService {
  static final RealImageService _instance = RealImageService._internal();
  factory RealImageService() => _instance;
  RealImageService._internal();

  // Simulace výběru z galerie - více realistická
  Future<File?> pickImageFromGallery() async {
    try {
      print('🖼️ Simulace: Otevírám galerii...');
      
      // Simulace času načítání galerie
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 70% šance že uživatel "zruší" výběr (realistické)
      final random = Random().nextInt(10);
      if (random < 7) {
        print('❌ Simulace: Uživatel nezvolil žádný obrázek');
        return null;
      }
      
      // 30% šance "úspěchu"
      print('✅ Simulace: Obrázek byl vybrán');
      return File('fake_gallery_${Random().nextInt(10000)}.jpg');
      
    } catch (e) {
      print('❌ Chyba při simulaci galerie: $e');
      return null;
    }
  }

  // Simulace focení kamerou
  Future<File?> takePhotoWithCamera() async {
    try {
      print('📷 Simulace: Otevírám kameru...');
      
      // Simulace času focení
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // 60% šance že uživatel "zruší" focení
      final random = Random().nextInt(10);
      if (random < 6) {
        print('❌ Simulace: Focení bylo zrušeno');
        return null;
      }
      
      // 40% šance "úspěchu"
      print('✅ Simulace: Fotka byla pořízena');
      return File('fake_camera_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
    } catch (e) {
      print('❌ Chyba při simulaci kamery: $e');
      return null;
    }
  }

  // Uložení obrázku
  Future<String?> saveImageToAppDirectory(File imageFile) async {
    try {
      print('💾 Simulace: Ukládám obrázek...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('✅ Simulace: Obrázek uložen jako $fileName');
      return 'app_directory/$fileName';
      
    } catch (e) {
      print('❌ Chyba při ukládání: $e');
      return null;
    }
  }

  // Smazání obrázku
  Future<bool> deleteImage(String imagePath) async {
    try {
      print('🗑️ Simulace: Mazám obrázek');
      await Future.delayed(const Duration(milliseconds: 200));
      print('✅ Simulace: Obrázek smazán');
      return true;
    } catch (e) {
      print('❌ Chyba při mazání: $e');
      return false;
    }
  }
}