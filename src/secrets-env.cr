require "file"
require "path"
require "set"

module ENV
  DEFAULT_SECRETS_PATH = "/run/secrets"

  private ACCESSED = Set(String).new

  # Returns the set of all environment variables or secrets  that have been
  # accessed by the program.
  def self.accessed : Array(String)
    ACCESSED.to_a
  end

  @[Deprecated("Static resolution no longer supported")]
  def self.accessed(static_only) : Array(String)
    raise "Static resolution no longer supported" if static_only
    ACCESSED.to_a
  end

  def self.each
    previous_def do |key, value|
      ACCESSED << key
      yield({key, value})
    end
  end

  # Retrieves a value corresponding to a given *key*. The value will be
  # retrieved from (in order of priorities): system env vars, available secrets
  # files or the return value of the block.
  #
  # This override the default ENV module behaviour to support reading of secrets
  # injected to an environment from docker-compose, kubernetes and other
  # orchestration tools.
  def self.fetch(key : String, &block : String -> String?)
    ACCESSED << key
    previous_def(key) do
      fetch_secret(key) do
        yield key
      end
    end
  end

  # Returns `true` if the environment variable named *key* exists or an secrets
  # file of the same name is available.
  def self.has_key?(key : String) : Bool
    previous_def(key) || has_secret?(key)
  end

  # Retrieves a value corresponding to the given *key*. Return the value of the
  # block if the key does not exist.
  def self.fetch_secret(key : String, &block : String -> String?)
    if has_secret?(key)
      File.read secret_file_path(key)
    else
      yield key
    end
  end

  # Returns `true` if the secret named *key* exists.
  def self.has_secret?(key : String) : Bool
    File.readable? secret_file_path(key)
  end

  private def self.secret_file_path(key)
    base = Crystal::System::Env.get("SECRETS_PATH") || DEFAULT_SECRETS_PATH
    Path[base, key]
  end
end
