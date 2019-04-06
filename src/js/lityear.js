"use strict";
  var moment = require('moment')
  , leapDay = 60
  , sunday = 0
  , monday = 1
  , thursday = 4
  , oneDay = 60 * 60 * 24 * 1000
  , oneWeek = oneDay * 7
  , litYearNames = ["c", "a", "b"]
  , January = 0,    February = 1,   March = 2,      April = 3
  , May = 4,        June = 5,       July = 6,       August = 7
  , September = 8,  October = 9,    November = 10,  December = 11
  , mdFormat = "MM-DD"
  ;
// weak assumption: Object.keys(rlds) will return keys in the order below
var rlds =
  { '01-18': 'confessionOfStPeter'
  , '01-25': 'conversionOfStPaul'
  , '02-02': 'presentation'
  , '02-24': 'stMatthias'
  , '03-19': 'stJoseph'
  , '03-25': 'annunciation'
  , '04-25': 'stMark'
  , '05-01': 'stsPhilipAndJames'
  , '05-31': 'visitation'
  , '06-11': 'stBarnabas'
  , '06-24': 'nativityOfJohnTheBaptist'
  , '06-29': 'stPeterAndPaul'
  , '07-01': 'dominion'
  , '07-04': 'independence'
  , '07-22': 'stMaryMagdalene'
  , '07-25': 'stJames'
  , '08-06': 'transfiguration'
  , '08-15': 'bvm'
  , '08-24': 'stBartholomew'
  , '09-14': 'holyCross'
  , '09-21': 'stMatthew'
  , '09-29': 'michaelAllAngels'
  , '10-18': 'stLuke'
  , '10-23': 'stJamesOfJerusalem'
  , '10-28': 'stsSimonAndJude'
  , '11-11': 'remembrance'
  , '11-30': 'stAndrew'
  , '12-21': 'stThomas'
  , '12-26': 'stStephen'
  , '12-27': 'stJohn'
  , '12-28': 'holyInnocents'
  };

/*
var rlds =
  { 312 : 'Epiphany'
  , 324 : 'confessionOfStPeter'
  , 331 : 'conversionOfStPaul'
  , 339 : 'presentation'
  , 361 : 'stMatthias'
  ,  19 : 'stJoseph'
  ,  25 : 'annunciation'
  ,  56 : 'stMark'
  ,  62 : 'stsPhilipAndJames'
  ,  92 : 'visitation'
  , 103 : 'stBarnabas'
  , 116 : 'nativityOfJohnTheBaptist'
  , 121 : 'stPeterAndPaul'
  , 123 : 'dominion'
  , 126 : 'independence'
  , 144 : 'stMaryMagdalene'
  , 147 : 'stJames'
  , 159 : 'transfiguration'
  , 168 : 'bvm'
  , 177 : 'stBartholomew'
  , 198 : 'holyCross'
  , 205 : 'stMatthew'
  , 213 : 'michaelAllAngels'
  , 232 : 'stLuke'
  , 237 : 'stJamesOfJerusalem'
  , 242 : 'stsSimonAndJude'
  , 256 : 'remembrance'
  , 275 : 'stAndrew'
  , 296 : 'stThomas'
  , 300 : 'Christmas'
  , 301 : 'stStephen'
  , 302 : 'stJohn'
  , 303 : 'holyInnocents'
  };
*/

// IMPORTANT TO THE PROGRAMMER!!!
// moment_date is MUTABLE
// which is OK if you want to actually change moment_date
// BUT if you want to use moment_date to calculate something
// BE SURE TO CLONE it!!!
// or give me a functional js

export var LitYear = {

thisYear: function (moment_date) { return moment(moment_date).year(); },
inRange: function (n, min, max) { return n >= Math.min(min, max) && n <= Math.max(min, max); },
listContains: function (list, obj) { return list.indexOf(obj) >= 0; },
// function advDays(d, days) { return new Date( d.valueOf() + oneDay * days ) },
// function advWeeks(d, weeks) { return advDays(d, weeks * 7) },
daysTill: function (d1, d2) { return Math.floor( (d2 - d1)/oneDay ); },
weeksTill: function (d1, d2) { return Math.floor( (d2 - d1)/oneWeek ); },
litYear: function (moment_date) {
  var yr = this.thisYear(moment_date);
  return moment_date.isSameOrAfter(this.advent(moment_date, 1)) ? yr + 1 : yr;
},
daysFromChristmas: function(moment_date) {
  var xmas = this.christmasDay( moment(moment_date) )
    , diff = this.daysTill(xmas, moment_date)
    ;
  if (diff < 0 ) { 
    xmas = this.christmasDay( moment_date.clone().subtract(1, 'year'))
    diff = this.daysTill(xmas, moment_date);
  }
  return diff;
},
litYearName: function (moment_date) { return litYearNames[ this.litYear(moment_date) % 3 ]; },
isSunday: function (moment_date) { return moment_date.day() == sunday; },
isMonday: function (moment_date) { return moment_date.day() == monday; },
daysTillSunday: function (moment_date) { return 7 - moment_date.day(); },
dateNextSunday: function (moment_date) { return moment_date.day(7); },
dateLastSunday: function (moment_date) { 
  return (this.isSunday(moment_date) ? moment_date.day(-7) : moment_date.day(0));
},
firstCalendarSunday: function (moment_date) {
  return moment([moment_date.year(), moment_date.month()]).day(0);
}, 
// algorithm from http://en.wikipedia.org/wiki/Computus#cite_note-otheralgs-47
// presumes `d` is either int or date
easter: function (thisDate) {
  var year = this.thisYear(thisDate) 
    , a = year % 19
    , b = Math.floor(year / 100)
    , c = year % 100
    , d = Math.floor(b / 4)
    , e = b % 4
    , f = Math.floor((b + 8) / 25)
    , g = Math.floor((b - f + 1) / 3)
    , h = (19 * a + b - d - g + 15) % 30
    , i = Math.floor(c / 4)
    , k = c % 4
    , l = (32 + 2 * e + 2 * i - h - k) % 7
    , m = Math.floor((a + 11 * h + 22 * l) / 451)
    , n0 = (h + l + 7 * m + 114)
    , n = Math.floor(n0 / 31) - 1
    , p = n0 % 31 + 1
    , date = moment({'year': year, 'month': n, 'day': p});
  return date; 
},
sundayInEaster: function (moment_date, n) { 
  return this.easter(moment_date).add(n - 1, 'weeks');
},
secondMondayAfterEaster: function (moment_date) {
  return this.easter(moment_date).add(8, 'days');
},
ascension: function (moment_date) { 
  return this.easter(moment_date).add(39, 'days');
},
rightAfterAscension: function (moment_date) {
  var a = this.ascension(moment_date)
    , ascen = moment_date.isSameOrAfter(a)
    , beforeSaad = moment_date.isBefore(this.sundayAfterAscension(moment_date)) // saad - sunday after ascension day
    ;
    return ascen && beforeSaad;
},
sundayAfterAscension: function (moment_date) { 
  return this.sundayInEaster(moment_date, 7) ;
},
pentecost: function (moment_date, n) { 
  return this.easter(moment_date).add(n + 6, 'weeks') ;
},
trinity: function (moment_date) { 
  return this.pentecost(moment_date, 2) ;
},
proper: function (moment_date, n) { 
  return this.advent(moment_date, n - 29) ;
},
christmasDay: function (moment_date) { 
  return moment(this.thisYear(moment_date) + '-12-25') ;
},
christmasSeason: function (moment_date, n) { 
  var y = this.thisYear(moment_date)
    , sundayAfter = this.dateNextSunday( this.christmasDay(y) )
    ;
  return (n == 2) ? sundayAfter.add(1, 'weeks') : sundayAfter;
},
dayOfMarchYear: function(moment_date) {
  var yr = (moment_date.year < 2) ? moment_date.getYear() - 1 : moment_date.getYear();
  return this.daysTill( moment([yr, 2, 1]), moment_date ) + 1;
},
advent: function (moment_date, n) { 
  var sundayBefore = this.dateLastSunday(this.christmasDay(moment_date));
  return sundayBefore.add(n - 4, 'weeks'); 
},
epiphanyDay: function (moment_date) { return moment(this.thisYear(moment_date) + '-01-06'); },
epiphanyBeforeSunday: function (moment_date) { 
  return moment_date.isSameOrAfter(this.epiphanyDay(moment_date)) && moment_date.isBefore(this.weekOfEpiphany(moment_date, 1)) ;
},
sundayAfterEpiphany: function (moment_date) { 
  return this.dateNextSunday( this.epiphanyDay(moment_date) ) ;
},
weekOfEpiphany: function (moment_date, n) { 
  return this.sundayAfterEpiphany(moment_date).add(n - 1, 'weeks');
},
ashWednesday: function (moment_date) { 
  return this.easter(moment_date).add( -46, 'days');
},
rightAfterAshWednesday: function (moment_date) { 
  return moment_date.isSameOrAfter(this.ashWednesday(moment_date)) && moment_date.isBefore(this.lent(moment_date, 1)); 
},
lent: function (moment_date, n) { 
  return this.easter(moment_date).add( n - 7, 'weeks') ;
},
palmSunday: function (moment_date) { 
  return this.easter(moment_date).add( -1, 'weeks') ;
},
goodFriday: function (moment_date) { 
  return this.easter(moment_date).add( -2, 'days') ;
},
isGoodFriday: function (moment_date) { 
  return moment_date.isSame(this.goodFriday(moment_date)) ;
},
toSeason: function (moment_date) {
//  var sunday = this.isSunday(moment_date) ? date : this.dateLastSunday(moment(moment_date))
  var sunday = moment_date.clone().day('Sunday')
    , y = this.litYear(sunday)
    , yrABC = this.litYearName(sunday)
    , dOfMonth = (sunday.month() + 1) + "/" + sunday.date()
    , weeksTillAdvent = this.weeksTill(sunday, this.advent(sunday, 1))
    , daysTillEpiphany = this.daysTill(moment_date, this.epiphanyDay(moment_date))
    , weeksFromEpiphany = this.weeksTill(this.epiphanyDay(sunday), sunday)
    , weeksFromChristmas = Math.floor( this.daysFromChristmas(moment_date) / 7 )
    , isChristmas = this.inRange( this.daysFromChristmas(moment_date), 0, 11)
    , weeksFromEaster = this.weeksTill(this.easter(moment_date), sunday)
    , daysTillEaster = this.daysTill(moment_date, this.easter(moment_date))
    , [rldDate, rldTitle] = this.nextHolyDay( moment_date.clone() )
    , isRLD = moment_date.isSame( rldDate )
    ;

  switch (true) {

  case isRLD:
    return {season: rldTitle, week: 1, year: yrABC, date: moment_date };
    break;
  case (isChristmas):
    return this.whereInChristmas(moment_date, yrABC);
    break;
  case (this.rightAfterAshWednesday(moment_date)): 
    return {season: "ashWednesday", week: "1", year: yrABC, date: moment_date}; 
    break;
  case (this.rightAfterAscension(moment_date)):
    return {season: "ascension",    week: "1", year: yrABC, date: moment_date};
    break;
  case (this.inRange(daysTillEaster, 1, 6)):
    return {season: "holyWeek",     week: (7 - daysTillEaster).toString(), year: yrABC, date: moment_date};
    break;
  case (this.inRange(daysTillEaster, -1, -6)):
    return {season: "easterWeek",   week: (0 - daysTillEaster).toString(), year: yrABC, date: moment_date};
    break;
  case (this.inRange(weeksFromEaster, -2, -6)):
    return {season: "lent",         week: (7 + weeksFromEaster).toString(), year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster == -1):
    return {season: "palmSunday",   week: "1", year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster == -7):
    return {season: "epiphany",     week: "9", year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster == -8):
    return {season: "epiphany",     week: "8", year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster === 0):
    return {season: "easterDay",    week: "1", year: yrABC, date: moment_date};
    break;
  case (this.inRange(weeksFromEaster, 0, 6)):
    return {season: "easter",       week: (1 + weeksFromEaster).toString(), year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster == 7):
    return {season: "pentecost",    week: "1", year: yrABC, date: moment_date};
    break;
  case (weeksFromEaster == 8):
    return {season: "trinity",      week: "1", year: yrABC, date: moment_date};
    break;
  case (this.inRange(weeksTillAdvent, 1, 27)):
    return {season: "proper",       week: (29 - weeksTillAdvent).toString(), year: yrABC, date: moment_date};
    break;
  case (this.inRange(weeksTillAdvent, 0, -3)):
    return {season: "advent",       week: (1 - weeksTillAdvent).toString(), year: yrABC, date: moment_date};
    break;
  case (this.epiphanyBeforeSunday(moment_date)):
    return {season: "epiphany",     week: "0", year: yrABC, date: moment_date};
    break;
  case (this.inRange(weeksFromEpiphany, 0, 8)):
    return {season: "epiphany",     week: (weeksFromEpiphany + 1).toString(), year: yrABC, date: moment_date};
    break;
  default:
    return {season: "unknown",      week: "unknown", year: "unknown",date: moment_date};
  }
  
},

whereInChristmas: function (moment_date, yrABC) {
  var now = moment_date.clone()
    , dfx = this.daysFromChristmas(now)
    , yr = (dfx > 6) ? now.year() - 1 : now.year() // dfx > 7 is the next year
    , key = (this.christmasDay([yr]).day() * 12) + dfx
    , xmasDay = { season: "christmasDay", week: '1', year: yrABC, date: now}
    , xmas = "christmas"
    , xmas1 = {season: xmas,    week: '1', year: yrABC, date: now}
    , xmas2 = {season: xmas,    week: '2', year: yrABC, date: now}
    , stStephen = {season: "stStephen", week: '', year: '', date: now}
    , stJohn    = {season: "stJohn", week: '', year: '', date: now}
    , holyInn   = {season: "holyInnocents", week: '', year: '', date: now}
    , holyName  = {season: "holyName", week: '1', year: yrABC, date: now}
    , obj = null;
    ;
  switch( key ) {
    // Christmas on sunday
    case 0: obj = xmasDay
    case 1: obj = stStephen; break;
    case 2: obj = stJohn; break;
    case 3: obj = holyInn; break;
    case 4:
    case 5:
    case 6: obj = xmasDay; break;
    case 7: obj = holyName; break;
    case 8:
    case 9:
    case 10:
    case 11:  obj = xmas1; break;
    // Christmas on monday
    case 12: obj = xmasDay; break;
    case 13: obj = stStephen; break;
    case 14: obj = stJohn; break;
    case 15: obj = holyInn; break;
    case 16:
    case 17: obj = xmasDay; break;
    case 18: obj = xmas1; break;
    case 19: obj = holyName; break;
    case 20:
    case 21:
    case 22:
    case 23: obj = xmas1; break;
    // Christmas on tuesday
    case 24: obj = xmasDay; break;
    case 25: obj = stStephen; break;
    case 26: obj = stJohn; break;
    case 27: obj = holyInn; break;
    case 28: obj = xmasDay; break;
    case 29:
    case 30: obj = xmas1; break;
    case 31: obj = holyName; break;
    case 32:
    case 33:
    case 34:
    case 35: obj = xmas1; break;
    // Christmas on wednesday
    case 36: obj = xmasDay; break;
    case 37: obj = stStephen; break;
    case 38: obj = stJohn; break;
    case 39: obj = holyInn; break;
    case 40:
    case 41:
    case 42: obj = xmas1; break;
    case 43: obj = holyName; break;
    case 44:
    case 45:
    case 46: obj = xmas1; break;
    case 47: obj = xmas2; break; 
    // Christmas on thursday
    case 48: obj = xmasDay; break;
    case 49: obj = stStephen; break;
    case 50: obj = stJohn; break;
    case 51: obj = xmas1; break;
    case 52: obj = holyInn; break;
    case 53:
    case 54: obj = xmas1; break;
    case 55: obj = holyName; break;
    case 56:
    case 57: obj = xmas1; break;
    case 58:
    case 59: obj = xmas2; break
    // Christmas on friday
    case 60: obj = xmasDay; break;
    case 61: obj = stStephen; break;
    case 62: obj = xmas1; break;
    case 63: obj = holyInn; break;
    case 64: obj = stJohn; break;
    case 65:
    case 66: obj = xmas1; break;
    case 67: obj = holyName; break;
    case 68: obj = xmas1; break;
    case 69:
    case 70:
    case 71: obj = xmas2; break;
    // Christmas on saturday
    case 72: obj = xmasDay; break;
    case 73: obj = xmas1; break;
    case 74: obj = stJohn; break;
    case 75: obj = holyInn; break;
    case 76: obj = stStephen; break;
    case 77:
    case 78: obj = xmas1; break;
    case 79: obj = holyName; break;
    default: obj = xmas2; // 80 - 83
  }
  return obj;
},

getSeasonName: function (season) {
return {
    advent: 'Advent'
  , christmas: 'Christmas'
  , christmasDay: 'Christmas Day'
  , holyName: 'Holy Name'
  , epiphany: 'Epiphany'
  , ashWednesday: 'Ash Wednesday'
  , lent: 'Lent'
  , palmSunday: 'Palm Sunday'
  , holyWeek: 'Holy Week'
  , goodFriday: 'Good Friday'
  , easter: 'Easter'
  , easterDay: 'Easter Day'
  , easterWeek: 'Easter Week'
  , ascension: 'Ascension'
  , pentecost: 'Pentecost'
  , trinity: 'Trinity Sunday'
  , proper: 'Season after Pentecost'
  }[season];
},

getCanticle: function (office, season, day, reading) {
  switch(office) {
    case 'mp':
      switch(reading) {
        case 'ot':
          switch(day){
            case 'Sunday':
              switch(season) {
                case 'advent': return "surge_illuminare";
                case 'easter': return "cantemus_domino";
                case 'lent': return "kyrie_pantokrator";
                default: return "benedictus";
              }
              break;
            case 'Monday':
              switch(season) {
                case 'lent': return "quaerite_dominum";
                default: return "ecce_deus";
              }
              break;
            case 'Tuesday':
              switch(season){
                case 'lent': return "quaerite_dominum";
                default: return "benedictis_es_domine";
              }
              break;
            case 'Wednesday':
              switch(season){
                case 'lent': return "kyrie_pantokrator";
                default: return "surge_illuminare";
              }
              break;
            case 'Thursday':
              switch(season){
                case 'lent': return "quaerite_dominum";
                default: return "cantemus_domino";
              }
              break;
            case 'Friday':
              switch(season){
                case 'lent': return "kyrie_pantokrator";
                case 'easter': return "te_deum";
                case 'easterWeek': return "te_deum";
                default: return "quaerite_dominum";
              }
              break;
            case 'Saturday':
              switch(season){
                case 'lent': return "quaerite_dominum";
                default: return "benedicite_omnia_opera_domini";
              }
          }
          break;
        case 'nt':
          switch(day){
            case 'Sunday':
              switch(season) {
                case 'advent': return "benedictus";
                case 'easter': return "cantemus_domino";
                case 'lent': return "benedictus";
                default: return "benedictus";
              }
              break;
            case 'Thursday':
              switch(season){
                case 'advent': return "magna_et_mirabilia";
                case 'lent': return "magna_et_mirabilia";
                default: return "cantemus_domino";
              }
              break;
            default: return "benedictus";
          }
      }
      break;
    case 'ep':
      switch(reading) {
        case 'ot': 
          switch('day'){
            case 'Sunday':return  "magnificat";
            case 'Monday':
              switch(season) {
                case 'lent': return "kyrie_pantokrator";
                default: return "cantemus_domino";
              }
              break;
            case 'Tuesday': return "quaerite_dominum";
            case 'Wednesday': return "benedicite_omnia_opera_domini";
            case 'Thursday': return "surge_illuminare";
            case 'Friday': return "benedictis_es_domine";
            case 'Saturday': return "ecce_deus";
          }
          break;
        case 'nt': 
          switch('day'){
            case 'Sunday': return "nunc_dimittis";
            case 'Monday': return "nunc_dimittis";
            case 'Tuesday': return "magnificat";
            case 'Wednesday': return "nunc_dimittis";
            case 'Thursday': return "magnificat";
            case 'Friday': return "nunc_dimittis";
            case 'Saturday': return "magnificat";
          }
      }
  }
},

holyDay: function (moment_date) {
  var m_d = moment_date.format(mdFormat)
    , rld = rlds[m_d]
    ;
  if (rld == 'presentation') {return [true, rld]; }
  else if ( this.isSunday(moment_date)) {return [false, ""]; }
  else if ( this.isMonday(moment_date)) { 
    // go back and check for translated RLD
    m_d = moment_date.add(-1, 'days').format(mdFormat);
    rld = rlds[m_d];
  }
  return (rld === undefined) ? [false, ""] : [true, rld];

},

nextHolyDay: function (moment_date) {
  var now = moment_date.clone()
    , keys = Object.keys(rlds)
    , key = undefined
    , last_key = keys[keys.length - 1]
    , yr = now.year()
    , m_d = now.format(mdFormat) // month_day
    ;

  for (var i = 0; i < keys.length; i++) {
    if ( m_d < keys[i]) {
      key = keys[i];
      break;
    }
  }
  // if this loop falls through then the date is 12/29 - 12/30
  // and the next RLD is the first in the list
  if (key === undefined) {
    yr += 1;
    key = keys[0];
  }
  return [moment(yr + "-" + key), rlds[key] ];

},

// function nextHolyDay(date) {
//   let yr = date.year()
//     , day = date.day()
//     , doy = dayOfYear(date)
//     , holy_doy = hd_doy[doy]
//     , advance = (holy_doy > 365) ? holy_doy + 1 : holy_doy
//     , newDate = advDate( moment(yr + '-01-01'), advance)
//   return [newDate, hd_index[holy_doy]]
// },
// function isLeapYear(date) {
//   let yr = thisYear(date);
//   return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
// },
// function dayOfYear(date) {
//   let newYear = moment(date.year() + '-01-01 ', )
//     , doy = Math.floor( (date - newYear) / oneDay )
//   return (isLeapYear(date) && doy > leapDay) ? doy - 1 : doy;
// },
// 
namedDayDate: function (name, moment_date, wk) {
  var yr = this.thisYear(moment_date);
  switch (name) {
    case "christmasDay":    return moment(yr + '-12-25');
    case "holyName":        return moment(yr + 1 + '-01-01');
    case "palmSunday":      return this.palmSunday(moment_date);
    case "holyWeek":        return this.palmSunday(moment_date).add( wk, 'days');
    case "easterDayVigil":  return this.easter(moment_date).add( 1, 'days');
    case "easterDay":       return this.easter(moment_date);
    case "easterWeek":      return this.easter(moment_date).add( wk, 'days');
    default:                return moment_date;
  }
},

translateFromSunday: function (moment_date) { 
  return this.isSunday(moment_date) ? moment_date.add( 1, 'days') : moment_date; 
},
thanksgiving: function (moment_date) {
  var yr = this.thisYear(moment_date)
    , tgd = { 0: 26, 1: 25, 2: 24, 3: 23, 4: 22, 5: 28, 6: 27 }
    , dow = moment(yr + '-11-01').day() // day() is 0 indexed on sunday
    ;
  return moment({'year': yr, 'month': November, 'date': tgd[dow]});
},
memorial: function (moment_date) {
  var yr = this.thisYear(moment_date)
    , md = { 0: 30, 1: 29, 2: 28, 3: 27, 4: 26, 5: 25, 6: 31 }
    , dow = moment(yr + '-05-01').day() // day() is 0 indexed on sunday
    ;
  return moment({'year': yr, 'month': May, 'date': md[dow]});
},

// dear confused programmer - for reasons for ever to remain a mystery
// javascript indexs months off 0 (jan = 0, dec = 11)
// and indexs days off of 1 (the first of the month is lo (and behold) 1)
stAndrew: function (moment_date)                 { return (this.thisYear(moment_date) + '-11-30 ' ); },
stThomas: function (moment_date)                 { return (this.thisYear(moment_date) + '-12-21 ' ); },
stStephen: function (moment_date)                { return (this.thisYear(moment_date) + '-12-26 ' ); },
stJohn: function (moment_date)                   { return (this.thisYear(moment_date) + '-12-27 ' ); },
holyInnocents: function (moment_date)            { return (this.thisYear(moment_date) + '-12-28 ' ); },
confessionOfStPeter: function (moment_date)      { return (this.thisYear(moment_date) + '-01-18 ' ); },
conversionOfStPaul: function (moment_date)       { return (this.thisYear(moment_date) + '-01-25 ' ); },
presentation: function (moment_date)             { return (this.thisYear(moment_date) + '-02-2 ' ); },
stMatthias: function (moment_date)               { return (this.thisYear(moment_date) + '-02-24 ' ); },
stJoseph: function (moment_date)                 { return (this.thisYear(moment_date) + '-03-19 ' ); },
annunciation: function (moment_date)             { return (this.thisYear(moment_date) + '-03-25 ' ); },
stMark: function (moment_date)                   { return (this.thisYear(moment_date) + '-04-25 ' ); },
stsPhilipAndJames: function (moment_date)        { return (this.thisYear(moment_date) + '-05-1 ' ); },
visitation: function (moment_date)               { return (this.thisYear(moment_date) + '-05-31 ' ); },
stBarnabas: function (moment_date)               { return (this.thisYear(moment_date) + '-06-11 ' ); },
nativityOfJohnTheBaptist: function (moment_date) { return (this.thisYear(moment_date) + '-06-24 ' ); },
stPeterAndPaul: function (moment_date)           { return (this.thisYear(moment_date) + '-06-29 ' ); },
dominion: function (moment_date)                 { return (this.thisYear(moment_date) + '-07-1 ' ); },
independence: function (moment_date)             { return (this.thisYear(moment_date) + '-07-4 ' ); },
stMaryMagdalene: function (moment_date)          { return (this.thisYear(moment_date) + '-07-22 ' ); },
stJames: function (moment_date)                  { return (this.thisYear(moment_date) + '-07-25 ' ); },
transfiguration: function (moment_date)          { return (this.thisYear(moment_date) + '-08-6 ' ); },
bvm: function (moment_date)                      { return (this.thisYear(moment_date) + '-08-15 ' ); },
stBartholomew: function (moment_date)            { return (this.thisYear(moment_date) + '-08-24 ' ); },
holyCross: function (moment_date)                { return (this.thisYear(moment_date) + '-09-14 ' ); },
stMatthew: function (moment_date)                { return (this.thisYear(moment_date) + '-09-21 ' ); },
michaelAllAngels: function (moment_date)         { return (this.thisYear(moment_date) + '-09-29 ' ); },
stLuke: function (moment_date)                   { return (this.thisYear(moment_date) + '-10-18 ' ); },
stJamesOfJerusalem: function (moment_date)       { return (this.thisYear(moment_date) + '-10-23 ' ); },
stsSimonAndJude: function (moment_date)          { return (this.thisYear(moment_date) + '-10-28 ' ); },
remembrance: function (moment_date)              { return (this.thisYear(moment_date) + '-11-11 ' ); },

translateFromSunday: function (moment_date) { return this.isSunday(moment_date) ? moment_date.add(1, 'day') : moment_date; },

} // end of LitYear
