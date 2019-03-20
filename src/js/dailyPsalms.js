var dailyPsalms = [ undefined // 0th day of month
  , { mp: [[1,1,999],  [2,1,999], [3,1,999], [4,1,999], [5,1,999]]
    , ep: [[6,1,999],  [7,1,999], [8,1,999]]} // 1
  , { mp: [[9,1,999],  [10,1,999], [11,1,999]]
    , ep: [[12,1,999], [13,1,999], [14,1,999]]} // 2
  , { mp: [[15,1,999], [16,1,999], [17,1,999]]
    , ep: [[18,1,999]]} // 3
  , { mp: [[19,1,999], [20,1,999], [21,1,999]]
    , ep: [[22,1,999], [23,1,999]]} // 4
  , { mp: [[24,1,999], [25,1,999], [26,1,999]]
    , ep: [[27,1,999], [28,1,999], [29,1,999]]} // 5
  , { mp: [[30,1,999], [31,1,999]]
    , ep: [[32,1,999], [33,1,999], [34,1,999]]} // 6
  , { mp: [[35,1,999], [36,1,999]]
    , ep: [[37,1,999]]} // 7
  , { mp: [[38,1,999], [39,1,999], [40,1,999]]
    , ep: [[41,1,999], [42,1,999], [43,1,999]]} // 8
  , { mp: [[44,1,999], [45,1,999], [46,1,999]]
    , ep: [[47,1,999], [48,1,999], [49,1,999]]} // 9
  , { mp: [[50,1,999], [51,1,999], [52,1,999]]
    , ep: [[53,1,999], [54,1,999], [55,1,999]]} // 10
  , { mp: [[56,1,999], [57,1,999], [58,1,999]]
    , ep: [[59,1,999], [60,1,999], [61,1,999]]} // 11
  , { mp: [[62,1,999], [63,1,999], [64,1,999]]
    , ep: [[65,1,999], [66,1,999], [67,1,999]]} // 12
  , { mp: [[68,1,999]]
    , ep: [[69,1,999], [70,1,999]]} // 13
  , { mp: [[71,1,999], [72,1,999]]
    , ep: [[73,1,999], [74,1,999]]} // 14
  , { mp: [[75,1,999], [76,1,999], [77,1,999]]
    , ep: [[78,1,999]]} // 15
  , { mp: [[79,1,999], [80,1,999], [81,1,999]]
    , ep: [[82,1,999], [83,1,999], [84,1,999], [85,1,999]]} // 16
  , { mp: [[86,1,999], [87,1,999], [88,1,999]]
    , ep: [[89,1,999]]} // 17
  , { mp: [[90,1,999], [91,1,999], [92,1,999]]
    , ep: [[93,1,999], [94,1,999]]} // 18
  , { mp: [[95,1,999], [96,1,999], [97,1,999]]
    , ep: [[98,1,999], [99,1,999], [100,1,999], [101,1,999]]} // 19
  , { mp: [[102,1,999], [103,1,999]]
    , ep: [[104,1,999]]} // 20
  , { mp: [[105,1,999]]
    , ep: [[106,1,999]]} // 21
  , { mp: [[107,1,999]]
    , ep: [[108,1,999], [109,1,999]]} // 22
  , { mp: [[110,1,999], [111,1,999], [112,1,999], [113,1,999]]
    , ep: [[114,1,999], [115,1,999]]} // 23
  , { mp: [[116,1,999], [117,1,999], [118,1,999]]
    , ep: [[119,1,32]]} // 24
  , { mp: [[119,33,72]]
    , ep: [[119,73,104]]} // 25
  , { mp: [[119,105,144]]
    , ep: [[119,145,176]]} // 26
  , { mp: [[120,1,999], [121,1,999], [122,1,999], [123,1,999], [124,1,999], [125,1,999]]
    , ep: [[126,1,999], [127,1,999], [128,1,999], [129,1,999], [130,1,999], [131,1,999]]} // 27
  , { mp: [[132,1,999], [133,1,999], [134,1,999], [135,1,999]]
    , ep: [[136,1,999], [137,1,999], [138,1,999]]} // 28
  , { mp: [[139,1,999], [140,1,999]]
    , ep: [[141,1,999], [142,1,999], [143,1,999]]} // 29
  , { mp: [[144,1,999], [145,1,999], [146,1,999]]
    , ep: [[147,1,999], [148,1,999], [149,1,999], [150,1,999]]} // 30
  , { mp: [[120,1,999], [121,1,999], [122,1,999], [123,1,999], [124,1,999], [125,1,999],[126,1,999], [127,1,999]]
    , ep: [[127,1,999], [128,1,999], [129,1,999], [130,1,999], [131,1,999],[132,1,999], [133,1,999], [134,1,999]]} // 31
]

function stringified(n) {
  return  { mp: dailyPsalms[n].mp.map( function(p) { return innerStringify(p) } )
          , ep: dailyPsalms[n].ep.map( function(p) { return innerStringify(p) } )
          }
}

function innerStringify( [pss, startAt, endAt] ) {
  if (endAt === 999) {
    if (startAt === 1) return "Psalm " + pss;
    endAt = "end";
  }
  return "Psalm " + pss + ": " + startAt + " - " + endAt;
}


module.exports =
  { dailyPsalms: dailyPsalms
  , stringified: stringified
  }