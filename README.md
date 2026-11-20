# xper-forever

WoW Forever (`Interface: 16001`) chat expression addon. Unzip into `Interface\AddOns` so the folder is `xper-forever` (name must match the `.toc`).

## `/x` expressions

- `/x 1+1` evaluates a Lua expression
- `/x 5x5` treats `x` as multiply
- `/x 15c` and `/x 15f` convert Celsius and Fahrenheit

## `/xs` swim speed

`/xs` takes one or more **item swim speed bonus percents**. Separate them with commas and/or spaces.

```
/xs 30,15,10
/xs 30 15 10
/xs 30
```

What those numbers are: the “Increases swimming speed by X%” values from items/enchants, not your current speed.

How it calculates:

1. Add the bonuses (they stack additively): `30 + 15 + 10 = 55%`
2. Apply that to base swim, which is **67.46% of ground run speed**: `67.46 × 1.55`
3. Compare the result to 100% run speed and print faster or slower

Example:

```
/xs 30,15,10
Swim bonus: 55% of swim (67.46 × 1.55, 4.56% faster than base running speed)
```

`/xs` with no arguments prints this usage.
