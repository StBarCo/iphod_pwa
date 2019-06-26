import './js/scripture.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

window.app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: [window.innerHeight, window.innerWidth]
});

registerServiceWorker();

import $ from 'jquery';
// 
// // var popper = require('popper.js');
// // var bootstrap = require('bootstrap');
var moment = require('moment');
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
var dbOpts = {}
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

//function sync() {
//  // iphod.replicate.to(remoteIphod, dbOpts, syncError);
//  iphod.replicate.from(remoteIphodURL, dbOpts, syncError);
//  // service.replicate.to(remoteService, dbOpts, syncError);
//  service.replicate.from(remoteServiceURL, dbOpts, syncError);
//  // psalms.replicate.to(remotePsalms, dbOpts, syncError);
//  psalms.replicate.from(remotePsalmsURL, dbOpts, syncError);
//  // lectionary.replicate.to(remoteLectionary, dbOpts, syncError);
//  lectionary.replicate.from(remoteLectionaryURL, dbOpts, syncError);
//}

function syncError() {};

// NEED TO ADD AN EVENT LISTENER TO CHECK FOR CONNECTIVITY
var isOnline = navigator.onLine; 
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
  , today = now.format("dddd, MMMM Do YYYY")
  , day = [ "Sunday", "Monday", "Tuesday"
          , "Wednesday", "Thursday", "Friday"
          , "Saturday"
          ][now.weekday()]
  , season = LitYear.toSeason(now)
  , iphodKey = season.season + season.week + season.year
  ;
  iphod.get(iphodKey).then( function(euResp){
    var serviceHeader = [
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
  })
}

function get_service(named) {
  // have to map offices here
  // we might want to add offices other than acna
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
    }[named];
  service.get(dbName).then(  function(resp) {
    service_response(named, resp)
    if ( updateOnlineIndicator() ) {
      app.ports.onlineStatus.send( "syncing");
      service.replicate.from(remoteServiceURL, dbOpts, syncError)
      .on("complete", function(info) {
        updateOnlineIndicator()
      })
      .on("paused", function(err) {
        updateOnlineIndicator();
      })
      .on("active", function(info) {
        app.port.onlineStatus.send("syncing")
      })
      .on("error", function(err) {
        app.ports.onlineStatus.send("sync error")
      })
    }
    ;

  })
  .catch( function(err) {
    if ( updateOnlineIndicator() ) {
      get_service_from_master(dbName);
    }
    else { console.log("GET SERVICE ERROR: ", err); }
  })
  }

function get_service_from_master(serv) {
  remoteService.get(serv).then (function(resp) {
    service_response(serv, resp)
  })
  .catch( function(err) {
    console.log("FAILED TO GET " + serv + " FROM MASTER: ", err)
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
    insertGospel( request )
    insertCollect( request )
    insertProper( request )
  }
  // otherwise, don't do anything
}

function insertLesson(lesson, office) {
  // mpepmmdd - mpep0122
  var mpep = (office === "morning_prayer") ? "mp" : "ep"
    , mpepRef = "mpep" + moment().format("MMDD")
    ;
  lectionary.get(mpepRef)
    .then(  function(resp) { lesson_response(mpep, lesson, resp) })
    .catch(  function(err) { 
      console.log("FAILED GETTING MPEP REFS: ", err)
    })
}

function lesson_response(mpep, lesson, resp) {
  var thisReading = resp[mpep + lesson.substr(-1)]
  , refs = thisReading.map(  function(r)  { return r.read })
  , styles = thisReading.map( function(r) { return r.style})
  , keys = BibleRef.dbKeys(refs)
  //, refTitles = keys.map( function(r) { return BibleRef.lessonTitleFromKeys(r) } )
  , allPromises = []
  ;
  keys.forEach( function(k) {
    allPromises.push( iphod.allDocs(
      { include_docs: true
      , startkey: k.from
      , endkey: k.to
      }
    ))
  });
  return Promise.all( allPromises )
    .then(  function(resp) {
      var thisLesson = [];
      resp.forEach( function(r, i) {
        thisLesson[i] =
          { ref: refs[i]
          , style: styles[i]
          , vss: r.rows.map( function(el) { return el.doc } )
          }
      })
      app.ports.receivedLesson.send( JSON.stringify({lesson: lesson, content: thisLesson}) );
      iphod.replicate.from(remoteIphodURL, dbOpts, syncError)
      .on("complete", function(info) { updateOnlineIndicator() })
      .on("paused", function(err) { updateOnlineIndicator() })
      .on("active", function(info) { app.port.onlineStatus.send("syncing") })
      .on("error", function(err) { app.ports.onlineStatus.send("sync error") })
      psalms.replicate.from(remotePsalmsURL, dbOpts, syncError)
      .on("complete", function(info) { updateOnlineIndicator() })
      .on("paused", function(err) { updateOnlineIndicator() })
      .on("active", function(info) { app.port.onlineStatus.send("syncing") })
      .on("error", function(err) { app.ports.onlineStatus.send("sync error") })
      lectionary.replicate.from(remoteLectionaryURL, dbOpts, syncError)
      .on("complete", function(info) { updateOnlineIndicator() })
      .on("paused", function(err) { updateOnlineIndicator() })
      .on("active", function(info) { app.port.onlineStatus.send("syncing") })
      .on("error", function(err) { app.ports.onlineStatus.send("sync error") })
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

function insertProper(office) {}

function insertPsalms(office) {
  var now = moment()
    , mpep = (office === "morning_prayer") ? "mp" : "ep"
    , dayOfMonth = now.date()
    , psalmRefs = DailyPsalms.dailyPsalms[dayOfMonth][mpep]
    , thesePsalms = psalmRefs.map(  function(p) { return "acna" + p[0] } )
    , allPromises = []
    ;
    thesePsalms.forEach(  function(p) {
      allPromises.push( psalms.get(p) );
    })
    Promise.all( allPromises )
      .then(  function(resp) {
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

      })
      .catch(  function(err) {
        console.log("PROBLEM GETTING PSALMS: " + err);
      })
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

