// calendar.js - calendar functions 
"use strict";
import Pouchdb from 'pouchdb';
// var iphod = new Pouchdb('iphod')
// var lectionary = new Pouchdb('lectionary')
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

, pickDB: function ( dbs ) {
    var thisDB = dbs.pop();
    console.log("THIS ONE? ", thisDB)
    thisDB.info()
      .then(resp => {
        console.log("RETURNING THIS: ", thisDB)
        return thisDB;
      })
      .catch(err => {
        if (dbs.length > 0) { return this.pickDB(dbs) }
        console.log("DB ERROR: ", err )
      })
    }


, buildPromises: function (daz, iDBs, lDBs) {
    var dofKeys = daz.map( d => { return d.mpepKey })
      , euKeys = daz.map( d => { return d.iphodKey })
      , allPromises = []
    //  , iphod = this.pickDB(iDBs)
    //  , lectionary = this.pickDB(lDBs)
    ;
    var iphod = undefined;
    var lectionary = undefined;
    var thisDB = iDBs.pop();
    // ASSUMPTION: if iphod(local) isn't available
    // then neither is lectionary
    // and if it is, so is lectionary
    // yeah, I know, weak assumption
    // use .info() to test for existance
    thisDB.info()
      .then( r => { 
        iphod = thisDB;
        lectionary = lDBs.pop();
      })
      .catch( r => {
        iphod = iDBs[0];
        lectionary = lDBs[0]; 
      })
      .then( r => {
        // lectionary and iphod are DBs
        dofKeys.forEach( k => { allPromises.push( lectionary.get(k) ) });
        euKeys.forEach( k => { allPromises.push( iphod.get(k) ) });
        return allPromises;

      })
  }

, get_calendar: function(thisMdate, iphodDBs, lectionaryDBs, port, dbs) {
    var now = thisMdate.clone()
      , startOn = this.firstCalendarDate(now)
      , mdate = startOn.clone() // mutate to first Sunday of calendar
      , daz = this.buildDays(startOn.clone())
      // , allPromises = this.buildPromises( daz, iphodDBs, lectionaryDBs )
      , iphod = undefined
      , lectionary = undefined
      ;
    iphodDBs[1].info()
      .then( r => { 
        iphod = iphodDBs[1];
        lectionary = lectionaryDBs[1];
      })
      .catch( r => {
        iphod = iphodDBs[0];
        lectionary = lectionaryDBs[0]; 
      })
      .then( r => {
        // lectionary and iphod are DBs
        var dofKeys = daz.map( d => { return d.mpepKey })
        , euKeys = daz.map( d => { return d.iphodKey })
        , allPromises = []
        ;
        dofKeys.forEach( k => { allPromises.push( lectionary.get(k) ) });
        euKeys.forEach( k => { allPromises.push( iphod.get(k) ) });
        return allPromises;
      })
      .then( allPromises => {
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
    })
    .catch(  function(err) {
      console.log("CALENDAR GET FAILED: ", err)
    })

  }
}

function makeReadings(lesson1, lesson2, psalms, gospel) {
  var lsnz = {}
  lsnz.lesson1 = {
      lesson: "lesson1"
    , content: makeThisReading( lesson1 )
    , spa_location: ""
  }
  lsnz.lesson2 = {
      lesson: "lesson2"
    , content: makeThisReading( lesson2 )
    , spa_location: ""
  }
  lsnz.psalms = {
      lesson: "psalms"
    , content: makeThisReading( psalms )
    , spa_location: ""
  }
  // no gospel for mp/ep
  if (gospel) {
    lsnz.gospel = {
        lesson: "gospel"
      , content: makeThisReading( gospel ) 
      , spa_location: ""
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


