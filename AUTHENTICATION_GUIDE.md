# Přihlašovací systém - Dokumentace

## Implementované funkce

### 1. Autentizační služba (AuthService)
Umístění: `lib/services/auth_service.dart`

**Podporované metody přihlášení:**
- ✅ Email a heslo (registrace + přihlášení)
- ✅ Google Sign In
- ✅ Sign in with Apple (pouze iOS/macOS)
- ✅ Reset hesla přes email

**Funkce "Zůstat přihlášen":**
- ✅ Použití SharedPreferences pro persistenci
- ✅ Automatické ukládání předvolby při přihlášení

### 2. Přihlašovací obrazovka (LoginScreen)
Umístění: `lib/screens/login_screen.dart`

**Funkce:**
- ✅ Přihlášení emailem a heslem
- ✅ Přihlášení přes Google
- ✅ Přihlášení přes Apple (iOS/macOS)
- ✅ Checkbox "Zůstat přihlášen"
- ✅ Reset zapomenutého hesla
- ✅ Navigace na registrační obrazovku
- ✅ Loading indikátory
- ✅ Error handling s českými hláškami

### 3. Registrační obrazovka (RegisterScreen)
Umístění: `lib/screens/register_screen.dart`

**Funkce:**
- ✅ Registrace emailem a heslem
- ✅ Validace silného hesla
- ✅ Potvrzení hesla
- ✅ Jméno a příjmení uživatele
- ✅ Error handling

### 4. Integrace do hlavní aplikace (main.dart)
**Změny:**
- ✅ StreamBuilder pro sledování auth stavu
- ✅ Dynamické zobrazení uživatele v AppBar
- ✅ Menu s informacemi o přihlášeném uživateli
- ✅ Funkce odhlášení

## Konfigurace Firebase

### Potřebné kroky pro dokončení:

1. **Firebase Console:**
   - Přejděte na https://console.firebase.google.com
   - Vyberte váš projekt
   - Povolte Authentication v levém menu
   - V záložce "Sign-in method" povolte:
     - Email/Password
     - Google
     - Apple (pro iOS)

2. **Generování Firebase konfigurace:**
   ```bash
   # Nainstalujte FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Nakonfigurujte projekt
   flutterfire configure
   ```

3. **Google Sign In konfigurace:**
   - Android: Automaticky nakonfigurováno přes `google-services.json`
   - iOS: Automaticky nakonfigurováno přes `GoogleService-Info.plist`

4. **Apple Sign In konfigurace (pouze iOS):**
   - V Xcode otevřete `ios/Runner.xcodeproj`
   - Přidejte "Sign in with Apple" capability
   - V Apple Developer Console povolte Sign in with Apple

## Užitečné příkazy

```bash
# Instalace závislostí
flutter pub get

# Analýza kódu
flutter analyze

# Spuštění aplikace
flutter run

# Build pro release
flutter build apk  # Android
flutter build ios  # iOS
```

## Bezpečnostní doporučení

1. **Firebase Security Rules:** Nakonfigurujte pravidla pro Firestore/Storage
2. **App Check:** Povolte Firebase App Check pro ochranu API
3. **Validace na backend:** Vždy validujte data na serveru
4. **HTTPS:** Používejte pouze HTTPS komunikaci

## Testování

Pro testování jednotlivých funkcí:

1. **Email/Password:** Použijte validní email formát
2. **Google Sign In:** Vyžaduje platný Firebase projekt
3. **Apple Sign In:** Funguje pouze na fyzických iOS zařízeních
4. **Reset hesla:** Email bude odeslán pouze pro existující účty

## Možná rozšíření

- 📱 Dvoufaktorová autentizace (2FA)
- 🔐 Biometrická autentizace (Touch ID/Face ID)
- 📞 Přihlášení přes telefonní číslo
- 👥 Správa profilů uživatelů
- 🔄 Synchronizace dat napříč zařízeními
