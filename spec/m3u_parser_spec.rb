require 'spec_helper'
require 'm3u_parser'

RSpec.describe 'M3UParser' do
  describe 'parse' do
    it 'should correctly parse the M3U file #1' do
      m3u_data = M3UParser.new(File.read("spec/fixtures/source_data_1.js")).parse
      assert_value(PP.pp(m3u_data, ''), :log => 'spec/references/parsed_data_1.ref')
    end

    it 'should correctly parse the M3U file #2' do
      m3u_data = M3UParser.new(File.read("spec/fixtures/source_data_2.js")).parse
      assert_value(PP.pp(m3u_data, ''), :log => 'spec/references/parsed_data_2.ref')
    end

    it 'should correctly parse the M3U file #3' do
      parser = M3UParser.new(File.read("spec/fixtures/source_data_3.js"))
      assert_value(PP.pp(parser.parse, ''), :log => 'spec/references/parsed_data_3.ref')
      assert_value(PP.pp(parser.extract_tracklist('http://some-server.net/some_dir/'), ''),
                    :log => 'spec/references/tracklist_3.ref')
    end
  end

end
