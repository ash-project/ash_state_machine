# Working with `Ash.can?`

Using `Ash.can?/3` won't return `false` if a given state machine transition is invalid. This is because `Ash.can?/3` is only concerned with policies, not changes/validations. However, many folks use `Ash.can?/3` in their UI to determine whether a given button/form/etc should be shown. To help with this you can add the following to your resource:

```elixir
policies do
  policy always() do
    authorize_if AshStateMachine.Checks.ValidNextState
  end
end
```

This check is only used in _pre_flight_ authorization checks (i.e calling `Ash.can?/3`), but it will return `true` in all cases when running real authorization checks. This is because the change is validated when you use the `transition_state/1` change and `AshStateMachine.transition_state/2`, and so you would be doing extra work for no reason.
