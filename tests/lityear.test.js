// Mocha/Chai lityeadescribe(
const expect = require('chai').expect;
const assert = require('chai').assert;
const LitYear = require('../src/js/lityear.js').LitYear;
const moment = require('moment');

describe('sanity', () => {
  it('should return true', function() {
      expect(true).to.equal(true);
  })
});

describe("days till sunday", () => {

    var monday    = moment([2016, 2, 7])
      , tuesday   = moment([2016, 2, 8])
      , wednesday = moment([2016, 2, 9])
      , thursday  = moment([2016, 2, 10])
      , friday    = moment([2016, 2, 11])
      , saturday  = moment([2016, 2, 12])
      , sunday    = moment([2016, 2, 13])
      ;
    it('should be 6 days till Sunday on monday', function() {
      expect( LitYear.daysTillSunday(monday)).to.equal( 6 )
    })
    it('should be 5 days till Sunday on tuesday', function() {
      expect( LitYear.daysTillSunday(tuesday)).to.equal( 5 )
    });
    it('should be 4 days till Sunday on wednesday', function() {
      expect( LitYear.daysTillSunday(wednesday)).to.equal( 4 )
    });
    it('should be 3 days till Sunday on thursday', function() {
      expect( LitYear.daysTillSunday(thursday)).to.equal( 3 )
    });
    it('should be 2 days till Sunday on friday', function() {
      expect( LitYear.daysTillSunday(friday)).to.equal( 2 )
    });
    it('should be 1 days till Sunday on saturday', function() {
      expect( LitYear.daysTillSunday(saturday)).to.equal( 1 )
    });
    it('should be 7 days till Sunday on sunday', function() {
      expect( LitYear.daysTillSunday(sunday)).to.equal( 7 )
    });
})

describe("thisYear: returns year of moment_date", function() {
  it('returns 2016 for date in 2016', function() {
    expect( LitYear.thisYear(moment([2016, 3, 5]))).to.equal( 2016);
    expect( LitYear.thisYear(moment([2021, 7, 15]))).to.equal( 2021);
  })
})

describe('inRange: returns true if n is inclusively between x & y', function() {
  it('returns true for 2, 1, 3', function(){
    expect( LitYear.inRange(2, 1, 3)).to.be.true;
  })
  it('returns true for 1, 1, 3', function(){
    expect( LitYear.inRange(1, 1, 3)).to.be.true;
  })
  it('returns true for 3, 1, 3', function() {
    expect( LitYear.inRange(3, 1, 3)).to.be.true;
  })
  it('returns false for 0, 1, 3', function() {
    expect( LitYear.inRange(0, 1, 3)).to.be.false;
  })
  it('returns false for 5, 1, 3', function() {
    expect( LitYear.inRange(5, 1, 3)).to.be.false;
  })
})

describe('listContains', function() {
  var list1 = [obj1, obj2] = [{a: 1, b:2}, {a: 3, b: 5}];
  var list2 = [obj2, {x: 1, z: 99}];
  it('returns true if list of objs contains given obj', function() {
    expect( LitYear.listContains(list1, obj1)).to.be.true;
    expect( LitYear.listContains(list2, obj2)).to.be.true;
  })
  it('returns false for empty list', function() {
    expect( LitYear.listContains([], obj1)).to.be.false;
    expect( LitYear.listContains([], null)).to.be.false;
    expect( LitYear.listContains([], [])).to.be.false;
  })
  it('returns true if list contains obj and dissimilar other objs', function() {
    expect( LitYear.listContains([obj1, 1, 2], obj1)).to.be.true;
  })
})

describe("daysTill", function() {
  var day1 = moment([2019, 2, 1])
    , day2 = moment([2019, 2, 2])
    , day3 = moment([2019, 11, 25])
    ;
  it('returns 0 for same day', function() {
    expect( LitYear.daysTill(day1, day1)).to.equal(0);
  })
  it('returns 1 for next day', function() {
    expect( LitYear.daysTill(day1, day2)).to.equal(1);
  })
  it('returns 299 for march1 till dec25', function() {
    expect( LitYear.daysTill(day1, day3)).to.equal(299);
  })
  it('returns neg count when first day comes after second day', function() {
    expect( LitYear.daysTill(day2, day1)).to.equal(-1);
  })
})

describe('weeksTill', function() {
  var day1 = moment([2019, 2, 1])
    , day2 = moment([2019, 2, 2])
    , day3 = moment([2019, 2, 8])
    , day4 = moment([2019, 2, 9])
    , day5 = moment([2019, 2, 15])
    ;
  it('returns 0 for next day', function() {
    expect( LitYear.weeksTill(day1, day2)).to.equal(0);
  })
  it('returns 1 for 6 days later', function() {
    expect( LitYear.weeksTill(day1, day3)).to.equal(1);
  })
  it('returns 1 for 7 days later', function() {
    expect( LitYear.weeksTill(day1, day4)).to.equal(1);
  })
  it('returns 2 for 14 days later', function() {
    expect( LitYear.weeksTill(day1, day5)).to.equal(2);
  })
})

describe('litYear', function() {
  var year1 = moment([2016, 11, 23])
    , year2 = moment([2016, 10, 15])
    ;
  it('returns 2017, for 2016 after Advent 1', function () {
    expect( LitYear.litYear(year1)).to.equal(2017);
  })
  it('returns 2016 for 2016 before Advent 1', function () {
    expect( LitYear.litYear(year2)).to.equal(2016);
  })
})

describe('litYearName', function () {
  var day1 = moment([2016, 11, 23]) // after advent 1
    , day2 = moment([2016, 10, 15]) // before advent 1
    , day3 = moment([2020, 1, 1]) // feb 1
    , day4 = moment([2019, 1, 1]) // feb 1
    , day5 = moment([2018])
    ;
  it('returns "a" for 2016 after Advent 1', function () {
    expect( LitYear.litYearName(day1)).to.equal('a');
  })
  it('returns "c" for 2016 before Advent 1', function () {
    expect( LitYear.litYearName(day2)).to.equal('c');
  })
  it('returns "a" for 2020', function () {
    expect( LitYear.litYearName(day3)).to.equal('a');
  })
  it('returns "c" for 2019', function () {
    expect( LitYear.litYearName(day4)).to.equal('c');
  })
  it('returns "b" for 2018', function () {
    expect( LitYear.litYearName(day5)).to.equal('b');
  })
})

describe('isSunday(moment_date)', function () {
  var sunday = moment([2019, 2, 31]) // mar 31
    , monday = moment([2019, 3, 1]) // apr 1
    ;
  it('returns true if moment_date is a sunday', function () {
    expect( LitYear.isSunday(sunday)).to.be.true;
  })
  it('returns false if moment_date is not a sunday', function () {
    expect( LitYear.isSunday(monday)).to.be.false;
  })
})

describe('isMonday(moment_date)', function () {
  var sunday = moment([2019, 2, 31]) // mar 31
    , monday = moment([2019, 3, 1]) // apr 1
    ;
  it('returns true if moment_date is a monday', function () {
    expect( LitYear.isMonday(monday)).to.be.true;
  })
  it('returns false if moment_date is not a monday', function () {
    expect( LitYear.isMonday(sunday)).to.be.false;
  })
})

describe('daysTillSunday(moment_date)', function () {
  var day1 = moment([2019, 2, 31]) // mar31 - sunday
    , day2 = moment([2019, 3, 1]) //apr1 - monday
    , day3 = moment([2019, 3, 6]) // apr6 - sat
    ;
  it('returns 7 if date is a sunday', function () {
    expect( LitYear.daysTillSunday(day1)).to.equal(7);
  })
  it('returns 6 if moment_date is a monday', function () {
    expect( LitYear.daysTillSunday(day2)).to.equal(6);
  })
  it('returns 1 if moment_date is saturday', function () {
    expect( LitYear.daysTillSunday(day3)).to.equal(1);
  })
})

describe('dateNextSunday(moment_date)', function () {
  var sunday = moment([2019, 2, 31]) // mar 31 - sunday
    , monday = moment([2019, 3, 1]) // apr 1 - monday
    , nextSunday = moment([2019, 3, 7]) // apr 7 - sunday
    ;
  // n.b. .to.equal is unhappy comparing moment_dates
  // so cant use .to.equal - must use momentjs comparator
  it('returns next sunday moment_date given a sunday', function () {
    expect( LitYear.dateNextSunday(sunday).isSame(nextSunday) ).to.be.true;
  })
  it('returns next sunday moment_date given a midweek date', function () {
    expect( LitYear.dateNextSunday(monday).isSame(nextSunday) ).to.be.true;
  })
})

describe('dateLastSunday(moment_date)', function () {
  var lastSunday = moment([2019, 2, 31]) // mar 31 - sunday
    , monday = moment([2019, 3, 1]) // apr 1 - monday
    , sunday = moment([2019, 3, 7]) // apr 7 - sunday
    ;
  // n.b. .to.equal is unhappy comparing moment_dates
  // so cant use .to.equal - must use momentjs comparator
  it('returns last sunday moment_date given a sunday', function () {
    expect( LitYear.dateLastSunday(sunday).isSame(lastSunday) ).to.be.true;
  })
  it('returns last sunday moment_date given a midweek date', function () {
    expect( LitYear.dateLastSunday(monday).isSame(lastSunday) ).to.be.true;
  })
})

describe('firstCalendarSunday(moment_date)', function () {
  var day = moment([2019, 3, 15]) // apr 15
    , cal1 = moment([2019, 2, 31]) // mar 31 - sunday - first day of apr calendar
    ; 
  it('returns the first date of the monthly calendar', function () {
    expect( LitYear.firstCalendarSunday(day).isSame(cal1) ).to.be.true;
  })
})

describe('easter(moment_date)', function () {
  var e2020  = moment([2020, 3, 12])
    , e2021  = moment([2021, 3, 4])
    , e2022  = moment([2022, 3, 17])
    , e2023  = moment([2023, 3, 9])
    , e2024  = moment([2024, 2, 31])
    , e2025  = moment([2025, 3, 20])
    , d2020  = moment([2020, 2, 2])
    , d2021  = moment([2021, 5, 5])
    , d2022  = moment([2022, 11, 15])
    , d2023  = moment([2023, 3, 9])
    , d2024  = moment([2024, 1, 28])
    , d2025  = moment([2025, 6, 6])
    ;
  it ('returns moment_date for easter in 2020', function () {
    expect( LitYear.easter(d2020).isSame(e2020)).to.be.true;
  })
  it ('returns moment_date for easter in 2021', function () {
    expect( LitYear.easter(d2021).isSame(e2021)).to.be.true;
  })
  it ('returns moment_date for easter in 2022', function () {
    expect( LitYear.easter(d2022).isSame(e2022)).to.be.true;
  })
  it ('returns moment_date for easter in 2023', function () {
    expect( LitYear.easter(d2023).isSame(e2023)).to.be.true;
  })
  it ('returns moment_date for easter in 2024', function () {
    expect( LitYear.easter(d2024).isSame(e2024)).to.be.true;
  })
  it ('returns moment_date for easter in 2025', function () {
    expect( LitYear.easter(d2025).isSame(e2025)).to.be.true;
  })
})

describe('rightAfterAshWednesday', function () {
  var we = moment([2019, 2, 6])
    , th = moment([2019, 2, 7])
    , fr = moment([2019, 2, 8])
    , sa = moment([2019, 2, 9])
    , tu = moment([2019, 2, 5])
    , su = moment([2019, 2, 10])
    ;
  it('returns false for tues before ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(tu)).to.be.false;
  })
  it('returns true for ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(we)).to.be.true;
  })
  it('returns true for thurs after ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(th)).to.be.true;
  })
  it('returns true for fri after ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(fr)).to.be.true;
  })
  it('returns true for sat after ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(sa)).to.be.true;
  })
  it('returns false for sun after ashWednesday', function () {
    expect( LitYear.rightAfterAshWednesday(su)).to.be.false;
  })
})


describe('rightAfterAscension', function () {
  var we = moment([2019, 4, 29])
    , th = moment([2019, 4, 30])
    , fr = moment([2019, 4, 31])
    , sa = moment([2019, 5, 1])
    , su = moment([2019, 5, 2])
    ;
  it('returns false for wed before ascension', function () {
    expect( LitYear.rightAfterAscension(we)).to.be.false;
  })
  it('returns true for ascension', function () {
    expect( LitYear.rightAfterAscension(th)).to.be.true;
  })
  it('returns true for fri after ascension', function () {
    expect( LitYear.rightAfterAscension(fr)).to.be.true;
  })
  it('returns true for sat after ascension', function () {
    expect( LitYear.rightAfterAscension(sa)).to.be.true;
  })
  it('returns false for sun after ascension', function () {
    expect( LitYear.rightAfterAscension(su)).to.be.false;
  })
})

describe('daysFromChristmas', function () {
  it('returns 1 on 12/26', function () {
    var boxing = moment([2019, 11, 26])
      , diff = LitYear.daysFromChristmas(boxing)
      ;
    expect( diff ).to.equal(1);
  })
  it('returns 7 on 1/1', function () {
    var jan1 = moment([2020, 0, 1])
      , diff = LitYear.daysFromChristmas(jan1)
      ;
    expect( diff ).to.equal( 7 );
  })
})

describe('toSeason(moment_date)', function () {
  // this is the most difficult...
  describe('ashWednesday thru Sunday Lent 1', function () {
    var aw = moment([2019, 2, 6]) 
      , sat = moment([2019, 2, 9])
      , abc = LitYear.litYearName(aw)
      ;
    it('returns ashWednesday wk 1 for ashWednesday', function () {
      var obj = LitYear.toSeason(aw);
      expect( obj.season ).to.equal('ashWednesday');
      expect( obj.week ).to.equal('1');
    })
    it('return ashWednesday wk 1 for sat before sunday lent1', function () {
      var obj = LitYear.toSeason(sat);
      expect( obj.season ).to.equal('ashWednesday');
      expect( obj.week ).to.equal('1');
    })
  })

  describe('ascension through sunday following', function () {
    var asc = moment([2019, 4, 30])
      , sat = moment([2019, 5, 1])
      , abc = LitYear.litYearName(asc)
      ;
    it('returns ascension wk 1 for ascension', function () {
      var obj = LitYear.toSeason(asc);
      expect( obj.season ).to.equal('ascension');
      expect( obj.week ).to.equal("1");
    })
    it('returns ascension wk 1 for saturday following ascension', function () {
      var obj = LitYear.toSeason(sat);
      expect( obj.season ).to.equal('ascension');
      expect( obj.week ).to.equal("1");
    })
  })

  describe('Christmas Day', function () {
    it('returns christmasDay week 1 on Christmas Day', function () {
      var xmas = moment([2019, 11, 25])
        , obj  = LitYear.toSeason( xmas )
        ;
      expect( obj.season ).to.equal('christmasDay');
      expect( obj.week).to.equal('1');
    })
  })

  describe('Holy Name', function () {
    it('returns holyName week 1 for Holy Name', function () {
      var obj = LitYear.toSeason( moment([2020, 0, 1]) );
      expect( obj.season ).to.equal('holyName');
      expect( obj.week ).to.equal('1');
    })
  })

  describe('Some years have two sundays in Christmas', function () {
    it('returns christmas week 2 for 2nd sunday in Christmas when 1/5 is sunday', function () {
      var sun = moment([2014, 0, 5])
        , obj = LitYear.toSeason(sun)
        ;
      expect( obj.season ).to.equal('christmas');
      expect( obj.week ).to.equal('2');
    })
    it('returns christmas week 1 on 2014-jan-2', function () {
      var obj = LitYear.toSeason( moment([2014, 0, 2]) );
      expect( obj.season ).to.equal('christmas');
      expect( obj.week ).to.equal('1');
    })
    it('returns christmas week 2 on 2015-jan-4', function () {
      var obj = LitYear.toSeason( moment([2015, 0, 4]) );
      expect( obj.season ).to.equal('christmas');
      expect( obj.week ).to.equal('2');
    })
    it('returns christmas week 1 on 2015-jan-2', function () {
      var obj = LitYear.toSeason( moment([2015, 0, 2]) );
      expect( obj.season ).to.equal('christmas');
      expect( obj.week ).to.equal('1');
    })
  })
  // body...
  describe('Some years only have 1 Sunday in Christmas', function () {
    it('returns christmas week 1 for 2023-jan-2', function () {
      var obj = LitYear.toSeason( moment([2023, 0, 2]));
      expect( obj.season ).to.equal('christmas');
      expect( obj.week ).to.equal("1");
    })
    it('returns christmasDay week 1 for 2022-dec-31', function () {
      var obj = LitYear.toSeason( moment([2022, 11, 31]));
      console.log(">>>>> XMAS 2022:", obj)
      expect( obj.season ).to.equal('christmasDay');
      expect( obj.week ).to.equal("1");
    })
  })

  describe('holyWeek', function () {
    var ps = moment([2019, 3, 14])
      , mt = moment([2019, 3, 18])
      , ea = moment([2019, 3, 21])
      ;
    it('returns palmSunday week 1 for palm sunday', function () {
      var obj = LitYear.toSeason(ps);
      expect( obj.season ).to.equal('palmSunday');
      expect( obj.week ).to.equal("1");
    })
    it('returns holyWeek week 4 for Maunday Thursday', function () {
      var obj = LitYear.toSeason(mt);
      expect( obj.season ).to.equal('holyWeek');
      expect( obj.week ).to.equal("4");
    })
    it('returns easterDay week 1 for Easter', function () {
      var obj = LitYear.toSeason(ea);
      expect( obj.season ).to.equal('easterDay');
      expect( obj.week ).to.equal("1");
    })
  })

  describe('Advent', function () {
    it('is advent 1 on 12/3 when Christmas is on monday', function () {
      var a1 = moment([2023, 11, 3])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 12/2 when Christmas is on Tueday', function () {
      var a1 = moment([2018, 11, 2])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 12/1 when Christmas is on Wednesday', function () {
      var a1 = moment([2019, 11, 1])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 11/30 when Christmas is on Thursday', function () {
      var a1 = moment([2025, 10, 30])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 11/29 when Christmas is on Friday', function () {
      var a1 = moment([2020, 10, 29])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 11/28 when Christmas is on Saturday', function () {
      var a1 = moment([2021, 10, 28])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
    it('is advent 1 on 11/27 when Christmas is on Sunday', function () {
      var a1 = moment([2022, 10, 27])
        , obj = LitYear.toSeason(a1)
        ;
      expect( obj.season ).to.equal('advent');
      expect( obj.week ).to.equal('1');
    })
  })


})
