@LAZYGLOBAL OFF.
LOCAL lib_rocket_utilities_lex IS LEX().
lib_rocket_utilities_lex:ADD("nextStageTime",TIME:SECONDS).

FUNCTION isp_calc {	//returns the average isp of all of the active engines on the ship
	LOCAL engineList IS LIST().
	LOCAL totalFlow IS 0.
	LOCAL totalThrust IS 0.
	LIST ENGINES IN engineList.
	FOR engine IN engineList {
		IF engine:IGNITION AND NOT engine:FLAMEOUT {
			SET totalFlow TO totalFlow + (engine:AVAILABLETHRUST / (engine:ISP * 9.80665)).
			SET totalThrust TO totalThrust + engine:AVAILABLETHRUST.
		}
	}
	IF totalThrust = 0 {
		RETURN 1.
	}
	RETURN (totalThrust / (totalFlow * 9.80665)).
}

FUNCTION stage_check {	//a check for if the rocket needs to stage
	PARAMETER enableStage IS TRUE, stageDelay IS 2.
	LOCAL needStage IS FALSE.
	IF enableStage AND STAGE:READY AND (lib_rocket_utilities_lex["nextStageTime"] < TIME:SECONDS) {
		IF MAXTHRUST = 0 {
			SET needStage TO TRUE.
		} ELSE {
			LOCAL engineList IS LIST().
			LIST ENGINES IN engineList.
			FOR engine IN engineList {
				IF engine:IGNITION AND engine:FLAMEOUT {
					SET needStage TO TRUE.
					BREAK.
				}
			}
		}
		IF needStage	{
			STAGE.
			STEERINGMANAGER:RESETPIDS().
			SET lib_rocket_utilities_lex["nextStageTime"] TO TIME:SECONDS + stageDelay.
		}
	}
	RETURN needStage.
}

FUNCTION drop_tanks {
	PARAMETER tankTag IS "dropTank".
	LOCAL tankList IS SHIP:PARTSTAGGED(tankTag).
	IF (tankList:LENGTH > 0) AND STAGE:READY AND lib_rocket_utilities_lex["nextStageTime"] < TIME:SECONDS {
		LOCAL drop IS FALSE.
		FOR tank IN tankList {
			FOR res IN tank:RESOURCES {
				IF res:AMOUNT < 0.01 {
					SET drop TO TRUE.
					BREAK.
				}
			}
		}
		IF drop {
			STAGE.
			SET lib_rocket_utilities_lex["nextStageTime"] TO TIME:SECONDS + 10.
		}
	}
	RETURN tankList:LENGTH > 0.
}

FUNCTION active_engine { // check for a active engine on ship
	LOCAL engineList IS LIST().
	LIST ENGINES IN engineList.
	LOCAL haveEngine IS FALSE.
	FOR engine IN engineList {
		IF engine:IGNITION AND NOT engine:FLAMEOUT {
			SET haveEngine TO TRUE.
			BREAK.
		}
	}
	CLEARSCREEN.
	IF NOT haveEngine {
		PRINT "No Active Engines Found.".
	} ELSE {
		PRINT "Active Engine Found.".
		WAIT 0.1.
	}
	RETURN haveEngine.
}

FUNCTION burn_duration {	//from isp and dv using current mass of the ship returns the amount of time needed for the provided DV
	PARAMETER ISPs, DV, wMass IS SHIP:MASS, sThrust IS SHIP:AVAILABLETHRUST.
	LOCAL dMass IS wMass / (CONSTANT:E^ (DV / (ISPs * 9.80665))).
	LOCAL flowRate IS sThrust / (ISPs * 9.80665).
	RETURN (wMass - dMass) / flowRate.
}

FUNCTION control_point { 
	PARAMETER pTag IS "controlPoint".
	LOCAL controlList IS SHIP:PARTSTAGGED(pTag).
	IF controlList:LENGTH > 0 { controlList[0]:CONTROLFROM(). }
}

FUNCTION not_warping {
	RETURN KUNIVERSE:TIMEWARP:RATE = 1 AND KUNIVERSE:TIMEWARP:ISSETTLED.
}

FUNCTION clear_all_nodes {
	IF HASNODE { PRINT "havenode". UNTIL NOT HASNODE { REMOVE NEXTNODE. PRINT "removed node". WAIT 0. }}
}