// calendar.js - calendar functions 
"use strict";
import Pouchdb from 'pouchdb';
var iphod = new Pouchdb('iphod')
var lectionary = new Pouchdb('lectionary')
// var moment = require('moment');
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
    var dofKeys = list.map( d => { return d.mpepKey })
      , euKeys = list.map( d => { return d.iphodKey })
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

    return Promise.all( allPromises).then(  function(resp) {
      var mpep = resp.slice(0, 42) // first 42
        , eu = resp.slice(42) // last 42
        , calday = []
        ;
      for ( var i = 0; i < 42; i++ ) {
        var m = mpep[i]
          , e = eu[i]
          , thisDate = daz[i].date
          , thisColor = LitYear.rldColor(thisDate)
          , dayOfMonth = thisDate.date()
          , pss = DailyPsalms.stringified(dayOfMonth) // psalms index off 1
          ;
        calday[i] = 
          { show: false
          , id: i
          , pTitle: m.title // String
          , eTitle: e.title // String
          , color: thisColor ? thisColor : e.colors[0] // String
          , colors: e.colors
          , season: daz[i].season // String
          , week: daz[i].week.toString() //String
          , weekOfMon: Math.floor(i/7)
          , lityear: daz[i].year // String
          , month: daz[i].date.month() // Int
          , dayOfMonth: dayOfMonth // int
          , year: daz[i].date.year() // Int
          , dow: daz[i].date.day() // Int
          , mp: makeReadings(m.mp1, m.mp2, pss.mp, false)
          , ep: makeReadings(m.ep1, m.ep2, pss.ep, false)
          , eu: makeReadings(e.ot, e.nt, e.ps, e.gs)
          }
      }
      port.send( JSON.stringify( {calendar: calday} ) );
    })
    .catch(  function(err) {
      console.log("CALENDER GET FAILED: ", err)
    })

  }
}

function makeReadings(lesson1, lesson2, psalms, gospel) {
  var lsnz = {}
  lsnz.lesson1 = {
      lesson: "lesson1"
    , content: makeThisReading( lesson1 )
    }
  lsnz.lesson2 = {
      lesson: "lesson2"
    , content: makeThisReading( lesson2 )
    }
  lsnz.psalms = {
      lesson: "psalms"
    , content: makeThisReading( psalms )
    }
  // no gospel for mp/ep
  if (gospel) {
    lsnz.gospel = {
        lesson: "gospel"
      , content: makeThisReading( gospel ) 
      }
    }
  return lsnz;
}

function makeThisReading(lessons) {
  
  if (lessons) {
    return lessons.map( function(l,id) { 
      // psalms do not have a style field and should be required
      var style = l.style ? l.style : "req";
      var ref = l.read ? l.read : l;
      return {id: id, ref: ref, style: style }; })
  }
  else { return []; }
}


