# Nastavení Firebase Authentication

## Krok 1: Povolení Email/Password Authentication

1. **Otevři Firebase Console:**
   - Jdi na https://console.firebase.google.com
   - Vyber svůj projekt

2. **Naviguj do Authentication:**
   - V levém menu klikni na "Authentication"
   - Přejdi na záložku "Sign-in method"

3. **Povol Email/Password:**
   - Klikni na "Email/Password"
   - Zapni první přepínač "Email/Password"
   - Můžeš také zapnout "Email link (passwordless sign-in)" pokud chceš
   - Klikni "Save"

## Krok 2: Konfigurace Email Templates (Volitelné)

1. **Přejdi na Templates:**
   - V Authentication sekci klikni na záložku "Templates"

2. **Uprav Email verification template:**
   - Klikni na ikonu úprav u "Email address verification"
   - Můžeš upravit:
     - Subject (předmět emailu)
     - Email body (obsah emailu)
     - Sender name (jméno odesílatele)

3. **Doporučený český text:**
   ```
   Subject: Ověřte svůj email pro Fotbal Live
   
   Body:
   Dobrý den,
   
   Klikněte na tento odkaz pro ověření svého emailu v aplikaci Fotbal Live:
   %LINK%
   
   Pokud jste si nevytvářeli účet v naší aplikaci, ignorujte tento email.
   
   Děkujeme,
   Tým Fotbal Live
   ```

## Krok 3: Testování

Po nastavení můžeš testovat:

1. **Registrace:**
   - Spusť aplikaci: `flutter run`
   - Klikni na ikonu přihlášení
   - Klikni "Zaregistrujte se"
   - Vyplň údaje a klikni "Vytvořit účet"
   - Automaticky se přesměruješ na obrazovku ověření

2. **Email ověření:**
   - Zkontroluj svou emailovou schránku
   - Klikni na ověřovací odkaz
   - Aplikace by měla automaticky detekovat ověření

3. **Přihlášení:**
   - Vrať se na přihlašovací obrazovku
   - Zadej své údaje
   - Pokud email není ověřen, zobrazí se upozornění

## Krok 4: Pokročilé nastavení (Volitelné)

### Vlastní doména pro emaily:
- V Templates sekci můžeš nastavit vlastní doménu
- Vyžaduje DNS konfiguraci

### Security Rules:
Pokud budeš používat Firestore, přidej tato pravidla:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Povolit čtení/zápis pouze ověřeným uživatelům
    match /{document=**} {
      allow read, write: if request.auth != null && request.auth.token.email_verified;
    }
  }
}
```

## Řešení problémů

### Email nepřichází:
- Zkontroluj spam složku
- Zkontroluj, zda je v Firebase povolený Email/Password
- Zkontroluj kvóty Firebase projektu

### Aplikace spadne:
- Zkontroluj, zda máš správně nakonfigurovaný `firebase_options.dart`
- Spusť `flutter clean && flutter pub get`

### Ověření nefunguje:
- Zkontroluj internetové připojení
- Ujisti se, že používáš stejný email jako při registraci
