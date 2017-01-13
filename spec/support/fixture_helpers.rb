module FixtureHelpers
  def fixture_data(name)
    path = File.join(fixture_path, "#{name}.json")
    File.read(path)
  end

  def decoded_fixture_data(name)
    JSON.parse(fixture_data(name))
  end
end
