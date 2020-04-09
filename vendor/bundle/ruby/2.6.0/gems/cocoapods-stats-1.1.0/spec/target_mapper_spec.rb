require File.expand_path('../spec_helper', __FILE__)
require 'cocoapods_stats/target_mapper'

describe CocoaPodsStats::TargetMapper do
  describe 'pods_from_project' do
    before do
      @user_project = Xcodeproj::Project.new('App.xcodeproj')
      @user_target = @user_project.new_target(:application, 'App', :ios)
      @user_target.stubs(:uuid).returns('111222333')

      @spec = Pod::Specification.new do |spec|
        spec.name = 'ORStackView'
        spec.version = '1.1.1'
      end

      @sandbox = stub('Sandbox',
                      :root => Pathname('Pods/'),
                      :project => Pod::Project.new('Pods/Pods.xcodeproj'))
      aggregate_target = stub('AggregateTarget',
                              :specs => [@spec],
                              :platform => Pod::Platform.new('test platform', '9.3'),
                              :user_targets => [@user_target],
                              :user_project => @user_project,
                              :label => 'Pods-App')
      @context = Pod::Installer::PostInstallHooksContext.generate(@sandbox, [aggregate_target])
    end

    it 'returns expected data' do
      master_pods = Set.new(['ORStackView'])

      mapper = CocoaPodsStats::TargetMapper.new
      pods = mapper.pods_from_project(@context, master_pods)

      pods.should == [
        {
          :uuid => 'da5511d2baa83c2e753852f1f2fba11003ed0c46c96820c7589b243a8ddb787a',
          :type => 'com.apple.product-type.application',
          :pods => [
            { :name => 'ORStackView', :version => '1.1.1' },
          ],
          :platform => :ios,
        }]
    end

    it 'returns no pods if it cannot find them in the master_pods set' do
      master_pods  = Set.new([''])

      mapper = CocoaPodsStats::TargetMapper.new
      pods = mapper.pods_from_project(@context, master_pods)

      pods.should == [
        {
          :uuid => 'da5511d2baa83c2e753852f1f2fba11003ed0c46c96820c7589b243a8ddb787a',
          :type => 'com.apple.product-type.application',
          :pods => [],
          :platform => :ios,
        },
      ]
    end
  end
end
