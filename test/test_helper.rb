require 'bundler/setup'

Bundler.require(:default, :test)

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/great_expectations'

require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir File.expand_path('../lib', __dir__)
loader.setup

MiniTest::Reporters.use!
