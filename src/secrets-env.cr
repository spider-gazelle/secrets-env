require "file"
require "path"
require "set"

module ENV
  DEFAULT_SECRETS_PATH = "/run/secrets"

  private STATIC_ACCESSED = [] of String

  macro finished
    private ACCESSED = STATIC_ACCESSED.to_set
  end

  # Returns the set of all environment variables accessed by the program.
  #
  # Items that can be statically resolved will be provided at compile time, with
  # dynamic access appended following usage.
  def self.accessed(static_only = false) : Array(String)
    if static_only
      STATIC_ACCESSED.dup
    else
      ACCESSED.to_a
    end
  end

  # Override `.[]` to enable compile-time resolution or accessed keys.
  #
  # Maintains the behaviour of the method of the same name.
  macro [](key)
    {{ STATIC_ACCESSED << key if key.is_a? StringLiteral && !STATIC_ACCESSED.includes? key }}
    ENV.fetch({{ key }})
  end

  {% if compare_versions(Crystal::VERSION, "0.36.0") < 0 %}
    {% verbatim do %}
      # Override `.[]?` to enable compile-time resolution or accessed keys.
      #
      # Maintains the behaviour of the method of the same name.
      macro []?(key)
        {{ STATIC_ACCESSED << key if key.is_a? StringLiteral && !STATIC_ACCESSED.includes? key }}
        ENV.fetch({{ key }}, nil)
      end
    {% end %}
  {% else %}
    def self.accessed(static_only = false) : Array(String)
      raise "Static only ENV.accessed is not supported on #{Crystal::VERSION}" if static_only
      previous_def
    end
  {% end %}

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
