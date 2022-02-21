{
  Proj:         MyLiteKit.spin
  Platform:     Parallax Project USB Board
  Rev:          2.0
  Author:       -
  Date:         19/11/2021
  Log:
        29/11/2021              rse1101 functional version (most prev codes are commented out)
        18/10/2021              edit vars, adapted
        17/11/2021              Instructed version
        14/11/2021              First version
}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _ConClkFreq             = ((_clkmode - xtal1) >> 6) + _xinfreq
        _ms001                  = _ConClkFreq / 1_000

        commSt  = $7A
        commFwd = $01
        commRvs = $02
        commL   = $03
        commR   = $04
        commStopAll = $AA

VAR
  long mainToF1, mainToF2, mainUS1, mainUS2
  long rx
  long mtrCmd, mtrSpd

OBJ
  snsr          : "SensorControl.spin"
  mtr           : "MotorControl.spin"
  comm          : "commControl.spin"
  'term          : "FullDuplexSerial.spin"                                                               'debug

PUB main '| dir {, mvmnt[11], i 'mvmnt[11], i is for debugging}

    'init objs

    snsr.start(_ms001, @mainToF1, @mainToF2, @mainUS1, @mainUS2)
    mtr.start(_ms001, @mtrCmd, @mtrSpd)
    comm.init(_ms001, @rx)

    repeat
      case rx 'debug

        1:
          if(mainToF1>250 OR mainUS1<250)               'incase bump into sth
            mtrCmd := 5                                 'rvs to make space
            pause(500)
          else
            if(mainToF1<250 AND mainUS1>250)            'resume if obsticle rmed
              mtrCmd := 1
              mtrSpd := 100
              pause(500)

        2:
          if(mainToF2>250 OR mainUS2<250)
            mtrCmd := 5         'stop
            pause(500)
          else
            if(mainToF2<250 AND mainUS2>250)
              mtrCmd := 2
              mtrSpd := 100
              pause(500)         'these actions are to go back
        3:
          mtrCmd := 3           'left
          mtrSpd := 100

        4:
          mtrCmd := 4           'right
          mtrSpd := 100

        5:
          mtrCmd := 5           'stop all mtrs}

    {pause(5000)
    term.Start(31, 30, 0, 115200)
    pause(3000)
    term.Str(String(13, "term init"))
    snsr.init(_ms001, @snsrFlag)
    term.Str(String(13, "snsr init"))
    pause(500)
    comm.init(_ms001, @commCmd)
    term.Str(String(13, "comm init"))
    pause(500)
    mtr.init(_ms001, @commCmd)
    term.Str(String(13, "mtr init"))
    pause(500)}

    {repeat
      repeat while(snsrFlag == 0)                   'while there is no obsticles
        mtr.mtrInstruct(commCmd)
        'repeat i from 0 to 10
          'mtrInstruct(i)
      'mtr.stopAllMtrs              '
      pause(5000)              'stop 5s for manual hazard evasion}


{PUB mtrInstruct(mvmntCode)

    'repeat while(i not 1)
    cgMtr := cognew(mtrInstruct(mvmntCode), @core2stk)
    term.Str(String(13, "mtr recieved instruction"))

    case mvmntCode
      0:
        mtr.stopAllMtrs
      1:
        mtr.fwd
      2:
        mtr.reverse
      3:
        mtr.turnL
      4:
        mtr.turnR}

PUB pause(ms) | t                                                                                       'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)