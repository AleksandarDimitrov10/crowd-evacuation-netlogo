# Crowd Evacuation Simulation in NetLogo

This project is an agent-based simulation of emergency crowd evacuation in enclosed spaces. It was developed in NetLogo for the Multi-Agent Systems course at Tilburg University.

The model investigates how factors such as exit availability, exit capacity, agent energy, crowd density, and leader presence influence evacuation efficiency and safety.

## Research Question

What factors influence the efficiency and safety of crowd evacuations during emergencies?

## Overview

The simulation represents a building layout with walls, rooms, exits, and moving agents. Each agent represents an individual trying to evacuate. Agents differ in speed and energy, and they must navigate toward available exits while avoiding walls and congestion.

The model allows users to adjust several parameters and observe how these changes affect evacuation outcomes such as escape percentage, death percentage, and evacuation success.

## Key Features

- Agent-based evacuation simulation in NetLogo
- Building layout with walls, rooms, and exits
- Adjustable number of exits
- Adjustable exit capacity
- Adjustable number of agents
- Agent energy depletion over time
- Optional leader agent
- Leader can either know or not know the exit location
- Tracking of successful evacuations and casualties
- BehaviourSpace experiments for scenario comparison

## Model Parameters

| Parameter | Meaning |
|---|---|
| `agent-count` | Number of agents in the simulation |
| `exit-count` | Number of exits available in the environment |
| `exit-capacity` | Number of agents that can pass through exits |
| `max-energy` | Maximum energy level of agents |
| `show-leader` | Whether a leader agent is present |
| `leader-knows-exit` | Whether the leader knows where the exits are |

## How the Model Works

Agents are placed inside a simulated building. They move through the environment while avoiding walls and attempting to reach exits. Each movement step decreases the agent's energy. If an agent reaches an exit, it successfully evacuates. If its energy reaches zero before escaping, it is counted as a casualty.

When a leader is present and knows the exit location, followers can be guided more effectively toward exits. This allows comparison between unguided and guided evacuation scenarios.

## Experiments

Three main scenarios were tested:

### Scenario 1: Worst Case

- Few exits
- Low exit capacity
- Low agent energy
- No leader guidance

This scenario produced the weakest evacuation outcomes.

### Scenario 2: Medium Case

- Moderate number of exits
- Moderate exit capacity
- Medium agent energy
- Leader present, but without exit knowledge

This scenario improved evacuation outcomes compared with the worst-case condition.

### Scenario 3: Best Case

- More exits
- Higher exit capacity
- Higher agent energy
- Leader present and aware of exit locations

This scenario produced the strongest evacuation outcomes.

## Main Findings

The results showed that evacuation success improves when:

- More exits are available
- Exit capacity is higher
- Agents have more energy
- A leader can guide agents toward exits

The best-case scenario achieved the highest escape percentages, while the worst-case scenario produced the lowest evacuation success.

## Project Files

```text
crowd-evacuation-netlogo/
├── model/
│   └── crowd_evacuation_model.nlogo
├── docs/
│   ├── interface-before-setup.png
│   ├── interface-after-setup.png
│   └── experiment-summary.md
├── analysis/
│   └── results-summary.md
├── README.md
├── LICENSE
└── .gitignore
