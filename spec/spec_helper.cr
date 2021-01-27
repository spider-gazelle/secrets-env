require "file"

# Sets an env var on the runtime environment.
#
# NOTE: this mutates the runtime environment.
def set_env_var!(key : String, value : String?) : Nil
  Crystal::System::Env.set key, value
end

# Temporarilly set an environment variable while the passed block executes.
#
# Yields the value path to the block.
def with_temp_env_var(key : String, value : String, & : String, String -> Nil) : Nil
  original_value = Crystal::System::Env.get key
  set_env_var! key, value
  yield key, value
  set_env_var! key, original_value
end

# Write an ephemeral secret to the filesystem that will persist while the passed
# block executes.
#
# Yields the secret key to the block.
def with_temp_secret(key : String, value : String, path = Dir.tempdir, & : String, String -> Nil) : Nil
  with_temp_env_var("SECRETS_PATH", path) do |_, path|
    secret = Path[path, key]
    raise "file conflict #{secret} already exists" if File.exists? secret
    File.write secret, value
    yield key, value
    File.delete secret
  end
end
