from machine import Pin
import time

sda = Pin(14, Pin.IN)
scl = Pin(15, Pin.IN)

UART_BIT_US = 833

events = []

program_start = time.ticks_ms()

print("Protocol Analyzer")


def decode_uart():

    line_buffer = ""

    start = time.ticks_ms()

    while time.ticks_diff(time.ticks_ms(), start) < 2000:

        while sda.value() == 1:

            if time.ticks_diff(time.ticks_ms(), start) >= 2000:
                return

        time.sleep_us(UART_BIT_US // 2)

        if sda.value() != 0:
            continue

        time.sleep_us(UART_BIT_US)

        value = 0

        for i in range(8):

            value |= (sda.value() << i)

            time.sleep_us(UART_BIT_US)

        if sda.value() != 1:
            continue

        if 32 <= value <= 126:

            line_buffer += chr(value)

        elif value == 10:

            message = line_buffer.strip()

            if message:

                timestamp = time.ticks_diff(
                    time.ticks_ms(),
                    program_start
                )

                print(
                    "Time =",
                    timestamp,
                    "ms | UART =",
                    message
                )

                events.append(
                    (
                        timestamp,
                        "UART",
                        message
                    )
                )

                if len(events) > 10:
                    events.pop(0)

            line_buffer = ""

        while sda.value() == 0:
            pass


while True:

    sda_edges = 0
    scl_edges = 0

    i2c_start_count = 0
    scl_rising_count = 0

    prev_sda = sda.value()
    prev_scl = scl.value()

    window_start = time.ticks_ms()

    while time.ticks_diff(
        time.ticks_ms(),
        window_start
    ) < 2000:

        cur_sda = sda.value()
        cur_scl = scl.value()

        if cur_sda != prev_sda:
            sda_edges += 1

        if cur_scl != prev_scl:
            scl_edges += 1

        if (
            prev_sda == 1 and
            cur_sda == 0 and
            cur_scl == 1
        ):
            i2c_start_count += 1

        if (
            prev_scl == 0 and
            cur_scl == 1
        ):
            scl_rising_count += 1

        prev_sda = cur_sda
        prev_scl = cur_scl

        time.sleep_us(100)

    timestamp = time.ticks_diff(
        time.ticks_ms(),
        program_start
    )

    if (
        i2c_start_count > 0 and
        scl_rising_count > 20 and
        scl_edges > 5
    ):

        print()
        print("Time =", timestamp, "ms")
        print("Protocol = I2C")
        print("SDA Edges =", sda_edges)
        print("SCL Edges =", scl_edges)
        print("START Conditions =", i2c_start_count)
        print("Clock Pulses =", scl_rising_count)

        events.append(
            (
                timestamp,
                "I2C",
                i2c_start_count,
                scl_rising_count
            )
        )

        if len(events) > 10:
            events.pop(0)

    elif (
        sda_edges > 20 and
        scl_edges <= 2
    ):

        print()
        print("Time =", timestamp, "ms")
        print("Protocol = UART")
        decode_uart()

    time.sleep_ms(100)
