require "rails_helper"

RSpec.describe Lock do
  before do
    redis.del("test")
  end

  after do
    redis.del("test")
  end

  it "locks" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
  end

  it "can be unlocked with lock_value" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    lock.unlock
    expect(lock).to_not be_locked
  end

  it "can't lock twice" do
    lock = Lock.new("test")
    expect(lock.lock).to be_truthy
    expect(lock.lock).to be_falsey
  end

  it "is unlocked after an hour" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    # We expect this to run in less than a second.
    expect(redis.ttl("test").to_i).to be >= 3599
    expect(redis.ttl("test").to_i).to be <= 3600
  end

  it "is lockable again after expiration" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    redis.expire("test", 1)
    sleep(2)
    expect(lock).to_not be_locked
    expect(lock.lock).to be_truthy
  end
end
