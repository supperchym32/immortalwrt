#!/bin/sh

PWMCHIP="/sys/class/pwm/pwmchip0"
PWM="$PWMCHIP/pwm0"
THERMAL="/sys/class/thermal/thermal_zone0/temp"

[ -d "$PWMCHIP" ] || exit 1

if [ ! -d "$PWM" ]; then
    echo 0 > "$PWMCHIP/export"
    sleep 1
fi

while [ ! -d "$PWM" ]; do
    sleep 1
done

if [ "$(cat "$PWM/enable")" = "1" ]; then
    echo 0 > "$PWM/enable"
fi

echo 50000 > "$PWM/period"
echo 1 > "$PWM/enable"

# Max speed 5 giây
echo 46990 > "$PWM/duty_cycle"
sleep 5
echo 25000 > "$PWM/duty_cycle"

while true; do
    temp=$(cat "$THERMAL")
    DUTY=$(cat "$PWM/duty_cycle")

    new_duty=49990
    low=50000

    if [ "$temp" -gt 75000 ]; then
        new_duty=10000
        low=70000
    elif [ "$temp" -gt 63000 ]; then
        new_duty=25000
        low=58000
    elif [ "$temp" -gt 58000 ]; then
        new_duty=35000
        low=53000
    elif [ "$temp" -gt 55000 ]; then
        new_duty=46990
        low=50000
    fi

    if [ "$new_duty" -gt "$DUTY" ]; then
        if [ "$temp" -lt "$low" ]; then
            DUTY="$new_duty"
        fi
    else
        DUTY="$new_duty"
    fi

    echo "$DUTY" > "$PWM/duty_cycle"

    sleep 2
done