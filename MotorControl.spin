{
  Proj:         MotorControl.spin
  Platform:     Parallax Project USB Board
  Rev:          2.0
  Author:       Mok ST Sonia
  Date:         19/11/2021
  Log:
        29/11/2021              rse1101 functional version (most prev codes are commented)
        18/11/2021              further adaptation
        14/11/2021              ported from EE6 asgnmnt for adaptation
        02/11/2021              fix varying motor vals
        01/11/2021              first version
}

CON
   'clk init
  {_clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _ConClkFreq             = ((_clkmode - xtal1) >> 6) + _xinfreq
  _ms001                  = _ConClkFreq / 1_000}

  'mtr pin declaration
  mtr1 = 10
  mtr2 = 11
  mtr3 = 12
  mtr4 = 13

  'mtr zero vals
  mtr1z = 1800
  mtr2z = 1800
  mtr3z = 1800
  mtr4z = 1800


  'vals for pause()
  '_ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  '_ms001 = _ConClkFreq / 1_000

VAR
  'long _ms001

  long cgMtr, corestk[128]
  long _ms001

OBJ
  Motors      : "Servo8Fast_vZ2.spin"
  'Term        : "FullDuplexSerial.spin"

{PUB main


  'debugging
  pause(3000)
  term.Start(31, 30, 0, 115200)
  term.Str(String(13, "term init"))
  pause(1000)
  mtrInstruct(1)
  term.Str(String(13, "mtr init"))


 {
  repeat
    cgMtr := cognew(mtrInstruct(commCmd), @core1stk)
    term.Str(String(13, "cog started"))
    Pause(10000)
    cogstop(cgMtr)
    term.Str(String(13, "cog stopped"))
    pause(5000)
 }}

PUB     start(mainMS, mtrCmd, mtrSpd)           ' start new cog(mtrCog) that exe cmds

  _ms001 := mainMS

  Stop     ' if mtrCG alr hv val, stops current cog b4 nxt cmd

  cgMtr := cognew(mtrInstruct(mtrCmd, mtrSpd), @corestk)

  return

PUB mtrInstruct(mtrCmd, mtrSpd)

    'term.Start(31, 30, 0, 115200)
    'term.Str(String(13, "mtr recieved instruction: "))
    'term.Dec(LONG[@commCmd])

    init  'init all mtr n pins

   repeat
     case LONG[mtrCmd]         'repeat (stops when cg is stopped)
       1:
         fwd(long[mtrSpd])
       2:
         reverse(long[mtrSpd])
       3:
         turnL(long[mtrSpd])
       4:
         turnR(long[mtrSpd])
       5:
         stopAllMtrs



 'Debug/customize spd
        {Motors.Set(mtr1, mtr1z)
        Motors.Set(mtr2, mtr2z)
        Motors.Set(mtr3, mtr3z)
        Motors.Set(mtr4, mtr4z)}


PUB Stop  'stop if cgMtr hv val other than 0

  if cgMtr > 0
    cogstop(cgMtr~)

  return

{PUB mtrDrv{(mvInst)} |  mvmnt[11], i, j
  mvmnt[0] := 1
  mvmnt[1] := 4
  mvmnt[2] := 1
  mvmnt[3] := 3
  mvmnt[4] := 1
  mvmnt[5] := 2
  mvmnt[6] := 4
  mvmnt[7] := 2
  mvmnt[8] := 3
  mvmnt[9] := 2
  mvmnt[10] := 0

  repeat i from 0 to 10
    pause(500)
    j := mvmnt[i]
    term.Str(String(13, "mtr recieved instruction"))
    case j 'mvInst
      0:
        stopAllMtrs
        term.Str(String(13, "Stop"))
      1:
        fwd
        term.Str(String(13, "fwd"))
      2:
        reverse
        term.Str(String(13, "rvs"))
      3:
        turnL
        term.Str(String(13, "L"))
      4:
        turnR
        term.Str(String(13, "R"))

'The abv code is potential copypasta debug}

PUB init

    Motors.Init                   'init the mtrs
    Motors.AddSlowPin(mtr1)       'AddSlowPin for each mtr pin
    Motors.AddSlowPin(mtr2)
    Motors.AddSlowPin(mtr3)
    Motors.AddSlowPin(mtr4)
    Motors.Start
    pause(500)

PUB set(mtr, spd)
  case mtr
    1:
      Motors.Set(mtr1, mtr1z + spd)                    'mtr zero spd + desired spd
    2:
      Motors.Set(mtr2, mtr2z + spd)
    3:
      Motors.Set(mtr3, mtr3z + spd)
    4:
      Motors.Set(mtr4, mtr4z + spd)

  return 1

PUB stopAllMtrs
  set(1, 0)                                             'since abv alr set
  set(2, 0)                                             'base pulse is zero spd
  set(3, 0)                                             'just put zero
  set(4, 0)
  pause(1000)


PUB fwd(i) '| i
    {repeat i from 0 to 300 step 15                      '5% step
      set(1, i)                                         'incremnts every repeat
      set(2, i)                                         'until reaches top spd
      set(3, i)
      set(4, i)
      pause(75)
    repeat i from 300 to 0 step 15
      set(1, i)                                         'same for decr spd
      set(2, i)
      set(3, i)
      set(4, i)
      pause(75)
   pause(1000)                                           'then stop for 1 s            }

      set(1, i)
      set(2, i)
      set(3, i)
      set(4, i)
      pause(75)


PUB reverse(i) '| i

    {repeat i from 0 to 300 step 15                      '5% step
      set(1, (-i))                                        'since is reverse
      set(2, (-i))                                        'val is -ve
      set(3, (-i))                                        'to make mtr
      set(4, (-i))                                        'go reverse dir
      pause(75)
    repeat i from 300 to 0 step 15
      set(1, (-i))
      set(2, (-i))
      set(3, (-i))
      set(4, (-i))
      pause(75)
  pause(1000)}

    set(1, -i)
    set(2, -i)
    set(3, -i)
    set(4, -i)
    pause(75)


PUB turnL(i) '| i

    {repeat i from 0 to 250 step 10                      '5% step
      set(1, i)
      set(2, (-i))                                       'make mtr 2 n 4 revolve opp dir
      set(3, i)                                         'vehicle turns on spot
      set(4, (-i))
      pause(30)
    repeat i from 250 to 0 step 10
      set(1, i)
      set(2, (-i))
      set(3, i)
      set(4, (-i))
      pause(30)
  pause(1000)}

      set(1, i)
      set(2, -i)
      set(3, i)
      set(4, -i)
      pause(75)

PUB turnR(i) '| i

    {repeat i from 0 to 250 step 10                      '5% step
      set(1, -i)
      set(2, i)                                         'same for other dir
      set(3, -i)                                        'instead for mtr 1 and 3
      set(4, i)
      pause(30)
    repeat i from 250 to 0 step 10
      set(1, -i)
      set(2, i)
      set(3, -i)
      set(4, i)
      pause(30)
  pause(1000)}

      set(1, -i)
      set(2, i)
      set(3, -i)
      set(4, i)
      pause(75)

PUB pause(ms) | t               'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return