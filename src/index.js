import './js/scripture.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

window.app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: [window.innerHeight, window.innerWidth]
});

registerServiceWorker();

var UseLocalDB = true; // ! /silk/i.exec(navigator.userAgent);

// axios is an HTTP lib, used for accessing the ESV API
// thought you'd like to know
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
  , receivedAllCanticles = undefined
  , receivedOfficeCanticles = undefined
  , receivedNewCanticle = undefined
  , receivedConfig = undefined
  , newWidth = undefined
  , CurrentPage = undefined
  , Config = 
    { _id: "config"
    , readingCycle: "OneYear"
    , psalmsCycle: "ThirtyDay"
    , fontSize: 14 
    }
  , ready = false;
// for global configuration access, set later
  ;

// Config helpers ...
function skipSecondLesson(lesson) {
  return (lesson === "lesson2" && twoYearCycle() )
}

function twoYearCycle() { return (Config.readingCycle === "TwoYear") }
function oneYearCycle() { return (Config.readingCycle === "OneYear")}
function thirtyDayCycle() { return (Config.psalmsCycle === "ThirtyDay")}
function sixtyDayCycle() { return (Config.psalmsCycle === "SixtyDay")}

function twoYearKey(office) {
  var officeYear = office + (moment().year() % 2);
    return { 
      morning_prayer0: "mp1"
    , mp0: "mp1"
    , morning_prayer1: "ep1"
    , mp1: "ep1"
    , evening_prayer0: "mp2"
    , ep0: "mp2"
    , evening_prayer1: "ep2"
    , ep1: "ep2"
    }[officeYear]; 
}

// end of Config helpers


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
import PouchDB from 'pouchdb';
window.PDB = PouchDB;

import PouchdbFind from 'pouchdb-find';
PouchDB.plugin(PouchdbFind);

import PouchdbAdapter from 'pouchdb-adapter-websql';
PouchDB.plugin(PouchdbAdapter);

var preferences = new PouchDB('preferences');
var iphod = new PouchDB('iphod')
var service = new PouchDB('service') // for production
var psalms = new PouchDB('psalms')
var DOdb = new PouchDB('DOdb')
var prayerList = new PouchDB('prayerList'); // never replicate!
var config = new PouchDB('config'); // never replicate!
var canticles = new PouchDB('canticles');
var occasional_prayers = new PouchDB('occasional_prayers');
var dbOpts = { live: true, retry: true }
  , remoteIphodURL =      "https://bcp2019.com/couchdb/iphod"
  // , remoteServiceURL =    "https://bcp2019.com/couchdb/service_dev" // for development
  , remoteServiceURL =    "https://bcp2019.com/couchdb/service" // for production
  , remotePsalmsURL =     "https://bcp2019.com/couchdb/psalms"
  , remoteLectionaryURL = "https://bcp2019.com/couchdb/lectionary"
  , remoteCanticles = "https://bcp2019.com/couchdb/canticles"
  , remoteOpsURL = "https://bcp2019.com/couchdb/occasional_prayers"
  , remoteIphod = new PouchDB(remoteIphodURL)
  , remoteService = new PouchDB(remoteServiceURL)
  , remotePsalms = new PouchDB(remotePsalmsURL)
  , remoteLectionary = new PouchDB(remoteLectionaryURL)
  , remoteCanticles = new PouchDB(remoteCanticles)
  , remoteOps = new PouchDB(remoteOpsURL)
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
  receivedAllCanticles = app.ports.receivedAllCanticles
  receivedOfficeCanticles = app.ports.receivedOfficeCanticles
  receivedNewCanticle = app.ports.receivedNewCanticle
  receivedConfig = app.ports.receivedConfig
  newWidth = app.ports.newWidth;
  iphod.info().then( function(resp) {
    // if resp.doc_count > 0, there is an existing DB and it should be synced
    // is this the right place to do it?
    if (resp.doc_count > 0) { sync(); } // this test makes no sense, explain?
  ready = true;
  get_config();
  get_prayer_list();
  send_status("Ready")
  })

}) // end of window.onload

function getDBsFor(dbName) {
  if (UseLocalDB) { return getAllDBsFor(dbName) }
  switch (dbName) {
    case "iphod": return [remoteIphod]; break;
    case "canticles": return [remoteCanticles]; break;
    case "service": return [remoteService]; break;
    case "psalms": return [remotePsalms]; break;
    case "lectionary": return [remoteLectionary]; break;
    case "occasional_prayers": return [remoteOps]; break;
    default: return [];
  }
}
function getAllDBsFor(dbName) {
  switch (dbName) {
    case "iphod": return [remoteIphod, iphod]; break;
    case "canticles": return [remoteCanticles, canticles]; break;
    case "service": return [remoteService, service]; break;
    case "psalms": return [remotePsalms, psalms]; break;
    case "lectionary": return [remoteLectionary, DOdb]; break;
    case "occasional_prayers": return [remoteOps, occasional_prayers]; break;
    default: return []
  }
}


// these tests for necessary DBs are pretty fragile
// there is probably a smarter way to do this
// perhaps something with revision sequences
iphod.info()
.then( function(resp) { if (resp.doc_count > 39000) { iphodOK = true} })
service.info()
.then( function(resp) { if (resp.doc_count >= 11) { serviceOK = true} })
psalms.info()
.then( function(resp) { if (resp.doc_count >= 150) { psalmsOK = true} })
DOdb.info()
.then( function(resp) { if (resp.doc_count >= 366) { lectionaryOK = true} })

// sync can hold things up unless you sync one at a time
function sync() {
  if (!ready) { return undefined }
  var options = {live: true, retry: true};
  if (!isOnline) return send_status("Offline")
  send_status("Syncing Iphod")
  try {
    iphod.replicate.from(remoteIphod, options)
      .on("complete", function(){
        send_status("Iphod Synced")
      })
  }
  catch(err) { console.log(err)}
  try {
    psalms.replicate.from(remotePsalms, options)
    .on("complete", function() {
      send_status("Psalms Synced")
    })
  }
  catch(err) { console.log(err)}

  try {
    DOdb.replicate.from(remoteLectionary, options)
    .on("complete", function() {
      send_status("Lectionary Synced")
    })
  }
  catch(err) { console.log(err)}
  
  try {
    occasional_prayers.replicate.from(remoteOps, options)
    .on("complete", function() {
      send_status("Occasional Prayers Synced")
    })
  }
  catch(err) { console.log(err)}

  try {
    canticles.replicate.from(remoteCanticles, options)
    .on("complete", function() {
      send_status("Canticles Synced")
    })
  }
  catch(err) { console.log(err)}

  try {
    service.replicate.from(remoteService, options)
    .on("complete", function() {
    send_status("Services Synced");
    })
  }
  catch(err) { console.log(err)}

  ('serviceWorker' in navigator) ? send_status("Service Worker Ready") : send_status("No Service Worker")
  //.on("error", function(err) {
  //  console.log("SYNC ERROR: ", err);
  //  send_status("Sync failed");
  //})
}


          
function send_status(s) { 
  if (onlineStatus) { onlineStatus.send(s) }
  else { console.log("Error: Online Status still iundefined: ", s) }
}

function db_fail(s) { send_status( s + " unavailable"); }

function syncError() {};

// NEED TO ADD AN EVENT LISTENER TO CHECK FOR CONNECTIVITY
var isOnline = navigator.onLine; 
var esvOK = navigator.onLine; // false because don't have key yet


// window.addEventListener('online', updateOnlineIndicator() );  // only on Firefox
// window.addEventListener('offline', updateOnlineIndicator() );  // only on Firefox
function updateOnlineIndicator() {
  isOnline = navigator.onLine;
  send_status( isOnline ? "" : "off line")
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
  iphodGet( id, getDBsFor("iphod"), ( resp => {
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
    , canticles: "canticles"
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
      // get_config();
      // get_prayer_list();
      // sync();
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
  var db = dbs.pop();
  db.get(key)
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
  var now = moment().local().millisecond(1);
  var season = LitYear.toSeason(now);
  var iphodKey = season.iphodKey;
  iphodGet(iphodKey, getDBsFor("iphod"), (euresp => {
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
  var [key, db] = req.service === "eu" ? [sn.iphodKey, iphod] : [sn.mpepKey, DOdb]

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
  CurrentPage = request;
  switch (request) {
    case "currentOffice": 
     // redirect to correct office based on local time
      var mid = new moment().local().hour(11).minute(30).second(0)
        , ep = new moment().local().hour(15).minute(0).second(0)
        , cmp = new moment().local().hour(20).minute(0).second(0)
        ;
      var co = "";
      if ( now.isBefore(mid)) { co = "morning_prayer" }
      else if ( now.isBefore(ep) ) { co = "midday" }
      else if ( now.isBefore(cmp) ) { co = "evening_prayer" }
      else { co = "compline" }
      CurrentPage = co
      get_service(co, getDBsFor("service"));
      get_office_canticles(co, getDBsFor("canticles"));
      break;
    case "calendar":
      get_service("calendar", getDBsFor("service"));
      Calendar.get_calendar( now, [remoteIphod, iphod], [remoteLectionary, DOdb], receivedCalendar );
      break;
    case "prayerList":
      get_service(request, getDBsFor("service"))
      get_prayer_list();
      get_ops_categories()
      break;

    case "occasionalPrayers":
      get_service(request, getDBsFor("service"))
      get_ops_categories();
      break;

    case "canticles":
      get_service(request, getDBsFor("service"))
      request_all_canticles(getDBsFor("canticles"));
      break;

    case "angChurchChat":
      var win = window.open("https://discord.gg/ARF5Et5", "_blank")
      win.focus();
      break;

    default: 
      get_service(request, getDBsFor("service"));
      get_office_canticles(request, getDBsFor("canticles"));
  };
};


function get_config() {
  config.get('config')
  .then( resp => {
    Config = resp
    receivedConfig.send( Json.stringify( Config ))
  })
  .catch( err => {
    init_config();
  })
}

function init_config() {
  config.put( Config )
  .then( resp => {
    receivedConfig.send(JSON.stringify( Config) )
  })
  .catch( err => {
    console.log("Config DB error: ", err)
  })
}

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
  getOccasionalPrayers( "categories", getDBsFor("occasional_prayers"), ( resp => {
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
    , getDBsFor("occasional_prayers")
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
      , getDBsFor("occasional_prayers")
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
      return Calendar.get_calendar( 
        moment({"year": year - 1, "month": 11, "date": 31})
        , [remoteIphod, iphod]
        , [remoteLectionary, DOdb]
        , receivedCalendar 
        );
      break;
    case (month > 11): // january next year
      return Calendar.get_calendar( 
        moment({"year": year + 1, "month": 0, "date": 1})
        , [remoteIphod, iphod]
        , [remoteLectionary, DOdb]
        , receivedCalendar 
        );
      break;
    default: 
      return Calendar.get_calendar( 
        moment({"year": year, "month": month, "date": 1})
        , [remoteIphod, iphod]
        , [remoteLectionary, DOdb]
        , receivedCalendar 
        );
  }
})

app.ports.toggleButtons.subscribe(  function(request) {
  var [div, section_button] = request.map(  function(r) { return r.toLowerCase(); } );
  var section_id = section_button.replace("button", "id")
  $("#alternatives_" + div + " .alternative").hide(); // hide all the alternatives
  $("#" + section_id).show(); // show the selected alternative
})

app.ports.saveConfig.subscribe( thisConfig => {
  config.get('config')
  .then( resp => {
    resp.readingCycle = thisConfig.readingCycle;
    resp.psalmsCycle = thisConfig.psalmsCycle;
    resp.fontSize = thisConfig.fontSize;
    config.put( resp );
    // check Config to see what changed
    // then set Config to current DB config
    // and update the psalms or the readings as appropriate
    // only one will change at a time
    if (thisConfig.psalmsCycle != Config.psalmCycle) {
      Config = resp;
      insertPsalms(CurrentPage);
    }
    if (thisConfig.readingCycle != Config.readingCycle) {
      Config = resp;
      request_lessons( CurrentPage, moment() )
    }
  })
  .catch( err => {
    console.log("Config DB error on saving: ", err)
  })

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
  var topNow = window.scrollY;
  var offset = (70 - topNow); // 70 === offset from the header
  var goto = topNow;

  // if pageTops is empty...
  // 1. calculate the header offset
  // 2. get the location of all the page breaks
  // 3. subtract offset from top position of each page break
  // 4. add 0 to the front of the list of page breaks

  if (pageTops.length === 0) {
    pageTops = []
      .slice
      .call( document.getElementsByClassName('page'))
      .map( p => { 
        return parseInt( p.getBoundingClientRect().top - offset );
      } )

    pageTops.unshift(0)
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
  // parseInt below because x,y location may magically become a float
  window.scroll({top:goto, behavior: "smooth"})
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
  if ( !office ) return undefined;
  var mpepKey = LitYear.toSeason(today).mpepKey
  insertPsalms( office, "office" )
  insertLesson( "lesson1", office, mpepKey, "office" )
  if ( oneYearCycle() ) {
    insertLesson( "lesson2", office, mpepKey, "office" )
  }
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
  iphodGet(key, getDBsFor("iphod"), ( resp => {
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
  if ( skipSecondLesson(lesson) ) return undefined;
  getLectionary(mpepKey, getDBsFor("lectionary"), (resp => {
    // first db to check is at end of list
    var lessonKeys = twoYearCycle() 
      ? resp[ twoYearKey(office) ]
      : resp[office + lesson.substr(-1)];
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
        var bookName = BibleRef.bookTitle(resp[0].rows[0].doc.book)
        resp.forEach( function(r, i) {
          thisLesson[i] =
            { ref: keys[i].ref
            , style: keys[i].style
            , vss: r.rows.map( function(el) { return el.doc } )
            }
            
        })
        receivedLesson.send( 
          JSON.stringify(
            { lesson: lesson
            , content: thisLesson
            , spa_location: spa_location
            , bookName: bookName
            }
          ) 
        );
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
  iphodGet(key, getDBsFor("iphod"), ( resp => {
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
  iphodGet(key, getDBsFor("iphod"), ( resp => {
    var psalms = resp.ps
    var psalmRefs = BibleRef.dbKeys(psalms)
    allPsalms(psalmRefs);
  }))
}

function insertPsalms(office) {
  var mpep = false
    , now = moment()
    , mpep =
      { evening_prayer: "ep"
      , ep: "ep"
      , morning_prayer: "mp"
      , mp: "mp"
      }[office]
  if (!mpep) return undefined;
  Config.psalmsCycle === "SixtyDay"
    ? sixtyDayPsalmCycle(mpep, LitYear.sixtyDayKey(now))
    : thirtyDayPsalmCycle(mpep, LitYear.thirtyDayKey(now))
}

function thirtyDayPsalmCycle(office, key) {
  allPsalms( DailyPsalms.dailyPsalms[key][office] );
}

function sixtyDayPsalmCycle(office, key) {
  allPsalms( DailyPsalms.dailyPsalms60Day[key][office])
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

function request_canticle(dbs, key) {
  var db = dbs.pop();
  db.get(key)
  .then( resp => {
    resp.officeId = "invitatory";
    // the decoder is expecting a list, so put the resp in a list
    receivedNewCanticle.send( JSON.stringify({canticles: [resp]}) );
  })
  .catch(err => {
    if (dbs.length > 0) { request_canticle(dbs, key) }
    else { console.log("Error getting Canticle" + err) }
  })
}

function request_all_canticles(dbs) {
  var db = dbs.pop();
  db.allDocs( {include_docs: true})
  .then( resp => {
    if (resp.total_rows === 0) { request_all_canticles(dbs) }
    var cants = resp.rows.map( c => { return c.doc } )
    receivedAllCanticles.send(JSON.stringify({canticles: cants}));
  })
  .catch( err => {
    if (dbs.length > 0 ) { request_all_canticles(dbs) }
    else { console.log("Error getting Canticles: " + err) }
  })
}

function request_canticles(canticles, dbs) {
  var db = dbs.pop()
    , names = Object.values(canticles)
    , keys = Object.keys(canticles)
    ;
  db.allDocs( {include_docs: true, keys: names} )
  .then( resp => {
    if (resp.total_rows === 0) { request_canticles( names, dbs ) }
    var cants = resp.rows.map( (c, i) => { 
      c.doc.officeId = keys[i]
      return c.doc;
    })
    receivedOfficeCanticles.send( JSON.stringify( {canticles: cants } ))
  })
  .catch( err => {
    console.log("Error on DB: ", db)
    if ( dbs.length > 0 ) { request_canticles( canticles, dbs ) }
    else (console.log("Error getting office canticles: ", err))
  })
}

function get_office_canticles( office, dbs ) {
  // carry on if mp or ep
  if ( !(office === "morning_prayer" || office === "evening_prayer") ) { return; }
  var names = 
      [ get_invitatory(office)
      , get_canticle(office, "lesson1")
      , get_canticle(office, "lesson2")
      ]
    , cants = []
    , officeIds = [ "invitatory", "lesson1", "lesson2"]
  names.forEach( (el, i) => {
    if (el) { 
      cants[officeIds[i]] = el
    }
  })
  request_canticles( cants, dbs );
}


var invitatories = ["venite", "venite_long", "jubilate", "pascha_nostrum"];

app.ports.requestNextInvitatory.subscribe( inv => {
  var nextInv = invitatories[ (invitatories.indexOf(inv) + 1) % 4 ];
  request_canticle( getDBsFor("canticles"), nextInv)
})


function get_invitatory(office) {
  if (office != "morning_prayer") { return null; }
  var now = new moment()
    , season = LitYear.toSeason(now).season
    , day = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"][now.day()]
    //  daily alternate between Venite (short version) and Jubilate
    , invitatory = (now.dayOfYear() % 2) === 1 ? "venite" : "jubilate"
    , dayOfMonth = now.date() === 19
    ;

  // during Eastertide, Pascha Nostrum only
  if (season.includes("easter")) { return "pascha_nostrum"}

  //  on the 19th of th month (paslm 95 day), do not use venite 
  if (now.date() === 19) { return "jubilate" }

  //  during Lent, Venite (long version) only
  if (season === "ashWednesday" || season === "lent") { 
    //  Sundays in lent: jubilate
    invitatory = day === "sun" ? "jubilate" : "venite_long" 
  }

  return invitatory;
}

function get_canticle(office, lesson) {
  if ( skipSecondLesson(lesson) ) return undefined;

  office = office === "morning_prayer" ? "mp" : "ep";
  lesson = lesson === "lesson1" ? office + "1" : office + "2";
  
  var now = new moment();
  var season = LitYear.toSeason(now).season;
  var day = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"][now.day()]; 
  var canticle = undefined;
  var key1 = lesson + "_" + season + "_" + day;
  var key2 = lesson + "_" + day;
  var canticles =
    { mp1_advent_sun: "surge_illuminare"
    , mp1_easter_sun: "domino"
    , mp1_easter_thu: "domino"
    , mp1_easter_fri: "domino"
    , mp1_easterWeek_fri: "te_deum"
    , mp1_lent_sun: "kyrie_pantokrator"
    , mp1_lent_wed: "kyrie_pantokrator"
    , mp1_lent_fri: "kyrie_pantokrator"
    , mp1_ashWednesday_sun: "kyrie_pantokrator"
    , mp1_ashWednesday_wed: "kyrie_pantokrator"
    , mp1_ashWednesday_fri: "kyrie_pantokrator"
    , mp2_advent_sun: "benedictus"
    , mp2_advent_thu: "magna_et_mirabilia"
    , mp2_lent_sun: "benedictus"
    , mp2_lent_fri: "benedictus"
    , mp2_ashWednesday_sun: "benedictus"
    , mp2_ashWednesday_fri: "benedictus"
    , mp2_ashWednesday_tue: "deus_misereatur"
    , mp2_lent_tue: "deus_misereatur"
    , mp2_lent_thu: "magna_et_mirabilia"
    , mp2_ashWednesday_thu: "magna_et_mirabilia"
    , mp1_sun: "benedictus"
    , mp1_mon: "ecce_deus"
    , mp1_tue: "benedictus_es_domine"
    , mp1_wed: "surge_illuminare"
    , mp1_thu: "deus_misereatur"
    , mp1_fri: "quaerite_dominum"
    , mp1_sat: "benedicite_omnia_opera_domini"
    , mp2_sun: "te_deum_laudamus"
    , mp2_mon: "magna_et_mirabilia"
    , mp2_tue: "dignus_es"
    , mp2_wed: "benedictus"
    , mp2_thu: "gloria_in_excelsis"
    , mp2_fri: "dignus_es"
    , mp2_sat: "magna_et_mirabilia"
    , ep1_sun: "magnificat"
    , ep1_mon: "magnificat"
    , ep1_tue: "magnificat"
    , ep1_wed: "magnificat"
    , ep1_thu: "magnificat"
    , ep1_fri: "magnificat"
    , ep1_sat: "magnificat"
    , ep2_sun: "nunc_dimittis"
    , ep2_mon: "nunc_dimittis"
    , ep2_tue: "nunc_dimittis"
    , ep2_wed: "nunc_dimittis"
    , ep2_thu: "nunc_dimittis"
    , ep2_fri: "nunc_dimittis"
    , ep2_sat: "nunc_dimittis"
    }
  return canticles[key1] ? canticles[key1] : canticles[key2];
}
