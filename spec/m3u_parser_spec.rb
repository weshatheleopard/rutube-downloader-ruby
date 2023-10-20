require 'spec_helper'
require 'm3u_parser'

RSpec.describe 'M3uParser' do
  describe 'parse' do
    it 'should correctly parse the M3U file #1' do
      m3u_data = M3uParser.new(File.read("spec/fixtures/source_data_1.js")).parse
      assert_value(PP.pp(m3u_data, ''), :log => 'spec/references/parsed_data_1.ref')
    end
  end

  describe 'parse' do
    it 'should correctly parse the M3U file #2' do
      m3u_data = M3uParser.new(File.read("spec/fixtures/source_data_2.js")).parse
      assert_value(PP.pp(m3u_data, ''), :log => 'spec/references/parsed_data_2.ref')
    end
  end
end
