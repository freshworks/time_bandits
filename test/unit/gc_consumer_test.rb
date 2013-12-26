require_relative '../test_helper'

class GCConsumerTest < Test::Unit::TestCase
  def setup
    TimeBandits.time_bandits = []
    TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance
    TimeBandits.reset
  end

  test "getting metrics" do
    # example metrics hash:
    sample = {
      :gc_time => 0.5,
      :gc_calls => 0,
      :heap_growth => 0,
      :heap_size => 116103,
      :allocated_objects => 8,
      :allocated_bytes => 152,
      :live_data_set_size => 69437
    }
    m = TimeBandits.metrics
    assert_equal sample.keys.sort, m.keys.sort
  end

  test "formatting" do
    # example runtime:
    # "GC: 0.000(0) | HP: 0(116101,6,0,69442)"
    gc, heap = TimeBandits.runtime.split(' | ')
    assert_equal "GC: 0.000(0)", gc
    assert_match heap, /HP: \d+\(\d+,\d+,\d+,\d+\)/
  end

  test "collecting GC stats" do
    work
    check_work
  end

  private
  def work
    TimeBandits.reset
    a = []
    10.times do |i|
      a << (i.to_s * 100)
    end
  end
  def check_work
    GC.start
    m = TimeBandits.metrics
    assert 0 <  m[:gc_calls]
    assert 0 <  m[:gc_time]
    assert 0 <= m[:heap_growth]
    assert 0 <  m[:heap_size]
    assert 0 <  m[:allocated_objects]
    assert 0 <  m[:allocated_bytes]
    assert 0 <= m[:live_data_set_size]
  end
end