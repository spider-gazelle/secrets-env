# secrets-env

[![Build Status](https://api.travis-ci.com/place-labs/secrets-env.svg?branch=master)](https://travis-ci.com/place-labs/secrets-env)

Extends the behaviour of the crystal-lang `ENV` module to read values injected by [docker secrets](https://docs.docker.com/engine/swarm/secrets/), [kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) and other orchestration tools.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     secrets-env:
       github: place-labs/secrets-env
   ```

2. Run `shards install`

## Usage

```crystal
require "secrets-env"
```

Use the `SECRETS_PATH` environment variable to specify the volume used for secrets injection.
If unspecified this will default to `/run/secrets`.

`ENV` may then be used as per the standard API.
Values fetch from (in order of priority):
1. environment variable
2. secret of the same name
3. fallback (if specified)

Note: attempts to update the environment (`[]=`) will apply this as an env var.
Secrets are immutable.
Once set as env vars take preference over secrets, the new value is readable by the current machine, but is ephemeral.


## Contributing

1. Fork it (<https://github.com/place-labs/secrets-env/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kim Burgess](https://github.com/KimBurgess) - creator and maintainer
