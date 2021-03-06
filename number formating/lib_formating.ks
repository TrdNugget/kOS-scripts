@LAZYGLOBAL OFF.

LOCAL lib_formating_lex IS LEX().

{
	LOCAL hoursInDay IS KUNIVERSE:HOURSPERDAY.
	LOCAL daysInYear IS 365.
	IF hoursInDay = 6 { SET daysInYear TO 426. }
	lib_formating_lex:ADD("timeModList",LIST(60,60,hoursInDay,daysInYear)).
}

LOCAL FUNCTION time_converter {
	PARAMETER timeValue,places.
	LOCAL returnList IS LIST().
	LOCAL localTime IS timeValue.

	LOCAL place IS 1.
	FOR modValue IN lib_formating_lex["timeModList"] {
		LOCAL returnValue IS MOD(localTime,modValue).
		returnList:ADD(returnValue).

		SET localTime TO FLOOR(localTime / modValue).
		IF localTime = 0 { BREAK. }
		SET place TO place + 1.
		IF place = places { BREAK. }
	}
	IF localTime > 0 { returnList:ADD(localTime). }
	RETURN returnList.
}

lib_formating_lex:ADD("leading0List",LIST(2,2,2,3,3)).
LOCAL FUNCTION time_string {
	PARAMETER timeSec, fixedPlaces, stringList, roundingList, tMinus.
	LOCAL places IS stringList:LENGTH.
	LOCAL timeList IS time_converter(ABS(timeSec),places).
	LOCAL returnString IS "".

	LOCAL maxLength IS MIN(timeList:LENGTH, places).

	IF fixedPlaces > 0 {
		UNTIL timeList:LENGTH >= fixedPlaces {
			timeList:ADD(0).
			SET maxLength TO MIN(timeList:LENGTH, places).
		}
	} ELSE {
		SET fixedPlaces TO maxLength.
	}

	FROM {LOCAL i IS maxLength - (fixedPlaces).} UNTIL i >= maxLength STEP {SET i TO i + 1.} DO {
		SET returnString TO padding(timeList[i],lib_formating_lex["leading0List"][i],roundingList[i],FALSE) + stringList[i] + returnString.
	}

	IF timeSec < 0 {
		IF tMinus {
			RETURN returnString:INSERT(0,"T- ").
		} ELSE {
			RETURN returnString:INSERT(0,"-").
		}
	} ELSE {
		IF tMinus {
			RETURN returnString:INSERT(0,"T+ ").
		} ELSE {
			RETURN returnString:INSERT(0," ").
		}
	}
}

//adding list of format types
lib_formating_lex:ADD("timeFormats",LIST()).
lib_formating_lex["timeFormats"]:ADD(LIST(0,LIST("s","m ","h ","d ","y "))).
lib_formating_lex["timeFormats"]:ADD(LIST(0,LIST("",":",":"," Days, "," Years, "))).
lib_formating_lex["timeFormats"]:ADD(LIST(0,LIST(" Seconds"," Minutes, "," Hours, "," Days, "," Years, "))).
lib_formating_lex["timeFormats"]:ADD(LIST(0,LIST("",":",":"))).
lib_formating_lex["timeFormats"]:ADD(LIST(3,lib_formating_lex["timeFormats"][3][1])).
lib_formating_lex["timeFormats"]:ADD(LIST(2,LIST("s  ","m  ","h  ","d ","y "))).
lib_formating_lex["timeFormats"]:ADD(LIST(2,LIST(" Seconds  "," Minutes  "," Hours    "," Days    "," Years   "))).

FUNCTION time_formating {
	PARAMETER timeSec,	//the time in seconds to format
	formatType IS 0,		//what type of format
	rounding IS 0,		//what rounding on the seconds
	tMinus IS FALSE.		//had a T- or T+ at the start of the formated time
	LOCAL roundingList IS LIST(MIN(rounding,2),0,0,0,0).
	LOCAL formatData IS lib_formating_lex["timeFormats"][formatType].
	RETURN time_string(timeSec,formatData[0],formatData[1],roundingList,tMinus).
}

lib_formating_lex:ADD("siPrefixList",LIST(" y"," z"," a"," f"," p"," n"," μ"," m","  "," k"," M"," G"," T"," P"," E"," Z"," Y")).
FUNCTION si_formating {
	PARAMETER num,//number to format,
	unit IS "".//unit of number
	IF num = 0 {
		RETURN padding(num,1,3) + "  " + unit.
	} ELSE {
		//SET num TO sig_dig_rounding(num,4).
		LOCAL powerOfTen IS MAX(MIN(FLOOR(LOG10(ABS(num))),26),-24).
		LOCAL SIfactor IS FLOOR(powerOfTen / 3).
		LOCAL trailingLength IS 3 - (powerOfTen - SIfactor * 3).
		LOCAL prefix IS lib_formating_lex["siPrefixList"][SIfactor + 8].
		//RETURN padding(adv_floor(num/1000^SIfactor,trailingLength),1,trailingLength,TRUE,TRUE) + prefix + unit.
		RETURN padding(num/1000^SIfactor,1,trailingLength,TRUE,TRUE) + prefix + unit.
	}
}

FUNCTION padding {
	PARAMETER num,	//number to pad
	leadingLenght,	//min length to the left of the decimal point
	trailingLength,	// length to the right of the decimal point
	positiveLeadingSpace IS TRUE,//if when positive should there be a space before the returned string
	useFloor IS FALSE.
	LOCAL returnString IS "".
	//LOCAL returnString IS ABS(ROUND(num,trailingLength)):TOSTRING.
	IF useFloor {
		SET returnString TO ABS(adv_floor(num,trailingLength)):TOSTRING.
	} ELSE {
		SET returnString TO ABS(ROUND(num,trailingLength)):TOSTRING.
	}

	IF trailingLength > 0 {
		IF NOT returnString:CONTAINS(".") {
			SET returnString TO returnString + ".0".
		}
		UNTIL returnString:SPLIT(".")[1]:LENGTH >= trailingLength { SET returnString TO returnString + "0". }
		UNTIL returnString:SPLIT(".")[0]:LENGTH >= leadingLenght { SET returnString TO "0" + returnString. }
	} ELSE {
		UNTIL returnString:LENGTH >= leadingLenght { SET returnString TO "0" + returnString. }
	}

	IF num < 0 {
		RETURN "-" + returnString.
	} ELSE {
		IF positiveLeadingSpace {
			RETURN " " + returnString.
		} ELSE {
			RETURN returnString.
		}
	}
}

LOCAL FUNCTION sig_dig_rounding {
	PARAMETER num,sigDig.
	LOCAL multiplier IS 10^(sigDig - FLOOR(LOG10(ABS(num))) - 1).
	RETURN ROUND(FLOOR(num*multiplier*10)/10,0)/multiplier.
}

LOCAL FUNCTION adv_floor {
	PARAMETER num,dp.
	LOCAL multiplier IS 10^dp.
	RETURN FLOOR(num * multiplier)/multiplier.
}