require "spec"
require "file"
require "../src/secrets-env"

original_secrets_path = nil

Spec.before_suite do
  original_secrets_path = Crystal::System::Env.get "SECRETS_PATH"
  Crystal::System::Env.set "SECRETS_PATH", Dir.tempdir
end

Spec.after_suite do
  Crystal::System::Env.set "SECRETS_PATH", original_secrets_path
end

describe ENV do
  describe "[]" do
    it "returns results from env vars" do
      # Regression test for original behaviour
      ENV["SECRETS_PATH"].should eq(Dir.tempdir)
    end

    it "returns results from a secrets file" do
      tmp = File.tempfile &.print("hunter2")
      tmp_name = Path[tmp.path].basename
      ENV[tmp_name].should eq("hunter2")
      tmp.delete
    end
  end
end
