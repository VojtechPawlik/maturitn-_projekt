🧩 Název projektu

Virtuální sázková aplikace na fotbalové zápasy – **Strike!**

---

### 📝 Co je tento projekt

Virtuální sázková aplikace na fotbalové zápasy, která:

- **simuluje sázení** na reálné fotbalové zápasy za **virtuální měnu (ne za skutečné peníze)**,
- umožňuje **soutěžit s kamarády** v rámci soukromých žebříčků,
- zobrazuje **aktuální zápasy, kurzy a výsledky** z top evropských lig.

Aplikace slouží jako **maturitní projekt** – kombinuje práci s reálným API (API-Football), moderním mobilním vývojem (Flutter) a backendem (Django / Firebase).

Video ukázka a prezentace projektu je na YouTube:  
`https://www.youtube.com/watch?v=z0Bxu2MON9s`
---

### ✅ Cíle a kritéria projektu

- **Simulace sázení** na skutečné fotbalové zápasy za virtuální měnu.
- **Bezpečné prostředí** – žádné reálné peníze, čistě studijní/projektové využití.
- **Soutěžení mezi uživateli** v rámci:
  - globálního leaderboardu,
  - soukromých žebříčků s kamarády.
- **Přehledná mobilní aplikace** pro Android/iOS s moderním UI.
- **Použití reálného API** pro fotbalová data (API-Football).
- **Dodržení harmonogramu** (září–leden) a dokumentace pro obhajobu.

---

### 🎯 Funkční požadavky

- **Zobrazení reálných zápasů**
  - Top 5 evropských lig (Premier League, La Liga, Bundesliga, Serie A, Ligue 1) + evropské poháry.
  - Detail zápasu, průběh, výsledky.
- **Možnost sázet na zápasy**
  - Výsledek 1 / X / 2 za virtuální měnu.
  - Práce s kurzy (z API-Football, případně výchozí hodnoty).
- **Automatické vyhodnocení sázek**
  - Po skončení zápasu se sázky automaticky přepočítají.
  - Aktualizace virtuálního zůstatku uživatele.
- **Uživatelský účet**
  - Registrace a přihlášení uživatelů.
  - Zůstatek účtu a historie sázek.
- **Sociální prvky**
  - Přidávání kamarádů.
  - Soukromé žebříčky.
  - Globální leaderboard.
- **Administrace (koncept)**
  - Admin rozhraní pro správu dat a zápasů (plánovaný/oddělený backend).

---

### 🔨 Použité technologie

**Mobilní aplikace (tento repozitář):**

- **Frontend (mobilní)**: Flutter (Dart)
- **Backend funkce**: Firebase (Authentication, Firestore, Remote Config)
- **Reálná data zápasů**: API-Football (REST API přes RapidAPI)

**Backend – koncept (samostatný projekt / návrh):**

- **Backend / API**: Django + Django REST Framework
- **Databáze**: PostgreSQL (nebo SQLite pro vývoj)
- **Autentizace**: JWT (token-based authentication)
- **Závislosti backendu**: Python, pip, virtualenv

Tento repozitář se zaměřuje hlavně na **Flutter aplikaci + Firebase**. Django backend je popsán v zadání jako možná serverová vrstva pro budoucí rozšíření.

---

### ▶️ Jak projekt spustit (Flutter aplikace)

#### 1. Předpoklady

- Nainstalovaný **Flutter SDK** (viz [flutter.dev](https://flutter.dev/)).
- Nainstalovaný **Android Studio** nebo Xcode (pro Android/iOS emulátor nebo fyzické zařízení).
- Nainstalovaný **Dart** (součást Flutter SDK).
- Vytvořený projekt ve **Firebase Console** (pro mobilní aplikaci):
  - povolené **Authentication** (např. Email/Password),
  - povolený **Cloud Firestore**,
  - povolený **Remote Config**.

V repozitáři už jsou soubory `firebase_options.dart` a konfigurace pro platformy (`GoogleService-Info.plist`, `google-services.json`). Pokud spouštíš projekt na **jiném Firebase projektu**, je potřeba tyto soubory znovu vygenerovat pomocí `flutterfire configure`.

#### 2. Naklonování repozitáře

```bash
git clone <url_tohoto_repozitáře>
cd maturitn-_projekt
```

#### 3. Instalace závislostí

```bash
flutter pub get
```

#### 4. Nastavení API-Football klíče (Remote Config)

V aplikaci se používá služba `ApiFootballService`, která načítá klíč přes **Firebase Remote Config** (`api_football_key`).

1. Otevři **Firebase Console** → Remote Config.
2. Vytvoř nový parametr:
   - **Název**: `api_football_key`
   - **Hodnota**: tvůj API klíč z API-Football / RapidAPI.
3. Publikuj změny.

Při spuštění aplikace se klíč načte a použije v API požadavcích.

#### 5. Spuštění aplikace

Připoj zařízení nebo spusť emulátor a poté:

```bash
flutter run
```

Flutter si vybere výchozí připojené zařízení (Android, iOS, web – podle konfigurace).  
Pro konkrétní platformu můžeš použít např.:

```bash
flutter run -d chrome        # web
flutter run -d emulator-5554 # konkrétní Android emulátor
```

#### 6. Spuštění testů

Základní widget testy:

```bash
flutter test
```

---

### 📆 Fáze projektu (časový plán)

**Fáze – Popis – Technologie – Výstup**

1. **Analýza a návrh**  
   Návrh funkcí, databáze, UI mockupy  
   **Technologie**: Figma, dbdiagram.io  
   **Výstup**: ER diagram, návrhy obrazovek, specifikace funkcí.

2. **Backend – základ** (návrh / koncept)  
   Vytvoření Django projektu, modely a API struktura  
   **Technologie**: Django ORM, Django REST Framework  
   **Výstup**: REST API (uživatelé, zápasy, sázky).

3. **API integrace**  
   Napojení na API-Football, ukládání zápasů / čtení dat  
   **Technologie**: Django/Flutter, `http`, `requests`  
   **Výstup**: Automatické stahování zápasů a kurzů.

4. **Flutter UI**  
   První verze appky – login, seznam zápasů, základní navigace  
   **Technologie**: Flutter  
   **Výstup**: Prototyp mobilní appky.

5. **Funkce sázení**  
   Logika sázení, výpočty výsledků, virtuální měna  
   **Technologie**: Flutter + Firebase (případně Django)  
   **Výstup**: Kompletní sázkový systém.

6. **Sociální prvky**  
   Přátelé, žebříčky, leaderboard  
   **Technologie**: Flutter + Firebase / Django API  
   **Výstup**: Přátelské soutěžení mezi uživateli.

7. **Testování a ladění**  
   Testy, opravy, validace dat  
   **Technologie**: Flutter Test, případně Pytest pro backend  
   **Výstup**: Hotová, stabilní aplikace.

8. **Dokumentace, prezentace, obhajoba**  
   Příprava README, prezentace, video, dokumentace k obhajobě  
   **Technologie**: Markdown / PDF, prezentační nástroje  
   **Výstup**: Materiály pro prezentaci a obhajobu projektu.

---

### 🗓️ Harmonogram (září–leden)

**Měsíc – Aktivita**

- **Září**  
  Analýza zadání, návrh funkcí a databázové struktury (ER diagram), hrubé UI náčrty.

- **Říjen**  
  Návrh a implementace backendu (pokud je použit), vytvoření Django modelů a API, napojení na fotbalové API (API-Football).

- **Listopad**  
  Vývoj Flutter UI, přidání funkcí sázení a uživatelského účtu, integrace s Firebase.

- **Prosinec**  
  Implementace přátel, žebříčku, historie sázek, testování, ladění chyb.

- **Leden**  
  Finální ladění, tvorba dokumentace, příprava prezentace a obhajoby projektu.

---

### 📚 Zdroje

- **API pro fotbalová data:**
  - API-Football – `https://www.api-football.com/`

- **Frameworky a technologie:**
  - Flutter – `https://flutter.dev/`
  - Dart – `https://dart.dev/`
  - Firebase – `https://firebase.google.com`
  - (Koncept backendu) Django – `https://www.djangoproject.com/`
  - (Koncept backendu) Django REST Framework – `https://www.django-rest-framework.org/`

- **Návrh databáze:**
  - dbdiagram.io – `https://dbdiagram.io`

- **Návrh UI:**
  - Figma – `https://www.figma.com/`

- **Testování:**
  - Flutter Testing – `https://docs.flutter.dev/testing`
  - (Backend) Pytest – `https://docs.pytest.org/`
