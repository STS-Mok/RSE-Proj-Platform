{
  Proj:         MyLiteKit1102.spin
  Platform:     Parallax Project USB Board
  Rev:          1.0
  Author:       Mok ST Sonia
  Date:         06/03/2022
  Log:
        25/03/2022              accomidate cortex cmd
        06/03/2022              fork as MyLiteKit1102.spin

        08/02/2022              intro 2 side US to prep for mecanum mvmt
        29/11/2021              RSE1101 functional version
        18/10/2021              edit vars, adapted
        17/11/2021              Instructed version
        14/11/2021              First version
}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _ConClkFreq             = ((_clkmode - xtal1) >> 6) + _xinfreq
        _ms001                  = _ConClkFreq / 1_000

        stop = $AA

VAR
  'snsr
  long mainToF1, mainToF2, mainUSFr, mainUSBk, sfUSL, sfUSR
  'comm recieve
  long rxDir, rxSpd
  'mtr send
  long mtrDir, mtrSpd

OBJ
  snsr          : "SensorMUXControl.spin"
  mtr           : "MecanumTest.spin"
  comm          : "Comm2Control.spin"
  'term          : "FullDuplexSerial.spin"                                                               'debug

PUB main '| dir {, mvmnt[11], i 'mvmnt[11], i is for debugging}

    'init objs

    'currently there is a hardware problem with snsr...
    'snsr.start(_ms001, @mainToF1, @mainToF2, @mainUSFr, @mainUSBk, @sfUSL, @sfUSR)
    mtr.start(_ms001, @mtrDir, @mtrSpd)
    comm.init(_ms001, @rxDir, @rxSpd)

    repeat
      'while (snsrFlag == 0)     'while snsr does not detect obj
        mtrDir := rxDir
        mtrSpd := rxSpd

VAR

'placeholder to differentiate sections

      'NEW - this is added within the repeat but outside case sw so it overrides other mvmt dirs (for now)
      'When implemented with mecanum in mind it should look similar to cases 1 and 2 when strafing
      {if(sfUSL<250 OR sfUSR<250)
        mtrCmd := 5
        pause(2000)

      case rx 'debug

        1:
          if(mainToF1>250 OR mainUSFr<250)               'incase bump into sth
            mtrCmd := 5                                 'rvs to make space
            pause(2000)
          else
            if(mainToF1<250 AND mainUSFr>250)            'resume if obsticle rmed
              mtrCmd := 1
              mtrSpd := 100
              pause(500)

        2:
          if(mainToF2>250 OR mainUSBk<250)
            mtrCmd := 5         'stop
            pause(2000)
          else
            if(mainToF2<250 AND mainUSBk>250)
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