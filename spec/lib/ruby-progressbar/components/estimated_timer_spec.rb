require 'spec_helper'
require 'support/time'

describe ProgressBar::Components::EstimatedTimer do
  let(:timer) { ProgressBar::Components::Timer.new }
  let(:progressable) { ProgressBar::Components::Progressable.new(:starting_at => 0, :total => progress_total, :smoothing => smoothing) }
  let(:smoothing)    { 0.1 }
  let(:progress_total) { 100 }

  describe '#progress=' do
    it 'raises an error when passed a number larger than the total' do
      @estimated_time = ProgressBar::Components::EstimatedTimer.new(:total => 100,
                                                                    :timer => timer,
                                                                    :progress => progressable)
      expect { progressable.progress = 101 }.to raise_error(ProgressBar::InvalidProgressError, "You can't set the item's current value to be greater than the total.")
    end
  end

  describe '#to_s' do
    context 'when the timer has been started but no progress has been made' do
      before do
        @estimated_time = ProgressBar::Components::EstimatedTimer.new(:total => 100,
                                                                      :timer => timer,
                                                                      :progress => progressable)
        progressable.start
        timer.start
      end

      it 'displays an unknown time remaining' do
        expect(@estimated_time.to_s).to eql ' ETA: ??:??:??'
      end

      context 'and it is incremented' do
        it 'should not display unknown time remaining' do
          progressable.increment
          expect(@estimated_time.to_s).not_to eql ' ETA: ??:??:??'
        end
      end
    end

    context 'when half the progress has been made' do
      context 'and smoothing is turned off' do
        let(:smoothing) { 0.0 }

        context 'and it took 3:42:12 to do it' do
          before do
            @estimated_time = ProgressBar::Components::EstimatedTimer.new(:timer => timer, :progress => progressable)

            Timecop.travel(-13332) do
              progressable.start
              timer.start
              50.times { progressable.increment }
            end
          end

          context 'when #decrement is called' do
            before { 20.times { progressable.decrement } }

            it 'displays the correct time remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: 08:38:28'
            end
          end

          context 'when #reset is called' do
            before { progressable.reset }

            it 'displays unknown time remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: ??:??:??'
            end
          end

          it 'displays the correct time remaining' do
            expect(@estimated_time.to_s).to eql ' ETA: 03:42:12'
          end
        end

        context 'when it is estimated to take longer than 99:59:59' do
          before do
            @estimated_time = ProgressBar::Components::EstimatedTimer.new(:timer => timer, :progress => progressable)

            Timecop.travel(-120000) do
              progressable.start
              timer.start
              25.times { progressable.increment }
            end
          end

          context 'and the out of bounds time format has been set to "friendly"' do
            before { @estimated_time.out_of_bounds_time_format = :friendly }

            it 'displays "> 4 Days" remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: > 4 Days'
            end
          end

          context 'and the out of bounds time format has been set to "unknown"' do
            before { @estimated_time.out_of_bounds_time_format = :unknown }

            it 'displays "??:??:??" remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: ??:??:??'
            end
          end

          it 'displays the correct time remaining' do
            expect(@estimated_time.to_s).to eql ' ETA: 100:00:00'
          end
        end
      end

      context 'and smoothing is turned on' do
        let(:smoothing) { 0.5 }

        context 'and it took 3:42:12 to do it' do
          before do
            @estimated_time = ProgressBar::Components::EstimatedTimer.new(:timer => timer, :progress => progressable)

            Timecop.travel(-13332) do
              progressable.start
              timer.start
              50.times { progressable.increment }
            end
          end

          context 'when #decrement is called' do
            before { 20.times { progressable.decrement } }

            it 'displays the correct time remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: 08:14:34'
            end
          end

          context 'when #reset is called' do
            before { progressable.reset }

            it 'displays unknown time remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: ??:??:??'
            end
          end

          it 'displays the correct time remaining' do
            expect(@estimated_time.to_s).to eql ' ETA: 03:51:16'
          end
        end

        context 'when it is estimated to take longer than 99:59:59' do
          before do
            @estimated_time = ProgressBar::Components::EstimatedTimer.new(:smoothing => smoothing, :timer => timer, :progress => progressable)

            Timecop.travel(-120000) do
              progressable.start
              timer.start
              25.times { progressable.increment }
            end
          end

          context 'and the out of bounds time format has been set to "friendly"' do
            before { @estimated_time.out_of_bounds_time_format = :friendly }

            it 'displays "> 4 Days" remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: > 4 Days'
            end
          end

          context 'and the out of bounds time format has been set to "unknown"' do
            before { @estimated_time.out_of_bounds_time_format = :unknown }

            it 'displays "??:??:??" remaining' do
              expect(@estimated_time.to_s).to eql ' ETA: ??:??:??'
            end
          end

          it 'displays the correct time remaining' do
            expect(@estimated_time.to_s).to eql ' ETA: 105:33:20'
          end
        end
      end
    end

    context 'a thing with a total' do
      let(:progress_total) { 10 }

    it 'displays a good estimate for regular increments' do
      begin
        Timecop.freeze(t = Time.now)
        estimated_time = ProgressBar::Components::EstimatedTimer.new(:smoothing => smoothing, :timer => timer, :progress => progressable)
        progressable.start
        timer.start
        results = (1..progress_total).map do |i|
          Timecop.freeze(t + 0.5 * i)
          progressable.increment
          estimated_time.to_s
        end

        expect(results).to eql([
          ' ETA: 00:00:05',
          ' ETA: 00:00:04',
          ' ETA: 00:00:04',
          ' ETA: 00:00:03',
          ' ETA: 00:00:03',
          ' ETA: 00:00:02',
          ' ETA: 00:00:02',
          ' ETA: 00:00:01',
          ' ETA: 00:00:01',
          ' ETA: 00:00:00',
        ])
      ensure
        Timecop.return
      end
    end
    end
  end

  describe '#out_of_bounds_time_format=' do
    context 'when set to an invalid format' do
      it 'raises an exception' do
        @estimated_time = ProgressBar::Components::EstimatedTimer.new(:total => 100, :timer => timer, :progress => progressable)
        expect { @estimated_time.out_of_bounds_time_format = :foo }.to raise_error('Invalid Out Of Bounds time format.  Valid formats are [:unknown, :friendly, nil]')
      end
    end
  end

  describe '#start' do

    ###
    # Using ruby-debug under jruby pulls in ruby-debug-base, which defines
    # Kernel.start. This causes a bug, as EstimatedTimer::As::method_missing calls
    # Kernel.start instead of EstimatedTimer.start. This spec duplicates the bug.
    # Without the fix, this results in the following exception:
    #
    # 1) ruby-debug-base doesn't stop the progressbar from working
    #    Failure/Error: COUNT.times { bar.increment }
    #    NoMethodError:
    #      undefined method `+' for nil:NilClass
    #    # ./lib/ruby-progressbar/components/progressable.rb:33:in `increment'
    #
    it 'properly delegates' do
      @output = StringIO.new('', 'w+')

      module Kernel
        def start(options={}, &block)
          puts "Kernel.start has been called"
          return nil
        end
      end

      begin
        COUNT = 100

        bar = ProgressBar.create(:output => @output, :title => 'ruby-debug-base', :total => COUNT)

        COUNT.times { bar.increment }
      ensure
        module Kernel
          remove_method :start
        end
      end
    end
  end
end
