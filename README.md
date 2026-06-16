# General-Physics-Project

# Ballistic Pendulum Simulation

A Godot 4 simulation based on the paper by J. C. Sanders,
"The effects of projectile mass on ballistic pendulum displacement,"
*American Journal of Physics* 88(5), 360–364 (2020).

General Physics 1 Group Project — Group 13
(Eunseo Choi, Seojin Hyun), DGIST.

## Overview

This simulation shows how the projectile mass affects the maximum
displacement of a ballistic pendulum. Instead of using a real physics
engine, it calculates the motion directly from the formulas in the paper
(momentum conservation, energy conservation, and the spring launching
process). This lets us check whether the simulation results match the
theory.

## Features

- You can change the projectile mass (mb: 4.7–300 g) and the pendulum mass (mc: 29–200 g)
- 3D animation of the firing process (cocking → launch → collision → swing)
- A real-time mb–Δh graph that shows the theory curve and the optimal mass

## How to Run

1. Install Godot 4 (https://godotengine.org/)
2. Open `project.godot` in Godot
3. Press the Play button (F5)

## File Structure

- `scripts/PhysicsConstants.gd` — physics formulas and fixed values
- `scripts/SimulationController.gd` — controls the firing sequence
- `scripts/Main.gd` — connects the nodes and handles the buttons
- `scripts/Projectile.gd`, `CupPendulum.gd`, `SpringGun.gd` — animations
- `scripts/GraphPanel.gd` — draws the graph



