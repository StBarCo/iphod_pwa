import './js/scripture.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

window.app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: [window.innerHeight, window.innerWidth]
});

registerServiceWorker();

import axios from 'axios';
axios.defaults.headers.common['Authorization'] = "Token 77f1ef822a19e06867cf335a168713f9d2159bfc";

import $ from 'jquery';
window.onload = ( function() {
  app.ports.onlineStatus.send( "All Ready");
})
// 
// // var popper = require('popper.js');
// // var bootstrap = require('bootstrap');
var moment = require('moment');
// var Bowser = require('bowser');
// console.log("BROWSER: ", Bowser.getParser(window.navigator.userAgent) )

// var markdown = require('markdown').markdown;
var LitYear = require( "./js/lityear.js" ).LitYear;
var Calendar = require('./js/calendar.js').Calendar;
var BibleRef = require( "./js/bibleRef.js" );
var DailyPsalms = require( "./js/dailyPsalms.js");
// 
import Pouchdb from 'pouchdb';
var pdb = Pouchdb;
var preferences = new Pouchdb('preferences');
var iphod = new Pouchdb('iphod')
var service = new Pouchdb('service_dev')
var psalms = new Pouchdb('psalms')
var lectionary = new Pouchdb('lectionary')
var dbOpts = { live: true, retry: true }
  , remoteIphodURL =      "https://legereme.com/couchdb/iphod"
  , remoteServiceURL =    "https://legereme.com/couchdb/service_dev"
  , remotePsalmsURL =     "https://legereme.com/couchdb/psalms"
  , remoteLectionaryURL = "https://legereme.com/couchdb/lectionary"
  , remoteIphod = new Pouchdb(remoteIphodURL)
  , remoteService = new Pouchdb(remoteServiceURL)
  , remotePsalms = new Pouchdb(remotePsalmsURL)
  , remoteLectionary = new Pouchdb(remoteLectionaryURL)
  , default_prefs = {
      _id: 'preferences'
    , ot: 'ESV'
    , ps: 'BCP'
    , nt: 'ESV'
    , gs: 'ESV'
    , fnotes: 'True'
    , vers: ['ESV']
    , current: 'ESV'
  }
  , iphodOK = false
  , serviceOK = false
  , lectionaryOK = false
  , psalmsOK = false
  , esv_key = "77f1ef822a19e06867cf335a168713f9d2159bfc"
  ;

// these tests for necessary DBs are pretty fragile
// there is probably a smarter way to do this
// perhaps something with revision sequences
iphod.info()
.then( function(resp) { if (resp.doc_count > 39000) { iphodOK = true} })
service.info()
.then( function(resp) { if (resp.doc_count >= 11) { serviceOK = true} })
psalms.info()
.then( function(resp) { if (resp.doc_count >= 150) { psalmsOK = true} })
lectionary.info()
.then( function(resp) { if (resp.doc_count >= 366) { lectionaryOK = true} })

function sync() {
  send_status("updating iphod")
    remoteIphod.allDocs({include_docs: true})
    .then( 
      function(resp) { 
        send_status("iphod read");
        iphod.bulkDocs( resp.rows.map( function(r) { return r.doc}))
        .then( function(resp) { update_service() })
      })
    .catch( function(err) {
        send_status("Iphod update failed")
        console.log("IPHOD UPDATE ERR: ", err)
      })
}

function update_service() {
  send_status("updating services");
    remoteService.allDocs({include_docs: true})
    .then( function(resp) {
      send_status("services read");
      service.bulkDocs( resp.rows.map( function(r) { return r.doc }) )
      .then( function(resp) { update_psalms() })
    })
    .catch( function(err) {
      send_status("Services update failed")
      console.log("Services UPDATE ERR: ", err)
    })
}

function update_psalms() {
  send_status("updating psalms");
    remotePsalms.allDocs({include_docs: true})
    .then( function(resp) {
      send_status("psalms read");
      psalms.bulkDocs( resp.rows.map( function(r) { return r.doc }) )
      .then( function(resp) { update_lectionary() })
    })
    .catch( function(err) {
      send_status("Psalms update failed")
      console.log("Psalms UPDATE ERR: ", err)
    })
}
          

function update_lectionary() {
  send_status("updating lectionary");
    remoteLectionary.allDocs({include_docs: true})
    .then( function(resp) {
      send_status("lectionary read");
      lectionary.bulkDocs( resp.rows.map( function(r) { return r.doc }) )
      .then( function(resp) { send_status("all updated") })
    })
    .catch( function(err) {
      send_status("Lectionary update failed")
      console.log("Lectionary UPDATE ERR: ", err)
    })
}
          
function send_status(s) { app.ports.onlineStatus.send(s); }
function update_database() { send_status("update database"); }
function db_fail(s) { send_status( s + " unavailable"); }

function syncError() {};

// NEED TO ADD AN EVENT LISTENER TO CHECK FOR CONNECTIVITY
var isOnline = navigator.onLine; 
var esvOK = navigator.onLine && false; // false because don't have key yet


// window.addEventListener('online', updateOnlineIndicator() );  // only on Firefox
// window.addEventListener('offline', updateOnlineIndicator() );  // only on Firefox
function updateOnlineIndicator() {
  isOnline = navigator.onLine;
  app.ports.onlineStatus.send( isOnline ? "" : "off line")
  return isOnline
}

// if (isOnline) sync();

function service_response(named, resp) {
  var now = moment()
  , season = LitYear.toSeason(now)
  , iphodKey = season.season + season.week + season.year
  , serviceHeader = []
  ;
  iphod.get(iphodKey).then( function(euResp){
    service_header_response(now, season, named, resp, euResp)
  })
  .catch( function(err) {
    if ( updateOnlineIndicator() ) {
      remoteIphod.get(iphodKey).then (function(euResp) {
        service_header_response(now, season, named, resp, euResp);
      })
      .catch( function(err) {
        console.log("ERROR GETTING REMOTE IPHOD: ", err)
      })

    }
    console.log("ERROR GETTING IPHOD: ", err)
  })
}

function service_header_response(now, season, named, resp, euResp) {
  var today = now.format("dddd, MMMM Do YYYY")
  , day = [ "Sunday", "Monday", "Tuesday"
          , "Wednesday", "Thursday", "Friday"
          , "Saturday"
          ][now.weekday()]
  , serviceHeader = [ 
      today
    , day
    , season.week.toString()
    , season.year
    , season.season
    , euResp.colors[0]
    , named
  ]
  request_lessons(named);
  app.ports.receivedOffice.send(serviceHeader.concat(resp.service))  

}

function service_db_name(s) {
  var dbName = 
    { deacons_mass: "deacons_mass"
    , morning_prayer: "morning_prayer"
    , midday: "midday"
    , evening_prayer: "evening_prayer"
    , compline: "compline"
    , family: "family_prayers"
    , reconciliation: "reconciliation"
    , toTheSick: "ministry_to_sick"
    , communionToSick: "communion_to_sick"
    , timeOfDeath: "ministry_to_dying"
    , vigil: "vigil"
    , about: "about"
    };
  return dbName[s];
}

function get_service_from_db(dbs, named) {
  var thisDB = dbs.pop();
  thisDB.get( service_db_name(named) )
  .then( function(resp) {
    service_response(named, resp);
  })
  .catch( function(err) { 
    if (dbs.length > 0) { get_service_from_db(dbs, named) }
    else { 
      db_fail("Service")
    }
  })
}

function get_service(named) {
  // have to map offices here
  // we might want to add offices other than acna
  send_status("getting " + named )
  if (named === "sync") { return sync()}
  get_service_from_db([remoteService, service], named)
}


function get_preferences(do_this_too) {
  preferences.get('preferences').then(function(resp){
    return do_this_too(resp);
  }).catch(function(err){
    console.log("GET PREFERENCE ERR: ", err);
    return do_this_too(initialize_preferences());
  })
}

function initialize_preferences() {
  preferences.put( default_prefs ).then(function (resp) {
    return resp;
  }).catch( function (err) {
    return prefs;
  })
}

function save_preferences(prefs) {
  prefs._id = 'preferences';
  preferences.put(prefs).then(function(resp) {
    return resp;
  }).catch(function(err) {
    return prefs;
  })
}

function preference_list() {
  get_preferences(function(resp) {
    return [resp.ot, resp.ps, resp.nt, resp.gs];
  })
}

function preference_for(key) {
  get_preferences(function(resp) { return resp[key] })
}

function initElmHeader() {
  get_preferences(function(resp) {
    return elmHeaderApp.ports.portConfig.send(resp);
  })
}

// END OF POUCHDB ....................

$(window).on("resize", function() {
  var newWidth = $(window).width();
  app.ports.newWidth.send( newWidth )
})

app.ports.requestTodaysLessons.subscribe(  function(request) {
  $(".lessons_today").empty();
  var [office, day] = request;
  (office === "eu") ? getEucharistLessons(day) : getOfficeLessons(office, day)
})

function getOfficeLessons(office, day) {
  var key = "mpep" + datePad0(day.month) + datePad0(day.dayOfMonth);
  lectionary.get(key)
  .then(  function(resp) {
    putCalendarLessons(office + "1_today", resp[office + "1"] );
    putCalendarLessons(office + "2_today", resp[office + "2"] );
  })
  .catch(  function(err) {
  })
}

function getEucharistLessons(day) {
  var key = day.season + day.week + day.lityear;
  iphod.get(key)
  .then(  function(resp) {
    putCalendarLessons("eu1_today", resp.ot);
     putCalendarLessons("eu2_today", resp.nt);
    putCalendarLessons("eugs_today", resp.gs);
  })
  .catch(  function(err) {
    console.log("GET EU LESSONS ERROR: ", err)
  })
}

app.ports.clearLessons.subscribe(  function(request) {
  $(".lessons_today").empty();
})

function putCalendarLessons( divId, refs ) {
  $(".lessons_today").hide();
  var allPromises = []
    , keys = BibleRef.dbKeys( refs.map(  function(r) { return r.read } ) )
    ;
  allPromises = keys.map(  function(k) {
     return iphod.allDocs(
      { include_docs: true
      , startkey: k.from
      , endkey: k.to
      }
    )
  });
  Promise.all( allPromises ).then(  function(resp) {
    resp.forEach(  function(r) {
      var vss = "";
      r.rows.forEach(  function(rx) { vss += rx.doc.vss } );
      $("#" + divId).append("<div>" + vss + "</div>").show();
    })
  })
  .catch(  function(err) {
    console.log("ERROR - putCalendarLessons for " + divId + ": ", err)
  })
}


app.ports.requestOffice.subscribe( function(request) {
  var now = new moment().local();
  switch (request) {
    case "currentOffice": 
     // redirect to correct office based on local time
      var mid = new moment().local().hour(11).minute(30).second(0)
        , ep = new moment().local().hour(15).minute(0).second(0)
        , cmp = new moment().local().hour(20).minute(0).second(0)
        ;
      if ( now.isBefore(mid)) { get_service("morning_prayer") }
      else if ( now.isBefore(ep) ) { get_service("midday")} // { get_service("midday")}
      else if ( now.isBefore(cmp) ) { get_service("evening_prayer")} // { get_service ("evening_prayer") }
      else { get_service("compline")}
      break;
    case "calendar":
      Calendar.get_calendar( now, app.ports.receivedCalendar );
      break;
    default: 
      get_service(request);
  };
});

app.ports.changeMonth.subscribe( function( [toWhichMonth, fromMonth, year] ) {
  // month is coming as jan = 1; moment uses jan = 0
  // that's why the weird math in the next line
  var month = (toWhichMonth === "prev") ? fromMonth -1 : fromMonth + 1;
  switch (true) {
    case (month < 0): // december previous year
      return Calendar.get_calendar( moment([year - 1, 11, 31]), app.ports.receivedCalendar );
      break;
    case (month > 11): // january next year
      return Calendar.get_calendar( moment([year + 1, 0, 1]), app.ports.receivedCalendar );
      break;
    default: 
      return Calendar.get_calendar( moment([year, month, 1]), app.ports.receivedCalendar );
  }
})

app.ports.toggleButtons.subscribe(  function(request) {
  var [div, section_button] = request.map(  function(r) { return r.toLowerCase(); } );
  var section_id = section_button.replace("button", "id")
  $("#alternatives_" + div + " .alternative").hide(); // hide all the alternatives
  $("#" + section_id).show(); // show the selected alternative
})

app.ports.requestReference.subscribe(  function(request) {
  var [id, ref] = request
    , keys = BibleRef.dbKeys(ref)
    , allPromises = []
    ;
  keys.forEach(  function(k) {
    allPromises.push( iphod.allDocs(
      { include_docs: true
      , startkey: k.from
      , endkey: k.to
      }
    ));
  }); // end of keys.forEach
  return Promise.all( allPromises )
  .then(  function(resp) {
    var readingDiv = "<div id='ReferenceReading'></div>";
    $("#ReferenceReading").remove();
    $("#" + id).parent().append(readingDiv); 
    resp[0].rows.forEach(  function(r) {
      $("#ReferenceReading").append(r.doc.vss);
    });
  })
  .catch(  function(err) {
    console.log( "REQUEST READING ERROR: ", err);
  })
})

  app.ports.requestLessons.subscribe(  function(request) {
  request_lessons(request);
})

function request_lessons(request) {
  if ( ["morning_prayer", "evening_prayer", "eucharist"].includes(request) ) { 
    insertPsalms( request )
    insertLesson( "lesson1", request )
    insertLesson( "lesson2", request )
    // insertGospel( request )
    // insertCollect( request )
    // insertProper( request )
  }
  // otherwise, don't do anything
}

function get_from_lectionary_db(dbs, lesson, mpep, mpepRef) {
  var thisDB = dbs.pop();
  thisDB.get(mpepRef)
  .then( function(resp) { 
    // first db to check is at end of list
    get_from_scripture_db([ remoteIphod, iphod, 'esv'], mpep, lesson, resp); 
  })
  .catch( function(err) { 
    if ( dbs.length > 0 ) { get_from_lectionary_db( dbs, lesson, mpep, mpepRef ) }
    else { db_fail("Lectionary") }
  })
}

function insertLesson(lesson, office) {
  // mpepmmdd - mpep0122
  var mpep = (office === "morning_prayer") ? "mp" : "ep"
    , mpepRef = "mpep" + moment().format("MMDD")
    ;
    get_from_lectionary_db( [remoteLectionary, lectionary], lesson, mpep, mpepRef );
}

function get_from_scripture_db(dbs, mpep, lesson, resp) {
  var thisDB = dbs.pop();
  if (thisDB === 'esv') { get_from_esv(dbs, mpep, lesson, resp) }
  else {
    // var thisReading = resp[mpep + lesson.substr(-1)]
    // , refs = thisReading.map(  function(r)  { return r.read })
    // , styles = thisReading.map( function(r) { return r.style})
    var keys = BibleRef.dbKeys( resp[mpep + lesson.substr(-1)] ) 
      , allPromises = []
      ;
    keys.forEach( function(k, i) {
      allPromises.push( thisDB.allDocs(
        { include_docs: true
        , startkey: k.from
        , endkey: k.to
        }
      ))
    });
    return Promise.all( allPromises )
      .then( function(resp) {
        var thisLesson = [];
        resp.forEach( function(r, i) {
          thisLesson[i] =
            { ref: keys[i].ref
            , style: keys[i].style
            , vss: r.rows.map( function(el) { return el.doc } )
            }
        })
        app.ports.receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson}) );
      })
      .catch( function(err) {
        if ( dbs.length > 0 ) {  get_from_scripture_db(dbs, mpep, lesson, resp) }
        else { db_fail("Iphod") }
      });
    } // end of else
}

function get_from_esv(dbs, mpep, lesson, resp) {
  var keys = resp[mpep + lesson.substr(-1)]
  , allPromises = []
  ;
  var qx = keys.map( function(k) { return k.read } );
  qx.forEach( function(q, i) {
    allPromises.push( axios.get('https://api.esv.org/v3/passage/html/?q=' + q) )
  });
  return Promise.all( allPromises )
  .then( function(resp) {
    var thisLesson = [];
    resp.forEach( function(r, i){
      thisLesson[i] =
        { ref: r.data.canonical
        , style: keys[i].style
        , vss: [{ vss: r.data.passages.join("<br />") }]
        }
    })
    app.ports.receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson}) );
  })
  .catch( function(err) {
    console.log("ESV ERROR: ", err)
    get_from_scripture_db(dbs,mpep, lesson, resp);
  })
}

function insertGospel(office) {}

function insertCollect(office) {
    var now = moment()
    , season = LitYear.toSeason(now)
    , key = "collect_" + season.season
    , collectDiv = "#collectOfDay"
    ;
  if ( ! ["ashWednesday", "annunciation", "allSaints"].includes(season.season) ) {
    key = key + season.week
  } 
  iphod.get(key).then(  function(resp) {
    $(collectDiv + " .collectTitle").append("Collect of The Day <em>" + resp.title + "</em>")
    $(collectDiv + " .collectContent").append(resp.text[0])
  })
  .catch(  function(err) {
    console.log("GET COLLET ERROR: ". err)
  })

}

function try_esv(mpep, lesson, resp) {
  if (esvOK) { return false; }
  return false;
}

function insertProper(office) {}

function insertPsalms(office) {
  var now = moment()
    , mpep = (office === "morning_prayer") ? "mp" : "ep"
    , dayOfMonth = now.date()
    , psalmRefs = DailyPsalms.dailyPsalms[dayOfMonth][mpep]
    , thesePsalms = psalmRefs.map(  function(p) { return "acna" + p[0] } )
    , allPromises = []
    ;
    thesePsalms.forEach(  function(p) { allPromises.push( psalms.get(p) ) });
    Promise.all( allPromises )
      .then(  function(resp) { psalm_response(psalmRefs, resp) })
      .catch(  function(err) {
        if (updateOnlineIndicator() ) {
          allPromises = [];
          thesePsalms.forEach( function(p) { allPromises.push( remotePsalms.get(p) ) });
          Promise.all( allPromises )
          .then( function(resp) { psalm_response(psalmRefs, resp) })
          .catch( function(err) { console.log("PROBLEM GETTING REMOTE PSALMS: " + err) });
        }
        console.log("PROBLEM GETTING PSALMS: " + err);
      })
}

function psalm_response(psalmRefs, resp) {
  // A lesson has 1 or more readings
  // a reading has 1 or more verses
  var thisLesson = [] // all the lessons from this response
  resp.forEach( function(r,i) {
    var vss = []; // all the verses for this reading
    var [chap, from, to] = psalmRefs[i]
    for(var j = from; j <= to; j++) { // add these verses to the reading
      if (r[j] === undefined) { break; }
      vss.push(
        { book: "PSA"
        , chap: chap
        , vs: j
        , vss: [r[j].hebrew, r[j].title, r[j].first, r[j].second].join("\n")
        }
      )
    }
    thisLesson.push ( // add this reading to the lesson
      { ref: r.name + "\n" + (r.title ? r.title : "") //some titles are undefined
      , style: "req"
      , vss: vss
      }
    )
  }) // end of resp.forEach
  app.ports.receivedLesson.send( JSON.stringify({lesson: "psalms", content: thisLesson}) )

}



// ----

function showPsalms(pss) {
  pss.forEach(  function(ps) {
    var title = ps.title ? ps.title : "";
    $("#psalms").append("<p class='psalm_name'>" + ps.name + "<span>" + title + "</span></p>")
    for (var i = ps.from; i <= ps.to; i++) {
      if (ps[i] === undefined) break;
      var sectionTitle = ps[i].title ? ps[i].title : ""
        , hebrew = ps[i].hebrew ? ps[i].hebrew : ""
        ;
      if ( sectionTitle.length > 0 ) {
        $("#psalms").append("<p class='psalm_name'>" + sectionTitle + "<span>" + hebrew + "</span></p>")
      }
      $("#psalms").append("<p class='psalm1'><sup>" + i + "</sup>" + ps[i].first + "</p>");
      $("#psalms").append("<p class='psalm2'>" + ps[i].second + "</p>")
    }
  })
  return pss;
}

function datePad0(n) {
  if (n < 10) return "0" + n;
  return '' + n;
}

