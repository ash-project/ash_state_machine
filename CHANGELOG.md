# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.2.9](https://github.com/ash-project/ash_state_machine/compare/v0.2.8...v0.2.9) (2025-04-09)




### Improvements:

* set the default_initial_state from initial_states if possible (#101)

* add igniter installer (#100)

## [v0.2.8](https://github.com/ash-project/ash_state_machine/compare/v0.2.7...v0.2.8) (2025-03-03)




### Bug Fixes:

* Add String.to_existing_atom casting to builtin change (#89)

* support transitioning state to a string

* handle `nil` target state in `no_matching_event` error

### Improvements:

* upgrade ash for atomic condition fixes

## [v0.2.7](https://github.com/ash-project/ash_state_machine/compare/v0.2.6...v0.2.7) (2024-11-26)

### Improvements:

- Allow create upsert actions in state transitions (#71)

## [v0.2.6](https://github.com/ash-project/ash_state_machine/compare/v0.2.5...v0.2.6) (2024-08-31)

### Bug Fixes:

- don't return tuple from `valid_next_state`

## [v0.2.5](https://github.com/ash-project/ash_state_machine/compare/v0.2.4...v0.2.5) (2024-07-13)

### Improvements:

- simplify atomic state transition with new ash feature

## [v0.2.4](https://github.com/ash-project/ash_state_machine/compare/v0.2.3...v0.2.4) (2024-06-17)

### Bug Fixes:

- support accepting the `:state` attribute

## [v0.2.3](https://github.com/ash-project/ash_state_machine/compare/v0.2.3-rc.1...v0.2.3) (2024-05-10)

## [v0.2.3-rc.1](https://github.com/ash-project/ash_state_machine/compare/v0.2.3-rc.0...v0.2.3-rc.1) (2024-05-04)

### Improvements:

- policy for including state machine in `can?` checks

- optimize atomic state transition check

- add atomic implementation

## [v0.2.3-rc.0](https://github.com/ash-project/ash_state_machine/compare/v0.2.2...v0.2.3-rc.0) (2024-03-29)

### Improvements:

- update to Ash 3.0

## [v0.2.2](https://github.com/ash-project/ash_state_machine/compare/v0.2.1...v0.2.2) (2023-09-15)

### Bug Fixes:

- scrub `:*` from the list of states

- proper entity path in replace logic

### Improvements:

- Add `possible_next_states` helper. (#9)

- Add `possible_next_states` helper.

- detect states used that don't exist and log an error

## [v0.2.1](https://github.com/ash-project/ash_state_machine/compare/v0.2.0...v0.2.1) (2023-09-08)

### Bug Fixes:

- Allow `next_state` to to match transitions from \*. (#7)

## [v0.2.0](https://github.com/ash-project/ash_state_machine/compare/v0.1.5...v0.2.0) (2023-09-08)

### Features:

- Add `next_state` builtin change. (#6)

### Improvements:

- exclude star from state_machine_all_states/1 to avoid inclusion in add_attribuet builder (#4)

## [v0.1.5](https://github.com/ash-project/ash_state_machine/compare/v0.1.4...v0.1.5) (2023-08-04)

### Improvements:

- support :\* in states

## [v0.1.4](https://github.com/ash-project/ash_state_machine/compare/v0.1.3...v0.1.4) (2023-05-03)

### Bug Fixes:

- Rename `from` to `old_state` in `NoMatchingTransition` error (#3)

## [v0.1.3](https://github.com/ash-project/ash_state_machine/compare/v0.1.2...v0.1.3) (2023-04-28)

### Bug Fixes:

- == not != for checking all states

## [v0.1.2](https://github.com/ash-project/ash_state_machine/compare/v0.1.1...v0.1.2) (2023-04-28)

## [v0.1.1](https://github.com/ash-project/ash_state_machine/compare/v0.1.0...v0.1.1) (2023-04-23)

### Improvements:

- make state diagrams the default chart

## [v0.1.0](https://github.com/ash-project/ash_state_machine/compare/v0.1.0...v0.1.0) (2023-04-23)

### Features:

- add mix task `ash_state_machine.generate_flow_charts` (#1)

### Bug Fixes:

- action does not uniquely identify a transition

- require `allow_nil? false` on state attribute

### Improvements:

- require `initial_states`

- fix lint/credo, handle all changeset types

- require from/to

- flow chart generation

- support `:*` as a transition action name to match all
