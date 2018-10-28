/me LOG "IF NOT SHIP:UNPACKED AND SHIP:LOADED { WAIT UNTIL SHIP:UNPACKED AND SHIP:LOADED. WAIT 1. } GLOBAL c IS addons:camera:flightcamera. core:doevent(“open terminal”)." TO PATH("1:/startup.ks"). SET CORE:BOOTFILENAME TO "startup".

IF HASNODE{UNTIL NOT HASNODE{REMOVE NEXTNODE. WAIT 0.}}
ADD NODE(TIME:SECONDS + 60,0,0,0).
UNTIL NEXTNODE:ORBIT:TRANSITION = "ENCOUNTER" { SET NEXTNODE:PROGRADE TO NEXTNODE:PROGRADE - 1. WAIT 0. }


ADD NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,SQRT(BODY:MU / SHIP:ORBIT:PERIAPSIS) - VELOCITYAT(SHIP,TIME:SECONDS + ETA:PERIAPSIS):MAG).

ADD NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,SQRT(BODY:MU / SHIP:ORBIT:APOAPSIS) - VELOCITYAT(SHIP,TIME:SECONDS + ETA:APOAPSIS):MAG).



ADD NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,-10).

PRINT "relative Velocity: " + ROUND((VELOCITYAT(SHIP,14400 + TIME:SECONDS) - VELOCITYAT(TARGET,14400 + TIME:SECONDS)):MAG,2).

LOCK rt_vel TO SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT. LOCK STEERING TO -rt_vel.

LOCK THROTTLE TO (rt_vel):MAG / (SHIP:AVAILABLETHRUST / SHIP:MASS).
WHEN rt_vel:MAG < 0.01 THEN {LOCK THROTTLE TO 0.}

KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + NEXTNODE:ETA - 120).

LOCK THROTTLE TO NEXTNODE:DELTAV:MAG / (SHIP:AVAILABLETHRUST / SHIP:MASS). WHEN NEXTNODE:DELTAV:MAG < 0.1 THEN { LOCK THROTTLE TO 0. }

LOCK STEERING TO SHIP:SRFRETROGRADE.
WHEN SHIP:VERTICALSPEED > -10 THEN {LOCK STEERING TO -SHIP:VELOCITY:SURFACE  + SHIP:UP:FOREVECTOR * 10.}
LOCK localGrav TO BODY:MU / (BODY:POSITION - SHIP:POSITION):SQRMAGNITUDE.
LOCK shipAcc TO (SHIP:AVAILABLETHRUST / SHIP:MASS) * .95 - localGrav.
SET offSet TO 10.
LOCK vSpeedTar TO shipAcc * sqrt(2 * ABS(ALT:RADAR - offSet) / shipAcc) + 0.5.
LOCK minThrot TO (localGrav / shipAcc).
LOCK THROTTLE TO SHIP:VELOCITY:SURFACE:MAG - vSpeedTar + minThrot.
WHEN VANG(SHIP:VELOCITY:SURFACE,SHIP:UP:VECTOR) > 179 THEN { LOCK THROTTLE TO -SHIP:VERTICALSPEED - vSpeedTar + minThrot. }
WAIT UNTIL FALSE.

LIST ENGINES IN engList. PRINT "DV aprox: "  ROUND(engList[0]:ISP * 9.80665 * LN(SHIP:MASS / SHIP:DRYMASS)).

/me SET burn_duration TO { PARAMETER ISPs, DV IS NEXTNODE:DELTAV:MAG, wMass IS SHIP:MASS, sThrust IS SHIP:AVAILABLETHRUST. LOCAL dMass IS wMass / (CONSTANT:E^ (DV / (ISPs * 9.80665))). LOCAL flowRate IS sThrust / (ISPs * 9.80665). RETURN (wMass - dMass) / flowRate. }.

LIST ENGINES IN engList. PRINT "aprox burn time: " ROUND((SHIP:MASS - (SHIP:MASS / (CONSTANT:E^ (NEXTNODE:DELTAV:MAG / (engList[0]:ISP * 9.80665))))) / (SHIP:AVAILABLETHRUST. / (engList[0]:ISP * 9.80665)),2).}



IF HASNODE{UNTIL NOT HASNODE{REMOVE NEXTNODE. WAIT 0.}}
ADD NODE(TIME:SECONDS + 600,0,0,0).
UNTIL NEXTNODE:ORBIT:NEXTPATCH:PERIAPSIS < 30000 AND NEXTNODE:ORBIT:NEXTPATCH:PERIAPSIS > 25000{ SET NEXTNODE:ETA TO NEXTNODE:ETA + 1. WAIT 0. }
UNTIL NEXTNODE:ORBIT:PERIAPSIS < 40000 { SET NEXTNODE:PROGRADE TO NEXTNODE:PROGRADE - 1. WAIT 0. }
PRINT NEXTNODE:ORBIT:PERIAPSIS.

LOCK THROTTLE TO 1. WHEN SHIP:ORBIT:NEXTPATCH:PERIAPSIS < 30000 THEN { LOCK THROTTLE TO 0. PRINT "PE below 30km".}

SET warp TO 5. WHEN SHIP:ALTITUDE < 500000000 THEN {SET warp TO 0. }

/me SET fairing TO SHIP:PARTSDUBBEDPATTERN("shell")[0]:GETMODULE("moduleproceduralfairing"):DOEVENT("deploy"). PRINT fairing[0]:GETMODULE("moduleproceduralfairing"):ALLEVENTS.
fairing[0].


/me GLOBAL rgb_gen IS { PARAMETER maxVal,val. LOCAL result IS MOD(val,maxVal) / maxVal * 3. LOCAL re IS MAX(MIN(1 - result,1),0). LOCAL gr IS 0. LOCAL bl IS MAX(MIN(result,1),0). IF result > 1 { SET bl TO MAX(MIN(2 - result,1),0). SET gr TO MAX(MIN(result - 1,1),0). IF result > 2 { SET gr TO MAX(MIN(3 - result,1),0). SET re TO MAX(MIN(result - 2,1),0). } } RETURN RGBA(re,gr,bl,2). }.
GLOBAL colorCount IS 0. GLOBAL hlIndex IS 0. GLOBAL nugHLlist IS LIST(). FOR par IN SHIP:PARTS { nugHLlist:ADD(HIGHLIGHT(par,rgb_gen:CALL(768,0))).} FOR hl IN nugHLlist {SET hl:ENABLED TO TRUE.} GLOBAL nugLive IS TRUE.
WHEN TRUE THEN { SET colorCount TO MOD(colorCount + 1,768). SET hlIndex TO MOD(hlIndex + 1,nugHLlist:LENGTH). SET nugHLlist[hlIndex]:COLOR TO rgb_gen:CALL(768,colorCount). IF nugLive {PRESERVE.} ELSE { FOR hl IN nugHLlist {SET hl:ENABLED TO FALSE. }}}
