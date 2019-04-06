// calendar.js - calendar functions 
"use strict";
import Pouchdb from 'pouchdb';
var iphod = new Pouchdb('iphod')
var lectionary = new Pouchdb('lectionary')
var moment = require('moment');
var LitYear = require('./lityear.js').LitYear;
var DailyPsalms = require('./dailyPsalms.js')

export var Calendar = {
  firstCalendarDate: function (arg) {
    return arg.startOf('month').startOf('week');
  }

, buildDays: function (mdate) {
    var daysInMonth = 42
      , daz = []
      ;
    for (var d = 0; d < daysInMonth; d++ ) {
      daz[d] = LitYear.toSeason(mdate.clone());
      mdate.add(1, 'day');
    }
    return daz;
  }

, buildPromises: function (list) {
    var dofKeys = list.map( d => { return "mpep" + d.date.format("MMDD") })
      , euKeys = list.map( d => { return d.season + d.week + d.year })
      , allPromises = []
      ;
    // lectionary and iphod are DBs
    dofKeys.forEach( k => { allPromises.push( lectionary.get(k) ) });
    euKeys.forEach( k => { allPromises.push( iphod.get(k) ) });
    return allPromises;
  }

, get_calendar: function(thisMdate, port) {
    var now = thisMdate.clone()
      , startOn = this.firstCalendarDate(now)
      , mdate = startOn.clone() // mutate to first Sunday of calendar
      , daz = this.buildDays(startOn.clone())
      , allPromises = this.buildPromises( daz )
      ;

    console.log("GET CAL: ", daz)
    return Promise.all( allPromises).then(  function(resp) {
      var mpep = resp.slice(0, 42) // first 42
        , eu = resp.slice(42) // last 42
        , calday = []
        ;
      for ( var i = 0; i < 42; i++ ) {
        var m = mpep[i]
          , e = eu[i]
          , dayOfMonth = daz[i].date.date()
          , pss = DailyPsalms.stringified(dayOfMonth) // psalms index off 1
          ;
        calday[i] = 
          { show: false
          , id: i
          , pTitle: m.title // String
          , eTitle: e.title // String
          , color: e.colors[0] // String
          , colors: e.colors
          , season: daz[i].season // String
          , week: daz[i].week //String
          , lityear: daz[i].year // String
          , month: daz[i].date.month() // Int
          , dayOfMonth: dayOfMonth // int
          , year: daz[i].date.year() // Int
          , dow: daz[i].date.day() // Int
          , mp: {
              lesson1: m.mp1
            , lesson2: m.mp2
            , psalms: pss.mp
            , gospel: []
            }
          , ep: {
              lesson1: m.ep1
            , lesson2: m.ep2
            , psalms: pss.ep
            , gospel: []
            }
          , eu: {
              lesson1: e.ot
            , lesson2: e.nt
            , psalms: e.ps.map(  function(p) { return p.read; } )
            , gospel: e.gs
            }
          }
      }
      port.send( calday )
    })
    .catch(  function(err) {
      console.log("CALENDER GET FAILED: ", err)
    })

  }

}

