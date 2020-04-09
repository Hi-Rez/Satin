require File.expand_path('../spec_helper', __FILE__)

describe CocoaPodsStats::OptOutValidator do
  describe 'validates' do
    it 'returns no when there is an env var' do
      ENV['COCOAPODS_DISABLE_STATS'] = 'true'

      subject = CocoaPodsStats::OptOutValidator.new
      subject.should.not.validates
    end

    it 'returns yes when given a master repo that is cocoapods/specs' do
      ENV['COCOAPODS_DISABLE_STATS'] = nil

      subject = CocoaPodsStats::OptOutValidator.new
      subject.should.validates
    end
  end
end
