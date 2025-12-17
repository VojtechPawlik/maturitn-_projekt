🧩 Název projektu:
Virtuální sázková aplikace na fotbalové zápasy

✅ Cíle a kritéria projektu:
Projekt bude simulovat sázení na skutečné fotbalové zápasy za virtuální měnu.
Uživatelé budou moci soutěžit mezi sebou v rámci přátelských žebříčků.

🎯 Funkční požadavky:
Zobrazení reálných zápasů (Top 5 evropských lig)
Možnost sázet na zápasy (výsledek 1/X/2) za virtuální měnu
Automatické vyhodnocení sázek po skončení zápasů
Registrace a přihlášení uživatelů
Zůstatek účtu a historie sázek
Přidávání kamarádů a soukromé žebříčky

🔨 Použité technologie:
Vrstva	Technologie
Frontend (mobilní)	Flutter (Dart)
Backend / API	Django + Django REST Framework
Databáze	Firebase
Reálná data zápasů	API-Football (REST API)

📆 Fáze projektu (časový plán):
Fáze	Popis	Technologie	Výstup

1. Analýza a návrh	Návrh funkcí, databáze, dbdiagram.io	ER diagram, návrhy obrazovek
   
2. Backend – základ	Vytvoření Django projektu, modely a API struktura	Django ORM	REST API (uživatelé, zápasy)
   
3. API integrace	Napojení na API-Football, requests	Automatické stahování zápasů
   
4. Flutter UI	První verze appky – login, seznam zápasů	Flutter	Prototyp mobilní appky
   
5. Funkce sázení	Logika sázení, výpočty výsledků, virtuální měna	Django + Flutter	Kompletní sázkový systém
    
6. Sociální prvky	Přátelé, žebříčky, leaderboard
    
7. Testování a ladění	Testy, opravy, validace dat	Pytest, Flutter Test	Hotová, stabilní aplikace
    
8. Dokumentace, prezentace, obhajoba	Markdown / PDF	Prezentace projektu
    
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
Flutter – https://flutter.dev/
Dart – https://dart.dev/
Firebase - https://firebase.google.com
Návrh databáze:
dbdiagram.io – https://dbdiagram.io
Testování:
Flutter Testing – https://docs.flutter.dev/testing
