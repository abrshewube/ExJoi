# ExJoi v0.9.0 - Async Validation & Parallel Processing 🚀

Just released **ExJoi v0.9.0** with async validation support! Now you can validate with external services, database lookups, and long-running computations—all running in parallel using `Task.async_stream`.

## What's New

- **Async validators** with `ExJoi.async/3` for external service checks
- **Parallel processing** - multiple async fields validate simultaneously
- **Timeout control** - configurable timeouts per rule or globally
- **Array element validation** - validate array items in parallel

## Quick Example

```elixir
schema = ExJoi.schema(%{
  username: ExJoi.async(
    ExJoi.string(required: true, min: 3),
    fn value, _ctx ->
      Task.async(fn ->
        if UsernameService.available?(value) do
          {:ok, value}
        else
          {:error, [%{code: :username_taken, message: "username is already taken"}]}
        end
      end)
    end,
    timeout: 3000
  )
})

# Multiple async fields run in parallel automatically
ExJoi.validate(data, schema, max_concurrency: 5)
```

## Resources

- **HexDocs**: https://hexdocs.pm/exjoi/0.9.0
- **Live Docs**: https://ex-joi.vercel.app/async-validation.html
- **GitHub**: https://github.com/abrshewube/ExJoi

Check out the [full documentation](https://ex-joi.vercel.app/async-validation.html) for real-world examples, error handling, and best practices!

