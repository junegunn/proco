Proco
=====

Proco is a lightweight asynchronous task executor service with a thread pool
especially designed for efficient batch processing of multiple data items.

Requirements
------------

Proco requires Ruby 1.8 or higher. Tested on MRI 1.8.7/1.9.3/2.0.0, and JRuby 1.7.3.

Architecture
------------

![Basic producer-consumer configuration](https://github.com/junegunn/proco/raw/master/viz/producer-consumer.png)

Proco is based on the traditional [producer-consumer model](http://en.wikipedia.org/wiki/Producer-consumer_problem)
(hence the name *ProCo*).

- Mutliple clients simultaneously submits (*produces*) items to be processed.
  - A client can asynchronously submit an item and optionally wait for its completion.
- Executor threads in the thread pool process (*consumes*) items concurrently.
- A submitted item is first put into a fixed sized queue.
- A queue has its own dedicated dispatcher thread.
- Each item in the queue is taken out by the dispatcher and assigned to one of the executor threads.
  - Assignments can be done periodically at certain interval, where multiple items are assigned at once for batch processing (see next section).
- In a highly concurrent environment, a queue becomes a point of contention, thus Proco allows having multiple queues.
  - However, for strict serializability (FCFS), you should just have a single queue and a single executor thread (default).

### Proco with a single queue and thread

![](https://github.com/junegunn/proco/raw/master/viz/proco-6-1-1.png)

```ruby
proco = Proco.new
```

### Proco with multiple queues

![](https://github.com/junegunn/proco/raw/master/viz/proco-6-4-5.png)

```ruby
proco = Proco.threads(5).queues(4).new
```

Batch processing
----------------

Sometimes it really helps to process multiple items in batch instead of one at a time.

Notable examples includes:
- buffered disk I/O in Kernel
- consolidated e-mail notification
- database batch updates
- group commit of database transactions

In this scheme, we don't process a request as soon as it arrives,
but wait a little while hoping that we receive more requests as well,
so we can process them together with minimal amortized latency.

It's a pretty common pattern, that most developers will be writing similar scenarios
one way or another at some point. So *why don't we make the pattern reusable*?

Proco was designed with this goal in mind.
As described above, item assignments can be done periodically at the specified interval,
so that multiple items are piled up in the queue between assignments,
and then given to one of the executor threads at once in batch.

```ruby
# Assigns items in batch every second
proco = Proco.interval(1).batch(true).new
```

Thread pool
-----------

Proco implements a pool of concurrently running executor threads.
If you're running CRuby, multi-threading only makes sense if your task involves blocking I/O operations.
On JRuby or Rubinius, executor threads will run in parallel and efficiently utilize multiple cores.

```ruby
# Proco with 8 executor threads
proco = Proco.threads(8).new
```

Proco API
---------

API of Proco is pretty minimal. The following flowchart summarizes the supported operations.

![Life of Proco](https://github.com/junegunn/proco/raw/master/viz/proco-lifecycle.png)

### Initialization

A Proco object can be initialized by chaining the following
[option initializer](https://github.com/junegunn/option_initializer) methods.

| Option     | Type    | Description                              |
|------------|---------|------------------------------------------|
| threads    | Fixnum  | number of threads in the thread pool     |
| queues     | Fixnum  | number of concurrent queues              |
| queue_size | Fixnum  | size of each queue                       |
| interval   | Numeric | dispatcher interval for batch processing |
| batch      | Boolean | enables batch processing mode            |

```ruby
# Initialization with method chaining
proco = Proco.interval(0.1).threads(8).queues(4).queue_size(100).batch(true).new

# Traditional initialization with options hash is also allowed
proco = Proco.new(
          interval:   0.1,
          threads:    8,
          queues:     4,
          queue_size: 100,
          batch:      true)
```

### Starting

```ruby
# Regular Proco
proco = Proco.new
proco.start do |item|
  # code for single item
end

# Proco in batch mode
proco = Proco.batch(true).new
proco.start do |items|
  # code for multiple items
end
```

### Submitting items

```ruby
# Synchronous submission
proco.submit 100

# Asynchronous(1) submission
future = proco.submit! 100
value = future.get
```

### Quitting

```ruby
# Graceful shutdown
proco.exit

# Immediately kills all running threads
proco.kill
```

Examples
--------

```ruby
require 'proco'

proco = Proco.interval(0.1).     # Runs every 0.1 second
              threads(4).        # 4 threads processing items every interval
              queue_size(1000)   # Each thread has a queue of size 1000

proco.start do |items|
  # Batch-process items
  items.each_slice(100) do |slice|
    # ...
  end

  # Return code for the batch
end

# Synchronous submit
result = proco.submit rand(1000)

# Asynchronous(!) submit (can block if the queue is full)
future = proco.submit! rand(1000)

# Wait until the batch containing the item is processed
# (Commit notification)
result = future.get

# ...

# Process remaining submissions and terminate threads
proco.exit

# Or, kill them instantly
# proco.kill
```

Benchmarks
----------

The purpose of the benchmarks shown here is not to present absolute
measurements of performance but to give you a general idea of how proco should
be configured under various workloads of different characteristics.

The following benchmark results were gathered on JRuby 1.7.3.

### Modeling CPU-intensive task

- The task does not involve any blocking I/O
- A fixed amount of CPU time is required for each item
- There's little benefit of batch processing as the total amount of work is just the same

#### Task definition

```ruby
task = lambda do |item|
  (1..10000).inject(:+)
end

batch_task = lambda do |items|
  # Total amount of work is just the same
  items.each do
    (1..10000).inject(:+)
  end
end
```

#### Result (on dual core)

### Modeling direct I/O on a single disk

- We're bypassing write buffer of the Kernel
- Time required to write data on disk is dominated by the seek time of the disk
- Let's assume seek time of our disk is 10ms, and data transfer rate, 50MB/sec
- Each request writes 50kB amount of data
- As we have only one disk, writes cannot occur concurrently

#### Task definition

```ruby
# Mutex for simulating exclusive disk access
mtx = Mutex.new

task = lambda do |item|
  mtx.synchronize do
    # Seek time: 0.01 sec
    # Transfer time: 50kB / 50MB/sec = 0.001 sec
    sleep 0.01 + 0.001
  end
end

batch_task = lambda do |items|
  mtx.synchronize do
    # Seek time: 0.01 sec
    # Transfer time: n * (50kB / 50MB/sec) = n * 0.001 sec
    sleep 0.01 + items.length * 0.001
  end
end
```

#### Result (on dual core)

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
