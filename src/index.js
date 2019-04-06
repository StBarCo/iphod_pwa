import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const app = Elm.Main.init({
  node: document.getElementById('root')
});

registerServiceWorker();
import "./css/normalize.css";
import "./css/bootstrap.min.css";
import appcss from "./main.css";
// 
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
var service = new Pouchdb('service')
var psalms = new Pouchdb('psalms')
var lectionary = new Pouchdb('lectionary')
var dbOpts = {live: true, retry: true}
  , remoteIphod =      "https://legereme.com/couchdb/iphod"
  , remoteService =    "https://legereme.com/couchdb/service"
  , remotePsalms =     "https://legereme.com/couchdb/psalms"
  , remoteLectionary = "https://legereme.com/couchdb/lectionary"
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

function sync() {
  iphod.replicate.to(remoteIphod, dbOpts, syncError);
  iphod.replicate.from(remoteIphod, dbOpts, syncError);
  service.replicate.to(remoteService, dbOpts, syncError);
  service.replicate.from(remoteService, dbOpts, syncError);
  psalms.replicate.to(remotePsalms, dbOpts, syncError);
  psalms.replicate.from(remotePsalms, dbOpts, syncError);
  lectionary.replicate.to(remoteLectionary, dbOpts, syncError);
  lectionary.replicate.from(remoteLectionary, dbOpts, syncError);
}

function syncError() {console.log("SYNC ERROR")};

sync();

function get_service(named) {
  // we might want to add offices other than acna
  var dbName = "acna_" + named;
  service.get(dbName).then(  function(resp) {
    var now = moment()
      , day = [ "Sunday", "Monday", "Tuesday"
              , "Wednesday", "Thursday", "Friday"
              , "Saturday"
              ][now.weekday()]
      , season = LitYear.toSeason(now)
      , serviceHeader = [day, season.week.toString(), season.year, season.season, named]
    ;
    app.ports.receivedOffice.send(serviceHeader.concat(resp.service))
  }).catch( function(err) {
    console.log("GET SERVICE ERROR: ", err);
  });
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
      else if ( now.isBefore(cmp) ) { get_service("morning_prayer")} // { get_service ("evening_prayer") }
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
  if ( ["morning_prayer", "evening_prayer", "eucharist"].includes(request) ) { 
    insertPsalms( request )
    insertLesson( "lesson1", request )
    insertLesson( "lesson2", request )
    insertGospel( request )
    insertCollect( request )
    insertProper( request )
  }
  // otherwise, don't do anything
})

function insertLesson(lesson, office) {
  // mpepmmdd - mpep0122
  var mpep = (office === "morning_prayer") ? "mp" : "ep"
    , mpepRef = "mpep" + moment().format("MMDD")
    ;
  lectionary.get(mpepRef)
    .then(  function(resp) {
      var thisReading = resp[mpep + lesson.substr(-1)]
        , refs = thisReading.map(  function(r)  { return r.read })
        , styles = thisReading.map( function(r) { return r.style})
        , keys = BibleRef.dbKeys(refs)
        , allPromises = []
        ;
      keys.forEach(  function(k) {
        allPromises.push( iphod.allDocs(
          { include_docs: true
          , startkey: k.from
          , endkey: k.to
          }
        ))
      });
      return Promise.all( allPromises )
        .then(  function(resp) {
          var $thisLesson = $("#" + lesson);
          resp.forEach( function(r, i) {
            var klazz = "lessonTitle " + styles[i]
              , newId = lesson + "_" + i
              , [prefix, suffix] = styles[i] == "req" ? ["", "</br>"] : ["[ ", "]</br>"]
              ;
            $thisLesson.append(
                "</br><div id='" + newId + "' >" 
              + prefix
              + BibleRef.lessonTitleFromKeys(keys[i].from, keys[i].to) 
              + "</div>");
            var $vss = $("#" + newId);
            r.rows.forEach(  function(row) {
              $thisLesson.append(row.doc.vss)
            })
            $thisLesson.append( suffix );
          })
        })
      })
    .catch(  function(err) { 
      console.log("FAILED GETTING MPEP REFS: ", err)
    })
}

function insertGospel(office) {
  console.log("INSERT GOSPEL: ", office);
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

function insertProper(office) {
  console.log("INSERT PROPER: ", office)
}

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
        resp.map( function(r,i) {
          r.from = psalmRefs[i][1]
          r.to = psalmRefs[i][2]
        })
        showPsalms(resp);
      })
      .catch(  function(err) {
        console.log("PROBLEM GETTING PSALMS: " + err);
      })
}



// ----

function showPsalms(pss) {
  // $("#psalms").waitUntilExists(function() { console.log("PSALMS EXISTS!!!")});
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

