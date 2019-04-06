"use strict";
  var moment = require('moment')
  , christmasDay = 300
  , dec31 = 306
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

var rlds =
  { 312 : 'epiphany'
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
  , 300 : 'christmasDay'
  , 301 : 'stStephen'
  , 302 : 'stJohn'
  , 303 : 'holyInnocents'
  , 307 : 'jan1'
  };

// weak assumption: Object.keys(rlds) will return keys in the order below

export const LitYear = {
  // day of year from Mar/1
  march1onSunday: function(moment_date) {
    return (moment([moment_date.year(), 2, 1]).day() === 0);
  }
, doyr: function (moment_date) {
    var yr = moment_date.year();
    // return moment.diff(moment_date, moment([yr, 2, 1])) +1;
    return moment.duration(moment_date.diff( moment([yr, 2, 1]) ) ).asDays() + 1;
  }
  // week of year from Mar/1
, woyr: function (moment_date) {
    var doy = this.doyr(moment_date);
    var wk = Math.floor(doy / 7);
    wk += this.march1onSunday(moment_date) ? 1 : 0;
    return (wk === 0) ? 52 : wk;
  }
, easter: function (thisDate) {
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
  }

}
