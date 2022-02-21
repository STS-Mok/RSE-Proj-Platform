{
  Proj:         SensorControl.spin
  Platform:     Parallax Project USB Board
  Rev:          2.1
  Author:       Mok ST Sonia
  Date:         19/11/2021
  Log:
        29/11/2021              rse1101 functional version (most prev codes are commented)
        18/11/2021              Fixed typos on variables
        17/11/2021              Instructed version
        14/11/2021              First version
}


CON
        {_clkmode                = xtal1 + pll16x                                                        'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq                = 5_000_000
        _conClkFreq             = ((_clkmode - xtal1) >> 6) * _xinfreq
        _ms001                  = _conClkFreq / 1_000}
        {Pin decl}

        'Ultra1 (frt) - I2C bus 1
        us1SCL    = 4                                   'SCL = clk
        us1SDA    = 5                                   'SDA = data
        'ultra2 (bck) - bus 2
        us2SCL    = 6
        us2SDA    = 7

        'tof1   (frt) - bus 3
        tof1SCL   = 0
        tof1SDA   = 1
        tof1RST   = 14                                  'RST = reset, used in quite a lot of situations
        'tof2   (bck) - bus 4
        tof2SCL   = 2
        tof2SDA   = 3
        tof2RST   = 15

        tofAdd    = $29

VAR
  long cgSnsr, corestk[128]
  long _ms001

OBJ
  term      : "FullDuplexSerial.spin"                                                                   'debug ter
  us1       : "EE-7_Ultra_v2.spin"                                                                      'updated ver of us lib
  us2       : "EE-7_Ultra_v2.spin"
  tof1      : "EE-7_ToF.spin"
  tof2      : "EE-7_ToF.spin"                                                                           'as abv


{PUB main
  init(_ms001,0)
  'debugging}

PUB start(mainMS, mainToF1, mainToF2, mainUS1, mainUS2)     'start snsr reading cog

  _ms001 := mainMS

  Stop

  cgSnsr := cognew(snsrOp(mainToF1, mainToF2, mainUS1, mainUS2), @corestk)

PUB Stop  'stop if cgSnsr hv val other than 0

  if cgSnsr > 0
    cogstop(cgSnsr~)

  return

PUB snsrOp(mainToF1, mainToF2, mainUS1, mainUS2)              '(snsrFlag)  |  USval, ToFval

  'term.Start(31, 30, 0, 115200)
  {pause(5000)
  term.Str(String(13, "term init"))
  {init
  pause(3000)
  term.Str(String(13, "snsr init"))}
  pause(3000)}

  init

  repeat
    long[mainUS1]               := us1.readSensor               'obtain readings
    long[mainUS2]               := us2.readSensor
    long[mainToF1]              := tof1.GetSingleRange(tofAdd)
    long[mainToF2]              := tof2.GetSingleRange(tofAdd)
    Pause(100)

  {repeat
    USval := readUS
    term.Str(String(13, "Ultrasonic reading: "))
    term.Dec(USval)
    pause(500)
    ToFval := readToF
    term.Str(String(13, "ToF reading: "))
    term.Dec(ToFval)
    long[@snsrFlag] := snsrVal(USval, ToFval)
    pause(1000)}

PUB init'(mainMS, snsrFlag)

  term.Start(31, 30, 0, 115200)                                                                         'debug ter
  '_ms001 := mainMS
  pause(2000)                                                                                           'for human delay

  us1.init(us1SCL, us1SDA)
  pause(500)
  us2.init(us2SCL, us2SDA)
  pause(500)

  tof1.init(tof1SCL, tof1SDA, tof1RST)                                                                   'add instances
  tof1.ChipReset(1)                                                                                   'Last state ON
  Pause(1000)'
  tof1.FreshReset(tofAdd)                                                                             'Hardware cal
  tof1.MandatoryLoad(tofAdd)
  tof1.RecommendedLoad(tofAdd)
  tof1.FreshReset(tofAdd)                                                                             'Reset again

  pause(500)

  tof2.init(tof2SCL, tof2SDA, tof2RST)                                                                   'add instances
  tof2.ChipReset(1)                                                                                   'Last state ON
  Pause(1000)'
  tof2.FreshReset(tofAdd)                                                                             'Hardware cal
  tof2.MandatoryLoad(tofAdd)
  tof2.RecommendedLoad(tofAdd)
  tof2.FreshReset(tofAdd)                                                                             'Reset again


{PUB snsrCog  |  blk, hed, fBlk, fHed

    snsr.initSnsr
    term.Str(String(13, "snsr init"))

    cg1 := cognew(snsrVal, @core1stk)
    term.Str(String(13, "cg1: avoidObst init"))}


{PUB snsrVal(USval, ToFval)  |  blk, hed, fBlk, fHed                            'this used to be a decision making component
                                                                                'now is within main
    repeat
      blk := readUS
      if(blk <= 150)
        fBlk := 1
        term.Str(String(13, "obsticle detected"))
      else
        fblk := 0
      pause(50)
      hed := readToF
      if(hed >= 150)
        fHed := 1
        term.Str(String(13, "cliff detected"))
      else
        fHed := 0

      if((fBlk == 1) or (fHed == 1))
        term.Str(String(13, "warning flagged, mtr halted"))
        return 1
      else
        return 0}



{PUB readUS | USval1, USval2, tmpVal1, tmpVal2           'this is to obtain reading for us
                                                        'and rtn the most dangerous val
    USval1 := us1.readSensor                                                                            '1st obj
    USval2 := us2.readSensor                                                                            '2nd

    'debug
    term.Str(String(13, "Ultrasonic 1 reading: "))
    term.Dec(USval1)
    term.Str(String(13, "Ultrasonic 2 reading: "))
    term.Dec(USval2)
    pause(1000)

    ifnot(USval1 == 0)
      tmpVal1 := USval1
    ifnot(USval2 == 0)
      tmpVal2 := USval2

    if(tmpVal1<tmpVal2)
      return tmpVal1
    else
      return tmpVal2}

{PUB readToF | ToFval1, ToFval2                             'obtain reading for ToF

    ToFval1 := tof1.getSingleRange(tofAdd)
    ToFval2 := tof2.getSingleRange(tofAdd)

    'debug
    term.Str(String(13, "ToF 1 reading: "))
    term.Dec(ToFval1)
    term.Str(String(13, "ToF 2 reading: "))
    term.Dec(ToFval2)
    pause(1000)

    if(ToFval1>ToFval2)
      return ToFval1
    else
      return ToFval2}

PUB pause(ms) | t                                                                                       'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return