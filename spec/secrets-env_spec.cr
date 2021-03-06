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
    it "tracks non-strict lookups" do
      ENV["SECRETS_ENV_NON_STRICT_TEST"]?
      ENV.accessed.should contain("SECRETS_ENV_NON_STRICT_TEST")
    end

    it "tracks strict lookups" do
      ENV["SECRETS_ENV_STRICT_TEST"] rescue nil
      ENV.accessed.should contain("SECRETS_ENV_STRICT_TEST")
    end

    it "tracks enumerations" do
      ENV.each { }
      ENV.accessed.should contain("CRYSTAL_PATH")
    end
  end
end
