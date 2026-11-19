# Energy meter: Tuya 4P 80A three-phase meter (MTY2)

The heat pump's supply runs through a Tuya three-phase 80A energy meter and breaker, so Home Assistant gets real power and energy figures instead of an estimate. It runs locally through [Tuya Local](https://github.com/make-all/tuya-local).

| | |
| --- | --- |
| Product | 4P 80A Tuya Smart Three-Phase Energy Meter & Protector (breaker, model MTY2) |
| Also sold as | TVPS3-100P |
| Tuya product id | `4tpaetqac6lap6mv` |
| Protocol | 3.5 |
| Firmware | Stock Tuya (not flashed) |
| Upstream | [tuya-local #6241](https://github.com/make-all/tuya-local/issues/6241), device config added in commit 59743a7 (unreleased as of Nov 2026) |

## DP mapping

Scaling verified against the meter's display with about 1.6 kW load. The energy counter details come from jace's UART capture in #6241.

| DP | Meaning | Scaling / type |
| --- | --- | --- |
| 1 | "switch_1", vendor note "not used" | Does not control the relay, hide it |
| 101 / 102 | Relay on / off | raw `AAE=` |
| 103 | Relay status (bitmap) | 15 = on, 0 = off |
| 104 | Refresh | Write to get fresh values |
| 105 / 110 | Total / instantaneous data (raw) | Cloud only, not sent locally |
| 106 | Residual current | mA |
| 119 | Split enable | Switches 101/102 to per-phase control |
| 121 | Energy import, total | /100 kWh, `total_increasing` |
| 122 | Energy export, total | /100 kWh, `total_increasing` |
| 123 / 125 / 127 | Import per phase | /100 kWh, `total_increasing`, sum = 121 |
| 124 / 126 / 128 | Export per phase | /100 kWh, `total_increasing`, sum = 122 |
| 130 | Total power | ×10 W, always positive |
| 131 | Temperature | °C |
| 132 / 133 / 134 | Voltage L1 / L2 / L3 | /100 V |
| 135 / 136 / 137 | Current L1 / L2 / L3 | /100 A |
| 138 / 139 / 142 | Power L1 / L2 / L3 | ×10 W, always positive |

Direction (import or export) only shows in which of 121 and 122 is rising. DP 120 ("stats_energy1") is not yet understood.

### DP 103 bits

| Bit | Meaning |
| --- | --- |
| 0 | Whole breaker |
| 1 / 2 / 3 | L1 / L2 / L3 |
| 4–7 | Never seen set |

0x0F = all closed. With DP 119 on, DP 102 `00 02` / `00 04` / `00 08` opens L1 / L2 / L3.

## Refresh every 10 seconds

The MCU only reports by itself every 15–16 minutes, or on a state change. The stock Wi-Fi firmware never polls on a timer, so an automation presses the refresh button (DP 104) every 10 seconds:

```yaml
alias: Energimåler varmepumpe – refresh
description: >-
  Tuya 3-faset måler (Teknikgang) sender kun nye værdier efter refresh på DP 104.
  Trykker Refresh hvert 10. sekund.
triggers:
  - trigger: time_pattern
    seconds: /10
conditions: []
actions:
  - action: button.press
    target:
      entity_id: button.teknik_gang_tuya_3_faset_energimaaler_80a_breaker_mty2_refresh
mode: single
max_exceeded: silent
```

## Energy dashboard

Until the upstream config marks the energy counters as `total_increasing`, they can be overridden in `configuration.yaml` (entity ids are examples):

```yaml
homeassistant:
  customize:
    sensor.energy_meter_import:
      state_class: total_increasing
      device_class: energy
      unit_of_measurement: kWh
    sensor.energy_meter_export:
      state_class: total_increasing
      device_class: energy
      unit_of_measurement: kWh
```

Remove the block again once the official config is in a Tuya Local release.
