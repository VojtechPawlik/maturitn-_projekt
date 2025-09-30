🧩 Název projektu:
Virtuální sázková aplikace na fotbalové zápasy

✅ Cíle a kritéria projektu:
Projekt bude simulovat sázení na skutečné fotbalové zápasy za virtuální měnu.
Uživatelé budou moci soutěžit mezi sebou v rámci přátelských žebříčků.

🎯 Funkční požadavky:
Zobrazení reálných zápasů (Top 5 evropských lig + evropské poháry)
Možnost sázet na zápasy (výsledek 1/X/2) za virtuální měnu
Automatické vyhodnocení sázek po skončení zápasů
Registrace a přihlášení uživatelů
Zůstatek účtu a historie sázek
Přidávání kamarádů a soukromé žebříčky
Globální leaderboard
Admin rozhraní pro správu dat a zápasů

🔨 Použité technologie:
Vrstva	Technologie
Frontend (mobilní)	Flutter (Dart)
Backend / API	Django + Django REST Framework
Databáze	PostgreSQL (nebo SQLite pro vývoj)
Reálná data zápasů	API-Football (REST API)
Autentizace	JWT (Token-based authentication)
Závislosti backendu	Python, pip, virtualenv

📆 Fáze projektu (časový plán):
Fáze	Popis	Technologie	Výstup

1. Analýza a návrh	Návrh funkcí, databáze, UI mockupy	Figma, dbdiagram.io	ER diagram, návrhy obrazovek

2. Backend – základ	Vytvoření Django projektu, modely a API struktura	Django ORM	REST API (uživatelé, zápasy)

3. API integrace	Napojení na API-Football, ukládání zápasů	Django, requests	Automatické stahování zápasů

4. Flutter UI	První verze appky – login, seznam zápasů	Flutter	Prototyp mobilní appky

5. Funkce sázení	Logika sázení, výpočty výsledků, virtuální měna	Django + Flutter	Kompletní sázkový systém

6. Sociální prvky	Přátelé, žebříčky, leaderboard	Django + Flutter	Přátelské soutěžení

7. Testování a ladění	Testy, opravy, validace dat	Pytest, Flutter Test	Hotová, stabilní aplikace

8. Dokumentace	README, prezentace, obhajoba	Markdown / PDF	Prezentace projektu

🗓️ Harmonogram (září–leden):
Měsíc	Aktivita

Září	Analýza zadání, návrh funkcí a databázové struktury (ER diagram)

Říjen	Backend – vytvoření Django modelů a API, napojení na fotbalové API

Listopad	Vývoj Flutter UI, přidání funkcí sázení a uživatelského účtu

Prosinec	Implementace přátel, žebříčku, historie sázek, testování

Leden	Finální ladění, tvorba dokumentace, prezentace a obhajoba projektu

📚 Zdroje:
API pro fotbalová data:
API-Football – https://www.api-football.com/
Frameworky a technologie:
Django – https://www.djangoproject.com/
Django REST Framework – https://www.django-rest-framework.org/
Flutter – https://flutter.dev/
Dart – https://dart.dev/
PostgreSQL – https://www.postgresql.org/
JWT – https://jwt.io/
Návrh databáze:
dbdiagram.io – https://dbdiagram.io
Návrh UI:
Figma – https://www.figma.com/
Testování:
Pytest – https://docs.pytest.org/
Flutter Testing – https://docs.flutter.dev/testing
