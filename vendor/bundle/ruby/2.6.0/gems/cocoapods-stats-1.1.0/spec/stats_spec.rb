require File.expand_path('../spec_helper', __FILE__)
require 'rubygems'

describe Stats = CocoaPodsStats::Stats do
  describe 'in general' do
    before do
      @stats = Stats.new
    end

    describe 'fork_available?' do
      it 'returns false on Windows' do
        Gem.stubs(:win_platform?).returns(true)
        @stats.fork_available?.should.be.false
      end

      it 'returns true on non-Windows platforms' do
        Gem.stubs(:win_platform?).returns(false)
        @stats.fork_available?.should.be.true
      end
    end

    it 'does not fork unless available' do
      @stats.stubs(:fork_available?).returns(false)
      @stats.expects(:compute_and_send_stats).once
      Process.expects(:fork).never
      @stats.send_stats(nil, nil)
    end

    it 'forks if available' do
      @stats.stubs(:fork_available?).returns(true)
      @stats.stubs(:compute_and_send_stats)
      Process.expects(:fork).once
      @stats.send_stats(nil, nil)
    end
  end
end
