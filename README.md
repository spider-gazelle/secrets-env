# secrets-env

Extends the behaviour of the crystal-lang `ENV` module to read values injected by [docker secrets](https://docs.docker.com/engine/swarm/secrets/), [kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) and other orchestration tools.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     secrets-env:
       github: spider-gazelle/secrets-env
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

Additionally, `ENV.accessed` is a compile-time record of all accesses to the `ENV` variable across the program.
