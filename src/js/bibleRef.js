// bible_ref.js

var parser = require('./parser.js');
var bookName = {
    "1ch": "1 chronicles", "1 chronicles": "1 chronicles",  "1 chron": "1 chronicles", "1 ch": "1 chronicles", "i ch": "1 chronicles", "1 chr": "1 chronicles", "i chr": "1 chronicles", "1chr": "1 chronicles", "i chron": "1 chronicles", "1chron": "1 chronicles", "i chronicles": "1 chronicles", "1chronicles": "1 chronicles", "1st chronicles": "1 chronicles", "first chronicles": "1 chronicles",
    "1co": "1 corinthians", "1 corinthians": "1 corinthians", "1 cor": "1 corinthians", "1 co": "1 corinthians", "i co": "1 corinthians", "i cor": "1 corinthians", "1cor": "1 corinthians", "i corinthians": "1 corinthians", "1corinthians": "1 corinthians", "1st corinthians": "1 corinthians", "first corinthians": "1 corinthians",
    "1es": "1 esdras", "1 esdras": "1 esdras",  "1 esdr": "1 esdras", "1 esd": "1 esdras", "i es": "1 esdras", "1es": "1 esdras", "i esd": "1 esdras", "1esd": "1 esdras", "i esdr": "1 esdras", "1esdr": "1 esdras", "i esdras": "1 esdras", "1esdras": "1 esdras", "1st esdras": "1 esdras", "first esdras": "1 esdras",
    "1jn": "1 john", "1 john": "1 john",  "1 jn": "1 john", "i jn": "1 john", "i jo": "1 john", "1jo": "1 john", "i joh": "1 john", "1joh": "1 john", "i jhn": "1 john", "1 jhn": "1 john", "1jhn": "1 john", "i john": "1 john", "1john": "1 john", "1st john": "1 john", "first john": "1 john",
    "1ki": "1 kings", "1 kings": "1 kings", "1 kgs": "1 kings", "1 ki": "1 kings", "1k": "1 kings", "i kgs": "1 kings", "1kgs": "1 kings", "i ki": "1 kings", "i kings": "1 kings", "1kings": "1 kings", "1st kgs": "1 kings", "1st kings": "1 kings", "first kings": "1 kings", "first kgs": "1 kings", "1kin": "1 kings",
    "1ma": "1 maccabees", "1 maccabees": "1 maccabees", "1 macc": "1 maccabees", "1 mac": "1 maccabees", "1m": "1 maccabees", "i ma": "1 maccabees", "i mac": "1 maccabees", "1mac": "1 maccabees", "i macc": "1 maccabees", "1macc": "1 maccabees", "i maccabees": "1 maccabees", "1maccabees": "1 maccabees", "1st maccabees": "1 maccabees", "first maccabees": "1 maccabees",
    "1pe": "1 peter", "1 peter": "1 peter", "1 pet": "1 peter", "1 pe": "1 peter", "i pe": "1 peter", "i pet": "1 peter", "1pet": "1 peter", "i pt": "1 peter", "1 pt": "1 peter", "1pt": "1 peter", "i peter": "1 peter", "1peter": "1 peter", "1st peter": "1 peter", "first peter": "1 peter",
    "1sa": "1 samuel", "1 samuel": "1 samuel",  "1 sam": "1 samuel", "1 sa": "1 samuel", "1samuel": "1 samuel", "1s": "1 samuel", "i sa": "1 samuel", "1 sm": "1 samuel", "i sam": "1 samuel", "1sam": "1 samuel", "i samuel": "1 samuel", "1st samuel": "1 samuel", "first samuel": "1 samuel",
    "1th": "1 thessalonians", "1 thessalonians": "1 thessalonians", "1 thess": "1 thessalonians", "1 th": "1 thessalonians", "i th": "1 thessalonians", "i thes": "1 thessalonians", "1thes": "1 thessalonians", "i thess": "1 thessalonians", "1thess": "1 thessalonians", "i thessalonians": "1 thessalonians", "1thessalonians": "1 thessalonians", "1st thessalonians": "1 thessalonians", "first thessalonians": "1 thessalonians",
    "1ti": "1 timothy", "1 timothy": "1 timothy", "1 tim": "1 timothy", "1 ti": "1 timothy", "i ti": "1 timothy", "i tim": "1 timothy", "1tim": "1 timothy", "i timothy": "1 timothy", "1timothy": "1 timothy", "1st timothy": "1 timothy", "first timothy": "1 timothy",
    "2ch": "2 chronicles", "2 chronicles": "2 chronicles",  "2 chron": "2 chronicles", "2 ch": "2 chronicles", "ii ch": "2 chronicles", "ii chr": "2 chronicles", "2 chr": "2 chronicles", "ii chron": "2 chronicles", "2chron": "2 chronicles", "ii chronicles": "2 chronicles", "2chronicles": "2 chronicles", "2nd chronicles": "2 chronicles", "second chronicles": "2 chronicles",
    "2co": "2 corinthians", "2 corinthians": "2 corinthians", "2 cor": "2 corinthians", "2 co": "2 corinthians", "ii co": "2 corinthians", "ii cor": "2 corinthians", "2cor": "2 corinthians", "ii corinthians": "2 corinthians", "2corinthians": "2 corinthians", "2nd corinthians": "2 corinthians", "second corinthians": "2 corinthians",
    "2es": "2 esdras", "2 esdras": "2 esdras",  "2 esdr": "2 esdras", "2 esd": "2 esdras", "ii es": "2 esdras", "ii esd": "2 esdras", "2esd": "2 esdras", "ii esdr": "2 esdras", "2esdr": "2 esdras", "ii esdras": "2 esdras", "2esdras": "2 esdras", "2nd esdras": "2 esdras", "second esdras": "2 esdras",
    "2jn": "2 john", "2 john": "2 john", "2 jn": "2 john", "ii jn": "2 john", "ii jo": "2 john", "2jo": "2 john", "ii joh": "2 john", "2joh": "2 john", "ii jhn": "2 john", "2 jhn": "2 john", "2jhn": "2 john", "ii john": "2 john", "2john": "2 john", "2nd john": "2 john", "second john": "2 john",
    "2ki": "2 kings", "2 kings": "2 kings", "2 kgs": "2 kings", "2 ki": "2 kings", "2k": "2 kings", "ii kgs": "2 kings", "2kgs": "2 kings", "ii ki": "2 kings", "ii kings": "2 kings", "2kings": "2 kings", "2nd kgs": "2 kings", "2nd kings": "2 kings", "second kings": "2 kings", "second kgs": "2 kings", "2kin": "2 kings",
    "2ma": "2 maccabees", "2 maccabees": "2 maccabees", "2 macc": "2 maccabees", "2 mac": "2 maccabees", "2m": "2 maccabees", "ii ma": "2 maccabees", "ii mac": "2 maccabees", "2mac": "2 maccabees", "ii macc": "2 maccabees", "2macc": "2 maccabees", "ii maccabees": "2 maccabees", "2maccabees": "2 maccabees", "2nd maccabees": "2 maccabees", "second maccabees": "2 maccabees",
    "2pe": "2 peter", "2 peter": "2 peter", "2 pet": "2 peter", "2 pe": "2 peter", "ii pe": "2 peter", "ii pet": "2 peter", "2pet": "2 peter", "ii pt": "2 peter", "2 pt": "2 peter", "2pt": "2 peter", "ii peter": "2 peter", "2peter": "2 peter", "2nd peter": "2 peter", "second peter": "2 peter",
    "2sa": "2 samuel", "2 samuel": "2 samuel",  "2 sam": "2 samuel", "2 sa": "2 samuel", "2s": "2 samuel", "ii sa": "2 samuel", "2 sm": "2 samuel", "ii sam": "2 samuel", "2sam": "2 samuel", "ii samuel": "2 samuel", "2samuel": "2 samuel", "2nd samuel": "2 samuel", "second samuel": "2 samuel",
    "2th": "2 thessalonians", "2 thessalonians": "2 thessalonians", "2 thess": "2 thessalonians", "2 th": "2 thessalonians", "ii th": "2 thessalonians", "ii thes": "2 thessalonians", "2thes": "2 thessalonians", "ii thess": "2 thessalonians", "2thess": "2 thessalonians", "ii thessalonians": "2 thessalonians", "2thessalonians": "2 thessalonians", "2nd thessalonians": "2 thessalonians", "second thessalonians": "2 thessalonians",
    "2ti": "2 timothy", "2 timothy": "2 timothy", "2 tim": "2 timothy", "2 ti": "2 timothy", "ii ti": "2 timothy", "ii tim": "2 timothy", "2tim": "2 timothy", "ii timothy": "2 timothy", "2timothy": "2 timothy", "2nd timothy": "2 timothy", "second timothy": "2 timothy",
    "3jn": "3 john", "3 john": "3 john", "3 jn": "3 john", "iii jn": "3 john", "iii jo": "3 john", "3jo": "3 john", "iii joh": "3 john", "3joh": "3 john", "iii jhn": "3 john", "3 jhn": "3 john", "3jhn": "3 john", "iii john": "3 john", "3john": "3 john", "3rd john": "3 john", "third john": "3 john",
    "3ma": "3 maccabees", "3 maccabees": "3 maccabees", "3 macc": "3 maccabees", "3 mac": "3 maccabees", "iii ma": "3 maccabees", "iii mac": "3 maccabees", "3mac": "3 maccabees", "iii macc": "3 maccabees", "3macc": "3 maccabees", "iii maccabees": "3 maccabees", "3rd maccabees": "3 maccabees", "third maccabees": "3 maccabees",
    "4ma": "4 maccabees", "4 maccabees": "4 maccabees", "4 macc": "4 maccabees", "4 mac": "4 maccabees", "iv ma": "4 maccabees", "iv mac": "4 maccabees", "4mac": "4 maccabees", "iv macc": "4 maccabees", "4macc": "4 maccabees", "iv maccabees": "4 maccabees", "iiii maccabees": "4 maccabees", "4maccabees": "4 maccabees", "4th maccabees": "4 maccabees", "fourth maccabees": "4 maccabees",
    "act": "acts", "acts": "acts",  "ac": "acts",
    "additional psalm": "additional psalm",  "add psalm": "additional psalm", "add ps": "additional psalm",
    "additions to esther": "additions to esther", "add esth": "additions to esther", "add es": "additions to esther", "rest of esther": "additions to esther", "the rest of esther": "additions to esther", "aes": "additions to esther", "addesth": "additions to esther",
    "amo": "amos", "amos": "amos",  "am": "amos",
    "bar": "baruch", "baruch": "baruch",  
    "bel and the dragon": "bel and the dragon",  "bel": "bel and the dragon",
    "col": "colossians", "colossians": "colossians",  
    "dan": "daniel", "daniel": "daniel",  "da": "daniel", "dn": "daniel",
    "deu": "deuteronomy", "deuteronomy": "deuteronomy", "deut": "deuteronomy", "dt": "deuteronomy",
    "ecc": "ecclesiastes", "ecclesiastes": "ecclesiastes",  "eccles": "ecclesiastes", "ec": "ecclesiastes", "eccl": "ecclesiastes", "qoh": "ecclesiastes", "qoheleth": "ecclesiastes",
    "eph": "ephesians", "ephesians": "ephesians", "ephes": "ephesians", 
    "epistle to the laodiceans": "epistle to the laodiceans", "laodiceans": "epistle to the laodiceans", "laod": "epistle to the laodiceans", "ep laod": "epistle to the laodiceans", "epist laodiceans": "epistle to the laodiceans", "epistle laodiceans": "epistle to the laodiceans", "epistle to laodiceans": "epistle to the laodiceans",
    "est": "esther", "esther": "esther",  "esth": "esther", "es": "esther",
    "exo": "exodus", "exodus": "exodus",  "ex": "exodus", "exod": "exodus",
    "ezk": "ezekiel", "ezekiel": "ezekiel", "ezek": "ezekiel", "eze": "ezekiel", 
    "ezr": "ezra", "ezra": "ezra", 
    "gal": "galatians", "galatians": "galatians", "ga": "galatians",
    "gen": "genesis", "genesis": "genesis", "ge": "genesis", "gn": "genesis",
    "hab": "habakkuk", "habakkuk": "habakkuk",  
    "hag": "haggai", "haggai": "haggai",  "hg": "haggai",
    "heb": "hebrews","hebrews": "hebrews",  
    "hos": "hosea", "hosea": "hosea", "ho": "hosea",
    "isa": "isaiah", "isaiah": "isaiah",  "is": "isaiah",
    "jas": "james", "james": "james", "jm": "james",
    "jer": "jeremiah", "jeremiah": "jeremiah",  "je": "jeremiah", "jr": "jeremiah",
    "job": "job", "jb": "job",
    "jol": "joel", "joel": "joel", "joe": "joel", "jl": "joel",
    "jhn": "john", "john": "john",  "jn": "john", 
    "jon": "jonah","jonah": "jonah", "jnh": "jonah", 
    "jos": "joshua", "joshua": "joshua",  "josh": "joshua", "jsh": "joshua",
    "jud": "jude", "jude": "jude",  
    "jdg": "judges", "judges": "judges",  "judg": "judges", "jg": "judges", "jdgs": "judges",
    "jdt": "judith", "judith": "judith",  "jdth": "judith", "jth": "judith",
    "lam": "lamentations", "lamentations": "lamentations",  "la": "lamentations",
    "letter of jeremiah": "letter of jeremiah", "let jer": "letter of jeremiah", "lje": "letter of jeremiah", "ltr jer": "letter of jeremiah",
    "lev": "leviticus", "leviticus": "leviticus", "le": "leviticus", "lv": "leviticus",
    "luk": "luke", "luke": "luke",  "lk": "luke",
    "mal": "malachi", "malachi": "malachi", "ml": "malachi",
    "mrk": "mark", "mark": "mark",  "mk": "mark", "mr": "mark",
    "mat": "matthew", "matthew": "matthew", "matt": "matthew", "mt": "matthew",
    "mic": "micah","micah": "micah",  
    "nah": "nahum", "nahum": "nahum", "na": "nahum",
    "neh": "nehemiah", "nehemiah": "nehemiah",  "ne": "nehemiah",
    "num": "numbers", "numbers": "numbers", "nu": "numbers", "nm": "numbers", "nb": "numbers",
    "oba": "obadiah", "obadiah": "obadiah", "obad": "obadiah", "ob": "obadiah",
    "ode": "ode", // WHATS THIS SUPPOSED TO BE?
    "phm": "philemon", "philemon": "philemon", 
    "php": "philippians", "philippians": "philippians", "phil": "philippians", "php": "philippians",
    "man": "prayer of manasseh", "prayer of manasseh": "prayer of manasses",  "pr of man": "prayer of manasses", "pr man": "prayer of manasses", "pma": "prayer of manasses", "prayer of manasses": "prayer of manasses",
    "pro": "proverbs", "proverbs": "proverbs",  "prov": "proverbs", "pr": "proverbs", "prv": "proverbs",
    "psa": "psalms", "psalm": "psalms", "pslm": "psalms", "ps": "psalms", "psalms": "psalms", "psa": "psalms", "psm": "psalms", "pss": "psalms",
    "psalms of solomon": "psalms of solomon", "ps solomon": "psalms of solomon", "ps sol": "psalms of solomon", "psalms solomon": "psalms of solomon", "pssol": "psalms of solomon",
    "rev": "revelation", "revelation": "revelation",  "re": "revelation", "the revelation": "revelation",
    "rom": "romans", "romans": "romans",  "ro": "romans", "rm": "romans",
    "rut": "ruth",  "ruth": "ruth",  "rth": "ruth", "ru": "ruth",
    "sir": "sirach", "sirach": "sirach",  "ecclesiasticus": "sirach", "ecclus": "sirach",
    "sng": "song of solomon", "song of solomon": "song of solomon", "song": "song of solomon", "so": "song of solomon", "canticle of canticles": "song of solomon", "canticles": "song of solomon", "song of songs": "song of solomon", "sos": "song of solomon",
    "song of three youths": "song of three youths",  "song of three": "song of three youths", "song thr": "song of three youths", "the song of three youths": "song of three youths", "pr az": "song of three youths", "prayer of azariah": "song of three youths", "azariah": "song of three youths", "the song of the three holy children": "song of three youths", "the song of three jews": "song of three youths", "song of the three holy children": "song of three youths", "song of thr": "song of three youths", "song of three children": "song of three youths", "song of three jews": "song of three youths",
    "susanna": "susanna",  "sus": "susanna",
    "tit": "titus", "titus": "titus",  
    "tob": "tobit", "tobit": "tobit",  "tb": "tobit",
    "wis": "wisdom of solomon", "wisdom of solomon": "wisdom of solomon", "wisd of sol": "wisdom of solomon", "wisd": "wisdom of solomon", "ws": "wisdom of solomon", "wisdom": "wisdom of solomon",
    "zec": "zechariah", "zechariah": "zechariah", "zech": "zechariah", "zc": "zechariah",
    "zep": "zephaniah", "zephaniah": "zephaniah", "zeph": "zephaniah", "zp": "zephaniah",
  }

  var web_names = {
    "1 chronicles" :  "1CH",
    "1 corinthians" :  "1CO",
    "1 esdras" :  "1ES",
    "1 john" :  "1JN",
    "1 kings" :  "1KI",
    "1 maccabees" :  "1MA",
    "1 peter" :  "1PE",
    "1 samuel" :  "1SA",
    "1 thessalonians" :  "1TH",
    "1 timothy" :  "1TI",
    "2 chronicles" :  "2CH",
    "2 corinthians" :  "2CO",
    "2 esdras" :  "2ES",
    "2 john" :  "2JN",
    "2 kings" :  "2KI",
    "2 maccabees" :  "2MA",
    "2 peter" :  "2PE",
    "2 samuel" :  "2SA",
    "2 thessalonians" :  "2TH",
    "2 timothy" :  "2TI",
    "3 john" :  "3JN",
    "3 maccabees" :  "3MA",
    "4 maccabees" :  "4MA",
    "acts" :  "ACT",
    "amos" :  "AMO",
    "baruch" :  "BAR",
    "colossians" :  "COL",
    "daniel (greek)" :  "DAG",
    "daniel" :  "DAN",
    "deuteronomy" :  "DEU",
    "ecclesiastes" :  "ECC",
    "ephesians" :  "EPH",
    "esther (greek)" :  "ESG",
    "esther" :  "EST",
    "exodus" :  "EXO",
    "ezekiel" :  "EZK",
    "ezra" :  "EZR",
    "galatians" :  "GAL",
    "genesis" :  "GEN",
    "glossary" :  "GLO",
    "habakkuk" :  "HAB",
    "haggai" :  "HAG",
    "hebrews" :  "HEB",
    "hosea" :  "HOS",
    "isaiah" :  "ISA",
    "james" :  "JAS",
    "jeremiah" :  "JER",
    "job" :  "JOB",
    "joel" :  "JOL",
    "john" :  "JHN",
    "jonah" :  "JON",
    "joshua" :  "JOS",
    "jude" :  "JUD",
    "judges" :  "JDG",
    "judith" :  "JDT",
    "lamentations" :  "LAM",
    "leviticus" :  "LEV",
    "luke" :  "LUK",
    "malachi" :  "MAL",
    "mark" :  "MRK",
    "matthew" :  "MAT",
    "micah" :  "MIC",
    "nahum" :  "NAM",
    "nehemiah" :  "NEH",
    "numbers" :  "NUM",
    "obadiah" :  "OBA",
    "philemon" :  "PHM",
    "philippians" :  "PHP",
    "prayer of manasses" :  "MAN",
    "preface" :  "FRT",
    "proverbs" :  "PRO",
    "psalm 151" :  "PS2",
    "psalms" :  "PSA",
    "revelation" :  "REV",
    "romans" :  "ROM",
    "ruth" :  "RUT",
    "sirach" :  "SIR",
    "song of solomon" :  "SNG",
    "titus" :  "TIT",
    "tobit" :  "TOB",
    "wisdom of solomon" :  "WIS",
    "zechariah" :  "ZEC",
    "zephaniah" :  "ZEP",  
    }

  var book_title = {
    "1 chronicles" :  "1 Chronicles",
    "1 corinthians" :  "1 Corinthians",
    "1 esdras" :  "1 Esdras",
    "1 john" :  "1 John",
    "1 kings" :  "1 Kings",
    "1 maccabees" :  "1 Maccabees",
    "1 peter" :  "1 Peter",
    "1 samuel" :  "1 Samuel",
    "1 thessalonians" :  "1 Thessalonians",
    "1 timothy" :  "1 Timothy",
    "2 chronicles" :  "2 Chronicles",
    "2 corinthians" :  "2 Corinthians",
    "2 esdras" :  "2 Esdras",
    "2 john" :  "2 John",
    "2 kings" :  "2 Kings",
    "2 maccabees" :  "2 Maccabees",
    "2 peter" :  "2 Peter",
    "2 samuel" :  "2 Samuel",
    "2 thessalonians" :  "2 Thessalonians",
    "2 timothy" :  "2 Timothy",
    "3 john" :  "3 John",
    "3 maccabees" :  "3 Maccabees",
    "4 maccabees" :  "4 Maccabees",
    "acts" :  "Acts",
    "amos" :  "Amos",
    "baruch" :  "Baruch",
    "colossians" :  "Colossians",
    "daniel (greek)" :  "Daniel (Greek)",
    "daniel" :  "Daniel",
    "deuteronomy" :  "Deuteronomy",
    "ecclesiastes" :  "Ecclesiastes",
    "ephesians" :  "Ephesians",
    "esther (greek)" :  "Esther (Greek)",
    "esther" :  "Esther",
    "exodus" :  "Exodus",
    "ezekiel" :  "Ezekiel",
    "ezra" :  "Ezra",
    "galatians" :  "Galatians",
    "genesis" :  "Genesis",
    "glossary" :  "Glossary",
    "habakkuk" :  "Habakkuk",
    "haggai" :  "Haggai",
    "hebrews" :  "Hebrews",
    "hosea" :  "Hosea",
    "isaiah" :  "Isaiah",
    "james" :  "James",
    "jeremiah" :  "Jeremiah",
    "job" :  "Job",
    "joel" :  "Joel",
    "john" :  "John",
    "jonah" :  "Jonah",
    "joshua" :  "Joshua",
    "jude" :  "Jude",
    "judges" :  "Judges",
    "judith" :  "Judith",
    "lamentations" :  "Lamentations",
    "leviticus" :  "Leviticus",
    "luke" :  "Luke",
    "malachi" :  "Malachi",
    "mark" :  "Mark",
    "matthew" :  "Matthew",
    "micah" :  "Micah",
    "nahum" :  "Nahum",
    "nehemiah" :  "Nehemiah",
    "numbers" :  "Numbers",
    "obadiah" :  "Obadiah",
    "philemon" :  "Philemon",
    "philippians" :  "Philippians",
    "prayer of manasses" :  "Prayer of Manasses",
    "preface" :  "Preface",
    "proverbs" :  "Proverbs",
    "psalm 151" :  "Psalm 151",
    "psalms" :  "Psalms",
    "revelation" :  "Revelation",
    "romans" :  "Romans",
    "ruth" :  "Ruth",
    "sirach" :  "Sirach",
    "song of solomon" :  "Song of Solomon",
    "titus" :  "Titus",
    "tobit" :  "Tobit",
    "wisdom of solomon" :  "Wisdom of Solomon",
    "zechariah" :  "Zechariah",
    "zephaniah" :  "Zephaniah",
  }

var bookKeys = {
  "GEN": 1000000,  "EXO": 2000000,  "LEV": 3000000,  "NUM": 4000000,  "DEU": 5000000,  "JOS": 6000000, 
  "JDG": 7000000,  "RUT": 8000000,  "1SA": 9000000,  "2SA": 10000000, "1KI": 11000000, "2KI": 12000000, 
  "1CH": 13000000, "2CH": 14000000, "EZR": 15000000, "NEH": 16000000, "EST": 17000000, "JOB": 18000000, 
  "PSA": 19000000, "PRO": 20000000, "ECC": 21000000, "SNG": 22000000, "ISA": 23000000, "JER": 24000000, 
  "LAM": 25000000, "EZK": 26000000, "DAN": 27000000, "HOS": 28000000, "JOL": 29000000, "AMO": 30000000, 
  "OBA": 31000000, "JON": 32000000, "MIC": 33000000, "NAM": 34000000, "HAB": 35000000, "ZEP": 36000000, 
  "HAG": 37000000, "ZEC": 38000000, "MAL": 39000000, 
  "MAT": 40000000, "MRK": 41000000, "LUK": 42000000, "JHN": 43000000, "ACT": 44000000, "ROM": 45000000, 
  "1CO": 46000000, "2CO": 47000000, "GAL": 48000000, "EPH": 49000000, "PHP": 50000000, "COL": 51000000, 
  "1TH": 52000000, "2TH": 53000000, "1TI": 54000000, "2TI": 55000000, "TIT": 56000000, "PHM": 57000000, 
  "HEB": 58000000, "JAS": 59000000, "1PE": 60000000, "2PE": 61000000, "1JN": 62000000, "2JN": 63000000, 
  "3JN": 64000000, "JUD": 65000000, "REV": 66000000, 
  "TOB": 67000000, "JDT": 68000000, "ESG": 69000000, "WIS": 70000000, "SIR": 71000000, "BAR": 72000000, 
  "1ES": 73000000, "MAN": 74000000, "PS2": 75000000, "1MA": 76000000, "2MA": 77000000, "3MA": 78000000, 
  "2ES": 79000000, "4MA": 80000000, "DAG": 81000000, 
  "FRT": 82000000, "GLO": 83000000
}

function dbKeys(refs) {
  // this will be confusinging
  // the incoming ref is an array of references
  // each incoming reference may also resolve into multiple references
  var parsedRefs = refs.map( function(r) { return parser.parse(r) } );
  var book = web_names[bookName[parsedRefs[0].book.toLowerCase()]];
  var bookKey = bookKeys[book];
  var keys = parsedRefs.map(function(p) { 
        var r = p.refs[0]; // p.refs is a list w/ one element
        if (r.length == undefined) {

            return  { from: "web" + (bookKey + 1000 * parseInt(r.chap) + parseInt(r.vsFrom)) 
                    , to:   "web" + (bookKey + 1000 * parseInt(r.chap) + parseInt(r.vsTo))
                    } 
            }
        else { // reference spans chapters
            return  { from: "web" + (bookKey + 1000 * parseInt(r[0].chap) + parseInt(r[0].vsFrom)) 
                    , to:   "web" + (bookKey + 1000 * parseInt(r[1].chap) + parseInt(r[1].vsTo))
                    } 
      
        }
        })
    ;
  return keys;
}

function lessonTitle(book, chap, from, to) {
  return book_title[bookName[book.toLowerCase()]] + " " + chap + ":" + from + "-" + to
}

function lessonTitleFromKeys(keyFrom, keyTo) {
    // assumption - lessons never span books
    var bookKey = parseInt( keyFrom.substr(-8, 2).replace(/[a-zA-Z]/g, "") ) * 1000000
      , abrv = getKeyByValue(bookKeys, bookKey)
      , title = book_title[getKeyByValue(web_names, abrv)]
      , fromChap = parseInt( keyFrom.substr(-6, 3) ) // 3 chars, 6 from the end 
      , vsFrom = parseInt( keyFrom.substr(-3) ) // last 3 chars
      , toChap = parseInt( keyTo.substr(-6, 3) )
      , vsTo = parseInt( keyTo.substr(-3) )
      ;
    vsTo = (vsTo === 999) ? "end" : vsTo
    if (fromChap === toChap) {
        return title + " " + fromChap + ":" + vsFrom + " - " + vsTo
    }
    return title + " " + fromChap + ":" + vsFrom + " - " + toChap + ":" + vsTo
}

function getKeyByValue(object, value) {
  return Object.keys(object).find(key => object[key] === value);
}

module.exports = 
  { dbKeys: dbKeys
  , lessonTitle: lessonTitle
  , lessonTitleFromKeys: lessonTitleFromKeys
  }
