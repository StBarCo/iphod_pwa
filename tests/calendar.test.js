// Mocha/Chai index.js
const expect = require('chai').expect;
const assert = require('chai').assert;
const Cal = require('../src/js/calendar.js').Calendar;
const LitYear = require('../src/js/lityear.js').LitYear;
const moment = require('moment');
  
describe('sanity', () => {
  it('should return true', function() {
      expect(true).to.equal(true);
  })
});
  
describe('Calendar functions - src/js/calendar.js', function () {

  describe('firstCalendarDate - gives date of 1st Sunday on the calendar', function () {
    it('returns 2/24/2019 for 3/15/2019', function () {
      var day = moment([2019, 2, 15])
        , startsOn = moment([2019, 1, 24])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 11/30/2025 for 12/15/2025', function () {
      var day = moment([2025, 11, 15])
        , startsOn = moment([2025, 10, 30])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 9/1/2019 for 9/15/2019', function () {
      var day = moment([2019, 8, 15])
        , startsOn = moment([2019, 8, 1])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 9/29/2019 for 10/15/2019', function () {
      var day = moment([2019, 9, 15])
        , startsOn = moment([2019, 8, 29])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 12/29/2019 for 1/15/2020', function () {
      var day = moment([2020, 0, 15])
        , startsOn = moment([2019, 11, 29])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 7/28/2019 for 8/15/2019', function () {
      var day = moment([2019, 7, 15])
        , startsOn = moment([2019, 6, 28])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 2/24/2019 for 3/15/2019', function () {
      var day = moment([2019, 2, 15])
        , startsOn = moment([2019, 1, 24])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    });
    it('returns 1/26/2020 for 2/15/2020', function () {
      var day = moment([2020, 1, 15])
        , startsOn = moment([2020, 0, 26])
        , ok  = startsOn.isSame( Cal.firstCalendarDate(day) )
        ;
      expect( ok ).to.be.true;
    })
    it('returns 3/31/2019 for 4/7/2019', function () {
      var day = moment([2019, 3, 1])
        , startsOn = moment([2019, 2, 31])
        , ok = startsOn.isSame( Cal.firstCalendarDate(day))
        ;
      expect( ok ).to.be.true;
    })
  })

  describe('buildDays', function () {
    var month = Cal.firstCalendarDate( moment([2019, 2, 17]) ) // 17-mar-2019
      , startsOn = moment([2019, 1, 24]) // 24-feb-2019
      , endsOn = moment([2019, 3, 6]) // 6-apr-2019
      daz = Cal.buildDays(month)
      ;
    it('has 42 days', function () {
      expect( daz.length ).to.equal( 42 );
    })
    it('starts on the correct date', function () {
      var obj = daz[0];
      expect( obj.date.isSame(startsOn) ).to.be.true;
    })
    it('ends on the correct date', function () {
      var obj = daz[41];
      expect( obj.date.isSame(endsOn) ).to.be.true;
    })
  })

  describe('Red Letter Days', function () {
    describe('when RLDs are not on Sunday', function () {
      var day = moment([2019, 0, 15])
        , rld = moment([2019, 0, 18])
        , [respRld, title]  = LitYear.nextHolyDay(day)
        , ok = respRld.isSame( rld )
        ;
      console.log(">>> ", rld.format("DD-MMM-YYYY"), respRld.format("DD-MMM-YYYY"))
      expect( ok ).to.equal( true );
      expect( title ).to.equal("confessionOfStPeter");
    })

    describe('when RLDs are on a Sunday', function () {
      // body...
    })
  })
})
  