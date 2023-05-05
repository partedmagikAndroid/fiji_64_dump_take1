#!/system/bin/sh
#!/bin/bash

# RETURN=PASS
# RETURN=FAIL
# RETURN=<VALUE>

version=0.2
Default_Delay=5
Default_Delay_30=30

Log(){
    log -p d -t cqa_commands $1
}

##### FM - BEGIN #####
# Note: After FM module is enabled,
# the FM RSSI level must be periodically updated,
# or updated when the command FM_GetRSSI is received.
function FM_On
{
    am start -n com.android.fmradio/.CQA_FMRadio --es str "FM"
    RET1=$?
    if [ $RET1 -ne 0 ];then
        echo "RETURN=FAIL"
    else
        echo "RETURN=PASS"
    fi
}

function FM_Tune
{
    am start -a android.intent.action.CQA_FMRadio -n com.android.fmradio/.CQA_FMRadio --ef CQA_freq $1
    RET1=$?
    if [ $RET1 -ne 0 ];then
       echo "RETURN=FAIL"
    else
       echo "RETURN=PASS"
    fi
}

function FM_GetRSSI
{
    RET=$(cat data/data/com.android.fmradio/files/rssi.txt)
    if [ $RET ]; then
       echo "$RET"
    else
       echo "-999"
    fi
}

function FM_Off
{
    am force-stop com.android.fmradio
    RET1=$?
    if [ $RET1 -ne 0 ];then
        echo "RETURN=FAIL"
    else
        echo "RETURN=PASS"
    fi
}
##### FM - END #####

##### LED - BEGIN #####
# Note: Besides the Notification LED,
function LED_Red
{
	echo "0" > "/sys/class/leds/green/brightness"
	RET1=$?
    echo "255" > "/sys/class/leds/red/brightness"
	RET2=$?
	if [ $RET1 -eq 0 ] && [ $RET2 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function LED_Green
{
    echo "0" > "/sys/class/leds/red/brightness"
	RET1=$?
    echo "255" > "/sys/class/leds/green/brightness"
	RET2=$?
	if [ $RET1 -eq 0 ] && [ $RET2 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function LED_Off
{
    echo "0" > "/sys/class/leds/red/brightness"
	RET1=$?
    echo "0" > "/sys/class/leds/green/brightness"
	RET2=$?
	if [ $RET1 -eq 0 ] && [ $RET2 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}
##### LED - END #####

##### MIC - BEGIN #####
# Note: This is to enable the loopback between mics and headset speakers.
# We only need commands to enable and disable loopback for each microphone,
# so the number of commands depends directly on the number of product microphones.
function MIC_1_ToHeadsetRecv_On
{
	RET=$(AudioSetParam SET_LOOPBACK_TYPE=1,2)
	echo "RETURN=PASS"
}

function MIC_1_ToHeadsetRecv_Off
{
	RET=$(AudioSetParam SET_LOOPBACK_TYPE=0)
    echo "RETURN=PASS"
}

function MIC_2_ToHeadsetRecv_On
{
    RET=$(AudioSetParam SET_LOOPBACK_TYPE=3,2)
    echo "RETURN=PASS"
}

function MIC_2_ToHeadsetRecv_Off
{
    RET=$(AudioSetParam SET_LOOPBACK_TYPE=0)
    echo "RETURN=PASS"
}
##### MIC - END #####

##### Sensor Calibration - BEGIN #####
# Note: Normally ODMs have internal algorithm or applications
# that calibrate Gyroscope / Accelerometer / Proximity / Light sensors.
# $1: sensor type;
# $2: sensor property;
# $3: optional, sleep timeout, if empty the default delay is used.
function SENSOR_CALIBRATION
{
    if [ -z $3 ]; then
        TIMEOUT=$Default_Delay_30
    else
        TIMEOUT=$3
    fi

    setprop $2 ""
    VALUE=$(getprop $2)
    #echo "value RETURN=$VALUE,(!EMPTY should be returned!)"

    am broadcast -a "com.mmi.helper.request" --es type $1 --es action "calibrate" -f 0x01000000
    RET1=$?
    if [ $RET1 -ne 0 ];then
        echo "RETURN=FAIL"
        exit 1
    fi

    cur_time=0
    VALUE=""
    while [[ -z $VALUE && $cur_time -lt $TIMEOUT ]]
    do
        #echo cur_time:$cur_time,$VALUE,$2,$TIMEOUT
        VALUE=$(getprop $2)
        let "cur_time=cur_time+1"
        sleep 1
    done

    if [ "$VALUE"  == "1" ]; then
        echo "RETURN=PASS"
    else
        echo "RETURN=FAIL"
    fi
}

function SENSOR_CAL_GYRO
{
    SENSOR_CALIBRATION "gyrosensor_calibration" "vendor.gyrosensor_calibration.calibrate"
}

function SENSOR_CAL_ACCEL
{
    SENSOR_CALIBRATION "gsensor_calibration" "vendor.gsensor_calibration.calibrate"
}

function SAR_SENSOR_LISTENER_STOP
{
    am broadcast -a "com.mmi.sensor_listener_unregister" --es type "stop_sensor_listener" --es action "stop" -f 0x01000000

    RET=$?
    if [ $RET -ne 0 ];then
        echo "RETURN=FAIL"
    else
        echo "RETURN=PASS"
    fi
}

function SAR_SENSOR_TEST_START
{
    VALUE=$(getprop vendor.sarsensor_calibration.value)

    [ -z "$VALUE" ] && echo "RETURN=FAIL" || echo "RETURN=PASS, $VALUE"
}

function USB_DETACHED_SHUTDOWN
{

    if [ -z $1 ]; then
		 echo "Default Wait: $Default_Delay"
		 AC_Delay=$Default_Delay
	 else
		 echo "Wait: $1"
		 AC_Delay=$1
	 fi

     am broadcast -a "com.mmi.helper.request" --es type "usb_detached" --es action "test" -f 0x01000000
     RET1=$?
     if [ $RET1 -ne 0 ];then
         echo "RETURN=FAIL"
     else
         echo "RETURN=PASS"
     fi

     sleep $AC_Delay
}

function SENSOR_CAL_PROXIMITY_START
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		AC_Delay=$Default_Delay
	else
		echo "Wait: $1"
		AC_Delay=$1
	fi

    # start
    echo "start psensor_calibration"
    am broadcast -a com.mmi.helper.request --es type "psensor_calibration" --es action "start" -f 0x01000000
	RET_START_AM=$?
	if [ $RET_START_AM -ne 0 ];then
		echo "RETURN=FAIL"
		exit 1
	fi

    sleep $AC_Delay

    RET=$(getprop vendor.psensor_calibration.start)
    Log "$RET"
    if [ "$RET" == "1" ]; then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function SENSOR_CAL_PROXIMITY_NO_COVER
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		AC_Delay=$Default_Delay
	else
		echo "Wait: $1"
		AC_Delay=$1
	fi

	# no_cover
	echo "no_cover psensor_calibration"
	am broadcast -a com.mmi.helper.request --es type "psensor_calibration" --es action "no_cover" -f 0x01000000
	RET_NOCOVER_AM=$?
	if [ $RET_NOCOVER_AM -ne 0 ];then
		echo "RETURN=FAIL"
		exit 1
	fi

    sleep $AC_Delay

    RET=$(getprop vendor.psensor_calibration.no_cover)
    VALUE=$(getprop vendor.psensor.no_cover.value)
    Log "$RET"
    if [ "$RET" == "1" ]; then
		echo "RETURN=PASS, $VALUE"
	else
		echo "RETURN=FAIL"
	fi
}

function SENSOR_CAL_PROXIMITY_NEAR
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		AC_Delay=$Default_Delay
	else
		echo "Wait: $1"
		AC_Delay=$1
	fi

	# near_distance
	echo "near_distance psensor_calibration"
	am broadcast -a com.mmi.helper.request --es type "psensor_calibration" --es action "near_distance" -f 0x01000000
	RET_NEAR_AM=$?
	if [ $RET_NEAR_AM -ne 0 ];then
		echo "RETURN=FAIL"
		exit 1
	fi

    sleep $AC_Delay

    RET=$(getprop vendor.psensor_calibration.near_distance)
    VALUE=$(getprop vendor.psensor.near.value)
    Log "$RET"
    if [ "$RET" == "1" ]; then
		echo "RETURN=PASS, $VALUE"
	else
		echo "RETURN=FAIL"
	fi
}

function SENSOR_CAL_PROXIMITY_STOP
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		AC_Delay=$Default_Delay
	else
		echo "Wait: $1"
		AC_Delay=$1
	fi

	# stop
	echo "stop psensor_calibration"
	am broadcast -a com.mmi.helper.request --es type "psensor_calibration" --es action "stop" -f 0x01000000
	RET_STOP_AM=$?
	if [ $RET_STOP_AM -ne 0 ];then
		echo "RETURN=FAIL"
		exit 1
	fi

    sleep $AC_Delay

    RET=$(getprop vendor.psensor_calibration.stop)
    Log "$RET"
    if [ "$RET" == "1" ]; then
		echo "RETURN=PASS"
	else
	    echo "RETURN=FAIL"
	fi
}

function SENSOR_CAL_LIGHT
{
    # insert your code below
    echo "feature $0 not implemented"
	echo "RETURN=FAIL"
}
##### Sensor Calibration - END #####

##### TP Self Test - BEGIN #####
# Note: Each ODM can have its own algorithm to perform an autotest
# on the touch panel. Motorola SW for example have several tests like
# open, short, relative capacitance, number of rows and columns.
function TOUCH_PANEL_SelfTest
{
    RET=$(cat "/sys/ontim_dev_debug/touch_screen/vendor")
    check_node_to_tp_test $RET "skyworth-ili9881h" "/proc/ilitek/mp_lcm_on_test"
    check_node_to_tp_test $RET "skyworth-ili9882n" "/proc/ilitek/mp_lcm_on_test"
    check_node_to_tp_test $RET "skyworth-b26ts-ili9881h" "/proc/ilitek/mp_lcm_on_test"
    check_node_to_tp_test $RET "holitek-ili9881h" "/proc/ilitek/mp_lcm_on_test"
    check_node_to_tp_test $RET "truly_focaltech" "/sys/bus/i2c/devices/0-0038/fts_test"
    check_node_to_tp_test $RET "holitek-ft8006p" "/sys/bus/i2c/devices/0-0038/fts_test"
    check_node_to_tp_test_1_0 $RET "truly-icnl9911s-hjc" "/sys/chipone-tddi/test/self_test"
    check_node_to_tp_test_1_0 $RET "truly-icnl9911s-rs" "/sys/chipone-tddi/test/self_test"
    check_node_to_tp_test_1_0 $RET "truly-icnl9911s-601" "/sys/chipone-tddi/test/self_test"
    check_node_to_tp_test_1_0 $RET "easyquick-icnl9911s-608" "/sys/chipone-tddi/test/self_test"
    check_node_to_tp_test_1_0 $RET "easyquick-icnl9911c-608" "/sys/chipone-tddi/test/self_test"
}

function check_node_to_tp_test()
{
    if [[ $1 == $2 ]]; then

        typeset -l RESULT
        RESULT=$(cat $3)
        if [[ "$RESULT" == *"pass"* ]]; then
            echo "PASS"
        else
            echo "FAIL"
        fi
    fi
}

function check_node_to_tp_test_1_0()
{
    if [[ $1 == $2 ]]; then
        echo 1 > $3
        result=$(cat $3)
        echo 0 > $3
        if [[ "$result" == *"pass"* ]]; then
            echo "PASS"
        else
           echo "FAIL"
        fi
    fi
}

##### TP Self Test - END #####


##### FINGERPRINT Self Test - BEGIN #####
function FingerPrint_SelfTest
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		FP_Delay=$Default_Delay
	else
		echo "Wait: $1"
		FP_Delay=$1
	fi
    am broadcast -a com.mmi.helper.request --es type "fp_test" -f 0x01000000
	RET1=$?
	if [ $RET1 -ne 0 ];then
		echo "RETURN=FAIL (CAN NOT START FP SELF_TEST)"
		exit 1
	fi	
	
	sleep $FP_Delay

	RET2=$(getprop vendor.sys.ontim.fpselftest)
	if [ "$RET2" == "1" ]; then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
	
}
##### FINGERPRINT Self Test - END #####

##### FINGERPRINT Presence - BEGIN #####
function FingerPrint_PRESENCE
{
	if [ -z $1 ]; then
		echo "Default Wait: $Default_Delay"
		FP_Delay=$Default_Delay
	else
		echo "Wait: $1"
		FP_Delay=$1
	fi
	logcat -c
    am start -n com.odmtel.midtest/com.odmtel.midtest.FingerprintEnrollAuthen
	RET1=$?
	if [ $RET1 -ne 0 ];then
		echo "RETURN=FAIL (CAN NOT START FP ENROLL TEST)"
		exit 1
	fi	
	
	sleep $FP_Delay
	
	RET2=$(logcat -d FingerprintEnrollAuthen *:S | grep -c "result= 2030")
	if [ $RET2 -eq 0 ]; then
		echo "RETURN=FAIL (FP ENROLL TEST NOT STARTED)"
		exit 1
	fi
	RET3=$(logcat -d FingerprintEnrollAuthen *:S | grep -c "result= -56")
	if [ $RET3 -ne 0 ]; then
		echo "RETURN=FAIL (FINGERPRINT PRESENCE TEST FAILED)"
		exit 1
	else
		echo "RETURN=PASS"
	fi
		
	
}
##### FINGERPRINT Presence - END #####


##### On/Off Batt Charge - BEGIN #####
# Note: This is to force Android to disable the phone charging
# even with USB cable connected. Important is to guarantee that not only
# the charging icon has changed, but energy is not flowing to battery to charge it.
# This is required for battery current tests, to measure battery discharge.
function BATT_CHARGE_Enable
{
	echo "1" > "/sys/devices/platform/charger/charge_onoff_ctrl"
	RET1=$?
	if [ $RET1 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function BATT_CHARGE_Disable
{
	echo "0" > "/sys/devices/platform/charger/charge_onoff_ctrl"
	RET1=$?
	if [ $RET1 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}
##### On/Off Batt Charge - END #####

##### Read Batt Current - BEGIN #####
# Note: This is part of battery/current tests that must be performed.
# Need to provide the real-time current flow on the phone battery.
# It is very important that the current value returned is as real-time as possible.
# Command will be executed multiple times to measure stability and average.
function BATT_CURRENT_Read
{
    # insert your code below
	RET=$(cat /sys/class/power_supply/battery/current_now)
	RET=`expr $RET / 1000`
	echo $RET mA
	if [ $RET ]; then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}
##### Read Batt Current - END #####

function BATT_LIMIT_ON
{
    echo "1" > "/sys/devices/platform/charger/runin_onoff_ctrl"
    RET1=$?
    if [ $RET1 -eq 0 ];then
        echo "RETURN=PASS"
    else
        echo "RETURN=FAIL"
    fi
}

function BATT_LIMIT_OFF
{
    echo "0" > "/sys/devices/platform/charger/runin_onoff_ctrl"
    RET1=$?
    if [ $RET1 -eq 0 ];then
        echo "RETURN=PASS"
    else
        echo "RETURN=FAIL"
    fi
}

##### Read Barcode - BEGIN #####
# Note: This get the barcode serial number
function READ_TRACK_ID
{    # insert your code below
	RET=$(getprop ro.serialno)
	echo $RET 	
}
##### Read Barcode - END #####

####################################################################
# Function:    FACTORY_RESET			  		          	       #
# Description: This function should force the phone factory reset  #
# Inputs:      N/A										   		   #
# Output:      status: 	OK/ERROR   						   		   #
####################################################################
function Factory_Reset
{
    am broadcast -a com.mmi.reset -f 0x01000000
	RET1=$?
	if [ $RET1 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function Turn_Unit_Secure
{
    RET=$(getprop ro.boot.securefuse)
    Log "$RET"
    if [ "$RET" == "true" ]; then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}

function STAY_AWAKE_ON
{
    am broadcast -a com.mmi.stay_awake_on -f 0x01000000
        RET1=$?
        if [ $RET1 -eq 0 ];then
                echo "RETURN=PASS"
        else
                echo "RETURN=FAIL"
        fi
}

function STAY_AWAKE_OFF
{
    if ( dumpsys window policy | grep screenState=SCREEN_STATE_OFF );then
        echo "current SCREEN_STATE_OFF , don't off again"
        return;
    fi

    # press power key
    input keyevent 26
    am broadcast -a com.mmi.stay_awake_off -f 0x01000000
        RET1=$?
        if [ $RET1 -eq 0 ];then
                echo "RETURN=PASS"
        else
                echo "RETURN=FAIL"
        fi
}

##### Power on Torch - BEGIN #####
# Note: Power on Torch
function TORCH_ON
{
	echo "1" > /sys/kernel/torch_status
	RET1=$?
	if [ $RET1 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}
##### Power on Torch - END #####

##### Power off Torch - BEGIN #####
# Note: Power off Torch
function TORCH_OFF
{
	echo "0" > /sys/kernel/torch_status
	RET1=$?
	if [ $RET1 -eq 0 ];then
		echo "RETURN=PASS"
	else
		echo "RETURN=FAIL"
	fi
}
##### Power off Torch - END #####

##### Read hardware sku - BEGIN #####
# Note: This get the hardware sku
function READ_HW_SKU
{    # insert your code below
	RET=$(getprop ro.boot.hardware.sku)
	echo $RET
}
##### Read hardware sku - END #####

##### Read TP ID - BEGIN #####
# Note: This get the TP vendor ID
function TP_ID
{
    RET=$(cat "/sys/hwinfo/TP_MFR")
    if [ "$RET" ]; then
       echo "$RET"
    else
       echo "FAIL"
    fi
}
##### Read TP ID - END #####

##### Read LCD ID - BEGIN #####
# Note: This get the LCD vendor ID
function LCD_ID
{
    RET=$(cat "/sys/hwinfo/LCD_MFR")
    if [ "$RET" ]; then
       echo "$RET"
    else
       echo "FAIL"
    fi
}
##### Read LCD ID- END #####

##### Set AIRPLANE_MODE ON- BEGIN #####
# Note: Set AIRPLANE_MODE ON
function AIRPLANE_MODE_ON
{
    settings put global airplane_mode_on 1
    RET1=$?
    if [ $RET1 -eq 0 ];then
        am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
        RET2=$?
        if [ $RET2 -eq 0 ];then
            echo "RETURN=PASS"
        else
            echo "RETURN=FAIL"
        fi
    else
        echo "RETURN=FAIL"
    fi
}
##### Set AIRPLANE_MODE ON- END #####

##### Set AIRPLANE_MODE OFF- BEGIN #####
# Note: Set AIRPLANE_MODE OFF
function AIRPLANE_MODE_OFF
{
    settings put global airplane_mode_on 0
    RET1=$?
    if [ $RET1 -eq 0 ];then
        am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
        RET2=$?
        if [ $RET2 -eq 0 ];then
            echo "RETURN=PASS"
        else
            echo "RETURN=FAIL"
        fi
    else
        echo "RETURN=FAIL"
    fi
}
##### Set AIRPLANE_MODE OFF- END #####

##### Get CARD_HOLDER_PRESENT- BEGIN #####
# Note: Get CARD_HOLDER_PRESENT
function CARD_HOLDER_PRESENT
{
    RET=$(cat "/sys/hwinfo/CARD_HOLDER_PRESENT")
    if [ "$RET" ]; then
       echo "$RET"
    else
       echo "FAIL"
    fi
}
##### Get CARD_HOLDER_PRESENT- END #####

function GET_FP_INFO
{
    RET=$(cat "/sys/hwinfo/FP_MFR")
    if [ "$RET" ]; then
       echo "$RET"
    else
       echo "FAIL"
    fi
}

function CHECK_BROAD_TEST
{
    NODE1="FP_MFR=ICNF7332"
    NODE2="FP_MFR=FT9362L6"

    RET=$(cat "/sys/hwinfo/FP_MFR")
    if [[ $RET == *$NODE1* ]]; then
       BORADTEST1=$(/vendor/bin/chipone_fp_test check_board_test)
       echo "$BORADTEST1"
    fi

    if [[ "$RET" == *$NODE2* ]]; then
       BORADTEST2=$(/vendor/bin/focal_fp_test check_board_test)
       echo "$BORADTEST2"
    fi
}

function FINGER_DOWN
{
    RET=$(cat "/sys/hwinfo/FP_MFR")
    NODE1="FP_MFR=ICNF7332"
    NODE2="FP_MFR=FT9362L6"

    if [[ $RET == *$NODE1* ]]; then
       DOWN1=$(/vendor/bin/chipone_fp_test finger_down)
       echo "$DOWN1"
    fi

    if [[ "$RET" == *$NODE2* ]]; then
       DOWN2=$(/vendor/bin/focal_fp_test finger_down)
       echo "$DOWN2"
    fi
}

function Camera_Verification
{
    getResultCmd="getprop ontim.autotest.result"
    result="0"

    setprop ontim.autotest.result 0

    am start -n com.arcsoft.verification.Activity/.MainActivity --es mode auto

    while [ "$result" == "0" ]
    do
        result=$($getResultCmd)
        sleep 1
    done

    echo "RESULT : $result"
}

function Camera_Calibration
{
    getResultCmd="getprop ontim.autotest.result"
    result="0"

    setprop ontim.autotest.result 0

    am start -n com.arcsoft.calibration.Activity/.MainActivity --es mode auto

    while [ "$result" == "0" ]
    do
        result=$($getResultCmd)
        sleep 1
    done

    echo "RESULT : $result"
}

function UTAG_BATTERY_ID
{
    # lower string
    # typeset -l INPUT=$1
    ID=""
    [[ $1 == "SB18C28957" ]] && ID="83 66 49 56 67 50 56 57 53 55"
    [[ $1 == "SB18C28956" ]] && ID="83 66 49 56 67 50 56 57 53 54"
    [[ $1 == "SB18C47080" ]] && ID="83 66 49 56 67 52 55 48 56 48"
    [[ $1 == "SB18C44581" ]] && ID="83 66 49 56 67 52 52 53 56 49"
    [[ $1 == "SB18C45530" ]] && ID="83 66 49 56 67 52 53 53 51 48"

    if [[ -z $ID ]]; then
        echo "FAIL, wrong parameter!"
    else
        RESULT=$(/system/bin/FacsvcClient -w 89 -v $ID)
        if [[ -z $RESULT ]]; then
            echo "FAIL, $RESULT"
        else
            echo "PASS, $RESULT"
        fi
    fi
}

function GET_CAP_TEST_RESULT
{
    GET_CQATEST_RESULT "/sdcard/Capsensor.txt"
}

function GET_FINGERPRINT_RESULT
{
    GET_CQATEST_RESULT "/data/data/com.motorola.motocit/temp/FingerPrint"
}

function GET_CQATEST_RESULT
{
    RET=$(cat $1)
    if [[ $RET == "PASS" ]]; then
        echo "PASS"
    else
        echo "FAIL"
    fi
}

function CHECK_CAMERA_INFO
{
    MAININFO=$(cat "/sys/hwinfo/BACK_CAM_MFR")
    AUXINFO=$(cat "/sys/hwinfo/BACKAUX_CAM_MFR")
    if [[ $MAININFO == *"Unknown"* ]]; then
        echo "FAIL"
    fi
    mainCamera1="s5k3p9sx_TXD"
    mainCamera2="s5k3p9sx_TSP"
    mainCamera3="ov16a10_HLT"
    str1="gc2375_TXD"
    str2="bj_TspGc2375_MainTXD3P9"
    str3="gc2375_TXD_NewModule"
    str4="blackjack_tsp_gc2375"
    str5="blackjack_sun_gc02m1b"
    str6="blackjack_sun_gc02m1c"
    resultMain=$(echo $MAININFO | grep ${mainCamera1})
    if [[ "$resultMain" != "" ]]
    then
        resultAux1=$(echo $AUXINFO | grep ${str1})
        resultAux2=$(echo $AUXINFO | grep ${str2})
        resultAux3=$(echo $AUXINFO | grep ${str3})
        if [[ "$resultAux1" != "" || "$resultAux2" != ""  || "$resultAux3" != "" ]]
        then
            echo "PASS"
        else
            echo "FAIL"
        fi
    fi
    resultMain=$(echo $MAININFO | grep ${mainCamera2})
    if [[ "$resultMain" != "" ]]
    then
        resultAux4=$(echo $AUXINFO | grep ${str4})
        resultAux5=$(echo $AUXINFO | grep ${str5})
        if [[ "$resultAux4" != "" || "$resultAux5" != "" ]]
        then
            echo "PASS"
        else
            echo "FAIL"
        fi
    fi
    resultMain=$(echo $MAININFO | grep ${mainCamera3})
    if [[ "$resultMain" != "" ]]
    then
         resultAux6=$(echo $AUXINFO | grep ${str6})
        if [[ "$resultAux6" != "" ]]
        then
            echo "PASS"
        else
            echo "FAIL"
        fi
    fi
}

##### Main #####
eval $@
