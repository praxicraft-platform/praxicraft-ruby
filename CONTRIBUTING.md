# Contributing

```bash
git clone https://github.com/praxicraft-platform/praxicraft-ruby.git
cd praxicraft-ruby
bundle install
bundle exec rake test
```

Guidelines:

- Thin wrapper around the [Assess Public API](https://docs.praxicraft.com).
- Keep HTTP mocked in tests — no live production calls in CI.
- Release notes: [RELEASING.md](RELEASING.md).

## Code of Conduct

This project follows our [Code of Conduct](./CODE_OF_CONDUCT.md). Report issues to support@praxicraft.com.
