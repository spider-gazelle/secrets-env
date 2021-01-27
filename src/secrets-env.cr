require "file"
require "path"

module ENV
  DEFAULT_SECRETS_PATH = "/run/secrets"

  private ACCESSED = [] of String

  macro finished
    {% if ACCESSED.empty? %}
      private STATIC_ACCESSED = Tuple.new
    {% else %}
      private STATIC_ACCESSED = Tuple.new(
        {% for key in ACCESSED %}
          {{ key }},
        {% end %}
      )
    {% end %}
  end

  # Override `.[]` to enable compile-time resolution or accessed keys.
  #
  # Maintains the behaviour of the method of the same name.
  macro [](key)
    {{ ACCESSED << key if key.is_a? StringLiteral && !ACCESSED.includes? key }}
    ENV.fetch({{ key }})
  end

  # Override `.[]?` to enable compile-time resolution or accessed keys.
  #
  # Maintains the behaviour of the method of the same name.
  macro []?(key)
    {{ ACCESSED << key if key.is_a? StringLiteral && !ACCESSED.includes? key }}
    ENV.fetch({{ key }}, nil)
  end

  # Returns the set of all environment variables accessed by the program.
  #
  # Items that can be statically resolved will be provided at compile time, with
  # dynamic access appended following usage.
  def self.accessed(static_only = false) : Enumerable(String)
    if static_only
      STATIC_ACCESSED
    else
      ACCESSED.dup
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
    ACCESSED << key unless key.in? ACCESSED
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
