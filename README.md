# copmax-heatpump-rs485

Reading (and later adjusting) the parameters of a **Copmax / HPW AW-10-15-20** air-to-water heat pump over its RS485 bus, using an ESP32 with ESPHome and Home Assistant.

The heat pump is controlled by a **Siemens PolyCool RWR470.10** PLC. Its RS485 port (A+ / B- / GND, plus an RJ45) is officially only used for the optional **HSHMI-01** remote panel, and there is no public Modbus register list. The goal of this project is to work that out.

## Goals

1. **Sniff** the existing HSHMI-01 ↔ PLC traffic passively, to learn the protocol, baud rate and register addresses.
2. **Read** temperatures, status and parameters into Home Assistant.
3. **Write** selected parameters (for example the heating setpoint ST02) from Home Assistant.

## Hardware

| Part | Use |
| --- | --- |
| ESP32 DevKit | ESPHome node |
| MAX3485 TTL-to-RS485 module (3.3 V) | Bus interface for the ESP32 |
| Waveshare industrial USB-to-RS485 adapter | Sniffing and testing from a PC |
| Tuya 3-phase 80A energy meter (MTY2) | Real power and energy for the heat pump ([tuya-local #6241](https://github.com/make-all/tuya-local/issues/6241)) |

### Wiring (passive sniffing)

| MAX3485 | ESP32 / bus |
| --- | --- |
| VCC | 3.3 V |
| GND | GND (also to PLC GND) |
| RO | GPIO16 (UART RX) |
| DI | GPIO17 (UART TX) |
| DE + RE | Tied to GND (receive only) |
| A / B | PLC A+ / B- |

Keep DE/RE low while sniffing, so the ESP32 can never drive the bus.

## Known PLC settings

Read from the PLC panel on this installation:

| Parameter | Value | Meaning |
| --- | --- | --- |
| ST02 | 45 °C | Heating flow setpoint |
| ST04 | 10 °C | Heating temperature differential (scale max) |
| EV01 | 0 | Circulation pump runs continuously |
| CM07 | – | Not relevant, no 4-way valve fitted |
| ST19 | 2.0 | "No use" according to the manual |

The heat pump is switched on and off from Home Assistant through a volt-free relay on terminals B1–B2, not by the PLC's internal thermostat.

## Status

- [x] Energy meter set up in Home Assistant (Tuya Local, refresh every 10 s)
- [ ] Passive sniffing with ESP32 + MAX3485 (`esphome/rs485-sniffer.yaml`)
- [ ] Identify baud rate, framing and protocol (Modbus RTU expected)
- [ ] Map register addresses
- [ ] Read values into Home Assistant with `modbus_controller`
- [ ] Write parameters from Home Assistant

## Files

- `esphome/rs485-sniffer.yaml` – receive-only ESPHome node that logs every frame on the bus as hex.

Findings will go in `docs/` as they turn up.
