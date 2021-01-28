require "./spec_helper"
require "../src/secrets-env"
require "spec"

describe ENV do
  describe ".has_secret?" do
    it "reflects the presence of a secret" do
      ENV.has_secret?("SECRETS_ENV_DOES_NOT_EXIST").should be_false
      with_temp_secret("SECRETS_ENV_TEST", "foo") do |key, _|
        ENV.has_secret?(key).should be_true
      end
    end
  end

  describe ".fetch_secret" do
    it "reads the value when available" do
      with_temp_secret("SECRETS_ENV_TEST", "foo") do |key, value|
        read_value = ENV.fetch_secret(key) { fail "file read missed" }
        read_value.should eq(value)
      end
    end

    it "falls back to the block if unavailable" do
      value = ENV.fetch_secret("SECRETS_ENV_DOES_NOT_EXIST") { "fallback" }
      value.should eq("fallback")
    end
  end

  describe ".has_key?" do
    it "reflects presence of an environment variable" do
      ENV.has_key?("SECRETS_ENV_DOES_NOT_EXIST").should be_false
      with_temp_env_var("SECRETS_ENV_TEST", "foo") do |key, _|
        ENV.has_key?(key).should be_true
      end
    end

    it "reflects the presence of a secret" do
      with_temp_secret("SECRETS_ENV_TEST", "foo") do |key, _|
        ENV.has_key?(key).should be_true
      end
    end
  end

  describe ".fetch" do
    it "fetches from an environment variable" do
      with_temp_env_var("SECRETS_ENV_TEST", "foo") do |key, value|
        ENV.fetch(key).should eq(value)
      end
    end

    it "fetches from a secret" do
      with_temp_secret("SECRETS_ENV_TEST", "foo") do |key, value|
        ENV.fetch(key).should eq(value)
      end
    end

    it "preferences env vars if both exist" do
      with_temp_secret("SECRETS_ENV_TEST", "secret value") do |key, secret|
        ENV.fetch(key).should eq(secret)
        with_temp_env_var(key, "env value") do |_, env|
          ENV.fetch(key).should eq(env)
        end
      end
    end
  end

  describe ".[]" do
    it "returns results from env vars" do
      with_temp_env_var("SECRETS_ENV_TEST", "42") do
        ENV["SECRETS_ENV_TEST"].should eq("42")
      end
    end

    it "returns results from a secrets file" do
      with_temp_secret("SECRETS_ENV_TEST", "hunter2") do |key, value|
        ENV[key].should eq(value)
      end
    end

    it "raises if the key does not exist" do
      expect_raises(KeyError) do
        ENV["SECRETS_ENV_DOES_NOT_EXIST"]
      end
    end
  end

  describe ".[]?" do
    it "returns results from env vars" do
      with_temp_env_var("SECRETS_ENV_TEST", "42") do
        ENV["SECRETS_ENV_TEST"].should eq("42")
      end
    end

    it "returns results from a secrets file" do
      with_temp_secret("SECRETS_ENV_TEST", "hunter2") do |key, value|
        ENV[key].should eq(value)
      end
    end

    it "returns nil if the key does not exist" do
      ENV["SECRETS_ENV_DOES_NOT_EXIST"]?.should be_nil
    end
  end

  describe ".accessed" do
    context "static resolution" do
      it "supports non-strict lookups" do
        {% if compare_versions(Crystal::VERSION, "0.36.0") >= 0 %}
          pending! "Static only ENV.accessed unavailable on #{Crystal::VERSION} for non-strict lookups"
        {% end %}
        ENV.accessed.should contain("SECRETS_ENV_NON_STRICT_TEST")
        ENV["SECRETS_ENV_NON_STRICT_TEST"]?
      end

      it "supports strict lookups" do
        ENV.accessed.should contain("SECRETS_ENV_STRICT_TEST")
        ENV["SECRETS_ENV_STRICT_TEST"] rescue nil
      end
    end

    it "includes runtime lookups" do
      runtime_key = ->{ "SECRETS_ENV_RUNTIME_TEST" }.call
      ENV.accessed.should_not contain(runtime_key)
      ENV[runtime_key]?
      ENV.accessed.should contain(runtime_key)
      {% if compare_versions(Crystal::VERSION, "0.36.0") < 0 %}
        ENV.accessed(static_only: true).should_not contain(runtime_key)
      {% else %}
        expect_raises(Exception) do
          ENV.accessed(static_only: true)
        end
      {% end %}
    end
  end
end
