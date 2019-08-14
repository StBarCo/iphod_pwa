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


// define ports (so they can be passed in callbacks)
var receivedLesson = undefined
  , onlineStatus = undefined
  , receivedOffice = undefined
  , receivedCalendar = undefined
  , receivedPrayerList = undefined
  , newWidth = undefined
  ;


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
// window.pdb = Pouchdb;
var blork = new Pouchdb('blork');
var preferences = new Pouchdb('preferences');
var iphod = new Pouchdb('iphod')
var service = new Pouchdb('service_dev')
var psalms = new Pouchdb('psalms')
var lectionary = new Pouchdb('lectionary')
var prayerList = new Pouchdb('prayerList'); // never replicate!
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

  import $ from 'jquery';
window.onload = ( function() {
  receivedLesson = app.ports.receivedLesson;
  onlineStatus = app.ports.onlineStatus;
  receivedOffice = app.ports.receivedOffice;
  receivedCalendar = app.ports.receivedCalendar;
  receivedPrayerList = app.ports.receivedPrayerList;
  newWidth = app.ports.newWidth;
  onlineStatus.send( "All Ready");
  iphod.info().then( function(resp) {
    if (resp.doc_count > 0) { sync(); }
  })
}) // end of window.onload


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
  iphod.replicate.from(remoteIphod)
  .on("complete", function(){
    psalms.replicate.from(remotePsalms)
    .on("complete", function() {
      service.replicate.from(remoteService)
      .on("complete", function() {
        lectionary.replicate.from(remoteLectionary)
        .on("complete", function() {
          send_status("Sync complete");
        })
      })
    })
  })
  .on("error", function(err) {
    console.log("SYNC ERROR: ", error);
    send_status("Sync failed");
  })
}

          
function send_status(s) { onlineStatus.send(s); }
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
  onlineStatus.send( isOnline ? "" : "off line")
  return isOnline
}

// if (isOnline) sync();

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
  request_lessons(named, now); // promise the lessons will be sent

  receivedOffice.send(serviceHeader.concat(resp.service))

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
    , calendar: "calendar"
    , prayerList: "prayer_list"
    };
  return dbName[s];
}

function get_service(named) {
  // have to map offices here
  // we might want to add offices other than acna
  send_status("getting " + named )
  if (named === "sync") { return sync() }
  service.get( service_db_name(named) )
  .then ( function(resp) {
    service_response(named, resp);
    get_prayer_list();
  })
  .catch( function(err) {
    db_fail("Service " + named)
  })
}


function service_response(named, resp) {
  var now = moment();
  var season = LitYear.toSeason(now);
  var iphodKey = season.iphodKey;

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

// PRAYER LIST

app.ports.prayerListDB.subscribe( function(request) {
  var [cmd, id, who, why, ofType, date] = request;
  var prayer =
    { who: who
    , why: why
    , ofType: ofType
    , date: date
    };
  switch (cmd) {
    case "new" :
      prayerList.post(prayer)
      .then (function(resp) {
        get_prayer_list();
      })
      .catch ( function(err) {
        console.log("ERROR SAVING PRAYER: ", err)
      })
      break;
    case "save" :
      // to save properly, first you have to get the rev
      prayerList.get(id)
      .then( function(doc){
        prayer._id = id;
        prayer._rev = doc._rev;
        prayerList.put(prayer)
        .then( function(resp){ get_prayer_list() })
      })
      .catch( function(err){
        console.log("Error saving prayer", err)
      })
      break;
    case "delete" :
      prayerList.get(id)
      .then( function(doc) {
        prayerList.remove(doc)
        .then( function(resp) {
          get_prayer_list()
        })
      })
      .catch( function(err) {
        console.log("Failed to remove prayer: ", err)
      })
      break;
    default:
      break;
    }
})

// END OF PRAYER LIST


$(window).on("resize", function() {
  newWidth.send( $(window).width() );
})

app.ports.calendarReadingRequest.subscribe( function(req) {
  var now = moment( { year: req.year
        , month: req.month
        , date: req.dayOfMonth 
        });
  var sn = LitYear.toSeason(now)
  var [key, db] = req.service === "eu" ? [sn.iphodKey, iphod] : [sn.mpepKey, lectionary]

  switch (req.reading) {
    case "lesson1":
        insertLesson( "lesson1", req.service, key, req.service )
      break;

    case "lesson2":
        insertLesson( "lesson2", req.service, key, req.service )
      break;

    case "psalms":
      req.service === "eu"
        ? insertEucharistPsalms(req.service, key)
        : insertPsalms( req.service, req.service)
      break;

    case "gospel":
      insertLesson( "gospel", req.service, key, req.service)
      // insertGospel(req.service, key)
      break;

    case "all":
        insertLesson( "lesson1", req.service, key, req.service )
        insertLesson( "lesson2", req.service, key, req.service )
        req.service === "eu" 
          ? insertEucharistPsalms(req.service, key)
          : insertPsalms( req.service, req.service )
        insertLesson( "gospel", req.service, key, req.service)
        // insertGospel(req.service, key)
      break;

    default:
      consolelog("CALENDAR READING REQUEST, can't find: ", req.reading);
  }
})


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
      get_service("calendar");
      Calendar.get_calendar( now, receivedCalendar );
      break;
    case "prayerList":
      get_service(request)
      get_prayer_list();
      break;
    default: 
      get_service(request);
  };
});

function get_prayer_list() {
  prayerList.allDocs({include_docs: true, limit: 50})
  .then( function(resp) {
    var prayers = resp.rows.map( r => {
      return  { id: r.doc._id
              , who: r.doc.who
              , why: r.doc.why
              , ofType: r.doc.ofType
              , tillWhen: r.doc.tillWhen
            }
    })
    receivedPrayerList.send( JSON.stringify( {prayers: prayers} ))
  })
  .catch( function(err) {
    console.log("ERROR GETTING PRAYER LIST: ", err);
  })
}

app.ports.changeMonth.subscribe( function( [toWhichMonth, fromMonth, year] ) {
  // month is coming as jan = 1; moment uses jan = 0
  // that's why the weird math in the next line
  var month = (toWhichMonth === "prev") ? fromMonth -1 : fromMonth + 1;
  switch (true) {
    case (month < 0): // december previous year
      return Calendar.get_calendar( moment([year - 1, 11, 31]), receivedCalendar );
      break;
    case (month > 11): // january next year
      return Calendar.get_calendar( moment([year + 1, 0, 1]), receivedCalendar );
      break;
    default: 
      return Calendar.get_calendar( moment([year, month, 1]), receivedCalendar );
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
  var today = new moment().local();
  request_lessons(request, today );
})

function request_lessons(request, today) {
  var offices = 
    { morning_prayer: "mp"
    , evening_prayer: "ep"
    , eucharist: "eu"
    }
    , office = offices[request]
    ;
  if ( office ) { 
    var mpepKey = LitYear.toSeason(today).mpepKey
    insertPsalms( office, "office" )
    insertLesson( "lesson1", office, mpepKey, "office" )
    insertLesson( "lesson2", office, mpepKey, "office" )
  }
  // otherwise, don't do anything
}

function insertLesson(lesson, office, key, spa_location) {
  // mpepmmdd - mpep0122
  if (office === "eu" ) {
    get_from_eucharist(lesson, key, spa_location)
  }
  else {
    get_from_lectionary_db( 
        office
      , lesson
      , key
      , spa_location
      );
  }
}

function get_from_eucharist( lesson, key, spa_location ) {
  iphod.get(key)
  .then( function(resp) {
    var eu_key = 
    { lesson1: "ot"
    , lesson2: "nt"
    , psalms: "ps"
    , gospel: "gs"
    }[lesson];
    var lessonKeys = resp[eu_key];
    get_from_scripture_db([iphod, 'esv'], "eu", lesson, lessonKeys, spa_location)
  })
}

function get_from_lectionary_db(office, lesson, mpepKey, spa_location) {
  lectionary.get(mpepKey)
  .then( function(resp) { 
    // first db to check is at end of list
    var lessonKeys = resp[office + lesson.substr(-1)];
    get_from_scripture_db([ iphod, 'esv'], office, lesson, lessonKeys, spa_location); 
  })
  .catch( function(err) { 
    db_fail("Lectionary");
  })
}

function get_from_scripture_db(dbs, office, lesson, lessonKeys, spa_location) {
  var thisDB = dbs.pop();
  if (thisDB === 'esv') { get_from_esv(dbs, office, lesson, lessonKeys, spa_location) }
  else {
    var keys = BibleRef.dbKeys( lessonKeys ) 
      , allPromises = []
      ;
    keys.forEach( function(k) {
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
        receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson, spa_location: spa_location}) );
      })
      .catch( function(err) {
        if ( dbs.length > 0 ) {  get_from_scripture_db(dbs, office, lesson, lessonKeys, spa_location) }
        else { db_fail("Iphod") }
      });
    } // end of else
}

function get_from_esv(dbs, office, lesson, lessonKeys, spa_location) {
  var allPromises = [];
  var qx = lessonKeys.map( function(k) { return k.read } );
  qx.forEach( function(q, i) {
    allPromises.push( axios.get('https://api.esv.org/v3/passage/html/?q=' + q) )
  });
  return Promise.all( allPromises )
  .then( function(resp) {
    var thisLesson = [];
    resp.forEach( function(r, i){
      thisLesson[i] =
        { ref: r.data.canonical
        , style: lessonKeys[i].style
        , vss: [{ vss: r.data.passages.join("<br />") }]
        }
    })
    receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson, spa_location: spa_location}) );
  })
  .catch( function(err) {
    console.log("ESV ERROR: ", err)
    get_from_scripture_db(dbs, office, lesson, resp);
  })
}

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

function insertEucharistPsalms(spa_location, key) {
  iphod.get(key)
  .then( function(resp) {
    var psalms = resp.ps
    var psalmRefs = BibleRef.dbKeys(psalms)
    allPsalms(psalmRefs, spa_location);
  })
  .catch( function(err) {
    console.log("Eucharist Psalms fail:  " + err)
  })
}

function insertPsalms(office, spa_location) {
  var now = moment()
    , mpep = (office === "morning_prayer") ? "mp" : "ep"
    , dayOfMonth = now.date()
    , psalmRefs = DailyPsalms.dailyPsalms[dayOfMonth][mpep]
    allPsalms(psalmRefs);
}

function allPsalms(psalmRefs, spa_location) {
  var allPromises = [];
  var thesePsalms = psalmRefs.map( p => { return "acna" + p[0] });
  thesePsalms.forEach( p => { allPromises.push( psalms.get(p) ) });
  Promise.all( allPromises )
    .then(  function(resp) { psalm_response(psalmRefs, resp, spa_location) })
    .catch(  function(err) {
      if (updateOnlineIndicator() ) {
        allPromises = [];
        thesePsalms.forEach( function(p) { allPromises.push( remotePsalms.get(p) ) });
        Promise.all( allPromises )
        .then( function(resp) { psalm_response(psalmRefs, resp, spa_location) })
        .catch( function(err) { console.log("PROBLEM GETTING REMOTE PSALMS: " + err) });
      }
      console.log("PROBLEM GETTING PSALMS: " + err);
    })
}

function psalm_response(psalmRefs, resp, spa_location) {
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
  receivedLesson.send( JSON.stringify({lesson: "psalms", content: thisLesson, spa_location: spa_location}) )

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
