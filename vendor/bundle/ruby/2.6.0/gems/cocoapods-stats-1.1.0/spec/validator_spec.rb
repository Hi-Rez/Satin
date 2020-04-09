require File.expand_path('../spec_helper', __FILE__)

describe CocoaPodsStats::SpecsRepoValidator do
  describe 'validates' do
    it 'returns no when given a nil' do
      subject = CocoaPodsStats::SpecsRepoValidator.new
      subject.should.not.validates?(nil)
    end

    it 'returns no when given a source with no url' do
      source = mock(:url => nil)

      subject = CocoaPodsStats::SpecsRepoValidator.new
      subject.should.not.validates?(source)
    end

    it 'returns no when given a master repo that is not cocoapods/specs' do
      sources = mock
      sources.stubs(:url).returns('CocoaPods/NotSpecs.git')

      subject = CocoaPodsStats::SpecsRepoValidator.new
      subject.should.not.validates?(sources)
    end

    it 'returns yes when given a master repo that is cocoapods/specs' do
      sources = mock
      sources.stubs(:url).returns('CocoaPods/Specs.git')

      subject = CocoaPodsStats::SpecsRepoValidator.new
      subject.should.validates?(sources)
    end
  end
end
