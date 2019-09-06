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
  , receivedCollect = undefined
  , receivedOPCats = undefined
  , receivedOPs = undefined
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
import PouchFind from 'pouchdb-find'
Pouchdb.plugin(PouchFind);
window.pdb = Pouchdb;
var preferences = new Pouchdb('preferences');
var iphod = new Pouchdb('iphod')
var service = new Pouchdb('service')
var old_service = new Pouchdb('service_dev');
var psalms = new Pouchdb('psalms')
var lectionary = new Pouchdb('lectionary')
var prayerList = new Pouchdb('prayerList'); // never replicate!
var occasional_prayers = new Pouchdb('occasional_prayers');
var dbOpts = { live: true, retry: true }
  , remoteIphodURL =      "https://legereme.com/couchdb/iphod"
  , remoteServiceURL =    "https://legereme.com/couchdb/service"
  , remotePsalmsURL =     "https://legereme.com/couchdb/psalms"
  , remoteLectionaryURL = "https://legereme.com/couchdb/lectionary"
  , remoteOpsURL = "https://legereme.com/couchdb/occasional_prayers"
  , remoteIphod = new Pouchdb(remoteIphodURL)
  , remoteService = new Pouchdb(remoteServiceURL)
  , remotePsalms = new Pouchdb(remotePsalmsURL)
  , remoteLectionary = new Pouchdb(remoteLectionaryURL)
  , remoteOps = new Pouchdb(remoteOpsURL)
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
  , pageTops = [];
  ;

  import $ from 'jquery';
window.onload = ( function() {
  receivedLesson = app.ports.receivedLesson;
  onlineStatus = app.ports.onlineStatus;
  receivedOffice = app.ports.receivedOffice;
  receivedCalendar = app.ports.receivedCalendar;
  receivedPrayerList = app.ports.receivedPrayerList;
  receivedCollect = app.ports.receivedCollect;
  receivedOPCats = app.ports.receivedOPCats;
  receivedOPs = app.ports.receivedOPs
  newWidth = app.ports.newWidth;
  // onlineStatus.send( "All Ready");
  requestOffice('currentOffice')
  iphod.info().then( function(resp) {
    if (resp.doc_count > 0) { sync(); }
  })
  // make sure the old service isn't kept on mobile device
  old_service.destroy()
  .then ( r => { old_service = undefined } );
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
          occasional_prayers.replicate.from(remoteOps)
          .on("complete", function() {
            send_status("Sync complete");
          })
        })
      })
    })
  })
  .on("error", function(err) {
    console.log("SYNC ERROR: ", err);
    send_status("Sync failed");
  })
}

          
function send_status(s) { onlineStatus.send(s); }
function update_database() { send_status("update database"); }
function db_fail(s) { send_status( s + " unavailable"); }

function syncError() {};

// NEED TO ADD AN EVENT LISTENER TO CHECK FOR CONNECTIVITY
var isOnline = navigator.onLine; 
var esvOK = navigator.onLine; // false because don't have key yet


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
  requestSeasonalCollect(euResp._id);
  getCollect(dailyId(named), "daily");
  request_lessons(named, now); // promise the lessons will be sent

  receivedOffice.send(serviceHeader.concat(resp.service))

}


app.ports.requestCollect.subscribe( id => {
  var ofType = "traditional";
  // I think this request for a collect should always have
  // a read id - not a 'fake' one e.g. "daily" or "seasonal"
  // if (id == "daily") {
  //   ofType = id;
  //   id = dailyId();
  // }
  getCollect(id, ofType)
})

function dailyId(service) {
  // service should either be "morning_prayer" or "evening_prayer"
  var mpep = service === "morning_prayer" ? "_mp" : "_ep";
  return "collect_" + 
    ["sunday", "monday", "tuesday"
    , "wednesday", "thursday", "friday"
    , "saturday"
    ][moment().weekday()]
    + mpep;
}

function getCollect(id, ofType) {
  // send t/f as string so I don't have to convert an object
  // to json and srite another decoder
  // 'cause I'm beig lazy
  iphodGet( id, [remoteIphod, iphod], ( resp => {
    var id = resp._id;
    if (ofType === "seasonal" || ofType === "daily") { id = ofType; }
    receivedCollect.send( [ofType, id, resp.title, resp.text[0] ] )
  }))
}

function requestSeasonalCollect(season) {
  var id = 'collect_' + season;

  // if the collectId ends with a,b, or c - drop the last char
  switch (id.slice(-1)) {
    case 'a' :
    case 'b' :
    case 'c' :
      id = id.slice(0,-1)
  }
  getCollect(id, "seasonal")

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
    , occasionalPrayers: "occasional_prayers"
    };
  return dbName[s];
}

function get_service(named, dbs) {
  var thisServiceDB = dbs.pop();

  // have to map offices here
  // we might want to add offices other than acna
  // send_status("getting " + named )
  if (thisServiceDB) {
    if (named === "sync") { return sync() }
    thisServiceDB.get( service_db_name(named) )
    .then ( function(resp) {
      pageTops = []; // global, reset with new service
      service_response(named, resp);
      get_prayer_list();
      sync();
    })
    .catch( function(err) {
      if (dbs.length > 0) {
        get_service(named, dbs);
      }
      else { db_fail("Service " + named) }
    }) 
  }
  else { send_status("Service Database Unavailable"); }
}

function iphodGet(key, dbs, callback) {
  var thisIphod = dbs.pop();
  thisIphod.get(key)
  .then ( resp => { callback(resp) })
  .catch( err => {
    if ( updateOnlineIndicator() && dbs.length > 0) { iphodGet(key, dbs, callback) }
    else {
      console.log("Error: Iphod DB not available - ", err)
        send_status("Error: Iphod DB not available")
    }
  })
}

function service_response(named, resp) {
  var now = moment();
  var season = LitYear.toSeason(now);
  var iphodKey = season.iphodKey;
  iphodGet(iphodKey, [remoteIphod, iphod], (euresp => {
    service_header_response(now, season, named, resp, euresp)
  }))
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
  var [cmd, id, who, why, ofType, opId, date] = request;
  var prayer =
    { who: who
    , why: why
    , ofType: ofType
    , opId: opId
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


app.ports.requestOffice.subscribe( r => { requestOffice(r) });

function requestOffice(request, dbs) {
  var now = new moment().local();
  switch (request) {
    case "currentOffice": 
     // redirect to correct office based on local time
      var mid = new moment().local().hour(11).minute(30).second(0)
        , ep = new moment().local().hour(15).minute(0).second(0)
        , cmp = new moment().local().hour(20).minute(0).second(0)
        ;
      if ( now.isBefore(mid)) { get_service("morning_prayer", [remoteService, service]) }
      else if ( now.isBefore(ep) ) { get_service("midday", [remoteService, service])} // { get_service("midday")}
      else if ( now.isBefore(cmp) ) { get_service("evening_prayer", [remoteService, service])} // { get_service ("evening_prayer") }
      else { get_service("compline", [remoteService, service])}
      break;
    case "calendar":
      get_service("calendar", [remoteService, service]);
      Calendar.get_calendar( now, receivedCalendar );
      break;
    case "prayerList":
      get_service(request, [remoteService, service])
      get_prayer_list();
      get_ops_categories()
      break;

    case "occasionalPrayers":
      get_service(request, [remoteService, service])
      get_ops_categories();
      break;
    default: 
      get_service(request, [remoteService, service]);
  };
};

function getOccasionalPrayers(key, dbs, callback) {
  var thisOPsDB = dbs.pop();
  thisOPsDB.get(key)
  .then ( resp => {
    callback(resp);
  })
  .catch ( err => {
    if (dbs.length > 0) { getOccasionalPrayers( key, dbs, callback ); }
    else { send_status( "Error: Occasional Prayer DB (get) not available" ); }
  })
}

function get_ops_categories() {
  getOccasionalPrayers( "categories", [remoteOps, occasional_prayers], ( resp => {
    receivedOPCats.send(resp.list)
  }) )
}

function findOccassionalPrayer( selector, dbs, callback) {
  var thisOPsDB = dbs.pop();
  thisOPsDB.find(selector)
  .then ( resp => { 
    if ( resp.warning ) { findOccassionalPrayer(selector, dbs, callback); } 
    else { callback( resp ) }
  })
  .catch ( err => {
    if ( dbs.length > 0) { findOccassionalPrayer(selector, dbs, callback); }
    else { send_status("Error: Occasion Prayer DB (find) not available"); }
  })
}

app.ports.requestOPsByCat.subscribe( request => {
  findOccassionalPrayer( 
      {selector: {category: request}}
    , (resp => {
      var docs = resp.docs;
      docs = docs.map( d => { d.id = d._id; return d } )
      receivedOPs.send( JSON.stringify({cat: request, prayers: docs}) )
    }) )
})

function allOPsDocs( selector, dbs, callback ) {
  var thisOPsDB = dbs.pop();
  thisOPsDB.allDocs( selector )
  .then ( resp => {
    if ( resp.warning ) { allOPsDocs(selector, dbs, callback); }
    else { callback(resp) }
  })
  .catch ( err => {
    if ( dbs.length > 0 ) { allOPsDocs(selector, dbs, callback); }
    else { send_status( "Error: Occasional Prayer DB (allDocs) not available"); }
  })
}

function get_prayer_list() {
  prayerList.allDocs({include_docs: true, limit: 50})
  .then( function(resp) {
    var prayers = resp.rows.map( r => {
      r.doc.id = r.doc._id;
      if (r.doc.opId === undefined) { r.doc.opId = "op000"}
      return r.doc;
    })
    prayers.sort( (a, b) => { 
      if (a.opId > b.opId) { return 1; } 
      return -1;
    })
    receivedPrayerList.send( JSON.stringify( {prayers: prayers} ))
    // get a set of unique OPs, sort
    var keys = [ ... new Set( prayers.map( p => { return p.opId }) ) ].sort();
    allOPsDocs(
        { include_docs: true
        , keys: keys
        }
      , [remoteOps, occasional_prayers]
      , ( resp => {
          var docs = resp.rows.map( r => { return r.doc });
          docs = docs.map( d => { d.id = d._id; return d } )
          receivedOPs.send( JSON.stringify({cat: "multiple", prayers: docs})
        )}
      )
    )
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

app.ports.swipeLeftRight.subscribe( swipe => {
  var headerOffset = 60;
  var topNow = window.scrollY;
  var breakNow = false;
  var goto = topNow;
  if (pageTops.length === 0) {
    pageTops = []
      .slice
      .call( document.getElementsByClassName('page'))
      .map( p => { return p.getBoundingClientRect().top - headerOffset} )
  }
  for( let i = 0; i < pageTops.length; i++ ) {
    var p = pageTops[i]
    if (swipe === 'right') {
      goto = p;
      if (p > topNow) { break; }
    }
    else {
      if (p > topNow) { 
        goto = pageTops[i-2] ? pageTops[i-2] : 0
        break; 
      };
    }
  }
  window.scroll(0, goto)
})

app.ports.requestLessons.subscribe(  function(request) {
  var today = new moment().local();
  var pages = document.getElementsByClassName['page']
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
  iphodGet(key, [remoteIphod, iphod], ( resp => {
    var eu_key = 
    { lesson1: "ot"
    , lesson2: "nt"
    , psalms: "ps"
    , gospel: "gs"
    }[lesson];
    var lessonKeys = resp[eu_key];
    get_from_scripture_db([iphod, 'esv'], "eu", lesson, lessonKeys, spa_location)
  }))
}

function getLectionary(key, dbs, callback) {
  var thisLectionaryDB = dbs.pop();
  thisLectionaryDB.get(key)
  .then ( resp => { callback(resp); })
  .catch ( err => {
    if (dbs.length > 0) { getLectionary(key, dbs, callback); }
    else { send_status("Error: Lectionary DB not available")}
  })
}
function get_from_lectionary_db(office, lesson, mpepKey, spa_location) {
  getLectionary(mpepKey, [remoteLectionary, lectionary], (resp =>{
    // first db to check is at end of list
    var lessonKeys = resp[office + lesson.substr(-1)];
    get_from_scripture_db([ iphod, 'esv'], office, lesson, lessonKeys, spa_location); 
  }) )
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
      // here's the problem - a request might have multiple parts, 
      // so we get multiple responses - it's possible, although HIGHLY
      // unlikely for one response to succeed and another fail
      // What to do in that case? Beats me.
      // Here we will ASSUME if the first response succeeds they all succeed
      // and if the first fails - they all fail.
      // The frustrating thing in the ESV API is, if you ask for a bogus
      // Biblical reference, the request will succeed and return no text
      // .e.g. Blork 1:1-10 succeeds, but returns no text, canonical name
      // With an invalid ref. the ESV API will return an empty reference
      // per following test
      if (resp[0].data.canonical.length > 0) {
        resp.forEach( function(r, i){
            // if r.data.passages.length == 0 ESV API returned no text
            // probably apacrophyal 
            thisLesson[i] =
              { ref: r.data.canonical
              , style: lessonKeys[i].style
              , vss: [{ vss: r.data.passages.join("<br />") }]
              }
        })
        receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson, spa_location: spa_location}) );
      }
      else { 
        get_from_scripture_db(dbs, office, lesson, lessonKeys, spa_location); }
  })
  .catch( function(err) {
    console.log("ESV ERROR: ", err)
    get_from_scripture_db(dbs, office, lesson, lessonKeys, spa_location);
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
  iphodGet(key, [remoteIphod, iphod], ( resp => {
    $(collectDiv + " .collectTitle").append("Collect of The Day <em>" + resp.title + "</em>")
    $(collectDiv + " .collectContent").append(resp.text[0])
  }))
}

function try_esv(mpep, lesson, resp) {
  if (esvOK) { return false; }
  return false;
}

function insertProper(office) {}

function insertEucharistPsalms(spa_location, key) {
  iphodGet(key, [remoteIphod, iphod], ( resp => {
    var psalms = resp.ps
    var psalmRefs = BibleRef.dbKeys(psalms)
    allPsalms(psalmRefs, spa_location);
  }))
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
      else { console.log("PROBLEM GETTING PSALMS: " + err); }
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
