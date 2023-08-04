# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.1.5](https://github.com/ash-project/ash_state_machine/compare/v0.1.4...v0.1.5) (2023-08-04)




### Improvements:

* support :* in states

## [v0.1.4](https://github.com/ash-project/ash_state_machine/compare/v0.1.3...v0.1.4) (2023-05-03)




### Bug Fixes:

* Rename `from` to `old_state` in `NoMatchingTransition` error (#3)

## [v0.1.3](https://github.com/ash-project/ash_state_machine/compare/v0.1.2...v0.1.3) (2023-04-28)




### Bug Fixes:

* == not != for checking all states

## [v0.1.2](https://github.com/ash-project/ash_state_machine/compare/v0.1.1...v0.1.2) (2023-04-28)




## [v0.1.1](https://github.com/ash-project/ash_state_machine/compare/v0.1.0...v0.1.1) (2023-04-23)




### Improvements:

* make state diagrams the default chart

## [v0.1.0](https://github.com/ash-project/ash_state_machine/compare/v0.1.0...v0.1.0) (2023-04-23)




### Features:

* add mix task `ash_state_machine.generate_flow_charts` (#1)

### Bug Fixes:

* action does not uniquely identify a transition

* require `allow_nil? false` on state attribute

### Improvements:

* require `initial_states`

* fix lint/credo, handle all changeset types

* require from/to

* flow chart generation

* support `:*` as a transition action name to match all
