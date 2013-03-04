Proco
=====

Proco is a lightweight asynchronous task executor service with a thread pool
especially designed for efficient batch processing of multiple data items.

### What Proco is
- Lightweight, easy-to-use building block for concurrency in Ruby
- High-throughput reactor for relatively simple, short-lived tasks
  - Proco can dispatch hundreds of thousands of items per second

### What Proco is not
- Omnipotent "does-it-all" super gem
- Background task schedulers like Resque or DelayedJob

A quick example
---------------

```ruby
require 'proco'

proco = Proco.interval(0.1).     # Runs every 0.1 second
              threads(4).        # 4 threads processing items every interval
              batch(true).new    # Enables batch processing mode

proco.start do |items|
  # Batch-process items and return something
  # ...
end

# Synchronous submit
result = proco.submit rand(1000)

# Asynchronous(!) submit (can block if the queue is full)
future = proco.submit! rand(1000)

# Wait until the batch containing the item is processed
# (Commit notification)
result = future.get

# Process remaining submissions and terminate threads
proco.exit
```

Requirements
------------

Proco requires Ruby 1.8 or higher. Tested on MRI 1.8.7/1.9.3/2.0.0, and JRuby 1.7.3.

Installation
------------

    gem install proco

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
  - Assignments can be done periodically at certain interval, where multiple items are assigned at once for batch processing
- In a highly concurrent environment, event loop of the dispatcher thread can become the bottleneck.
  - Thus, Proco can be configured to have multiple queues and dispatcher threads
  - However, for strict serializability (FCFS), you should just have a single queue and a single executor thread (default).

### Proco with a single queue and thread

![Default Proco configuration](https://github.com/junegunn/proco/raw/master/viz/proco-6-1-1.png)

```ruby
proco = Proco.new
```

### Proco with multiple queues

![Proco with multiple queues](https://github.com/junegunn/proco/raw/master/viz/proco-6-4-5.png)

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

| Option     | Type    | Description                                    |
|------------|---------|------------------------------------------------|
| threads    | Fixnum  | number of threads in the thread pool           |
| queues     | Fixnum  | number of concurrent queues                    |
| queue_size | Fixnum  | size of each queue                             |
| interval   | Numeric | dispatcher interval for batch processing       |
| batch      | Boolean | enables batch processing mode                  |
| batch_size | Fixnum  | number of maximum items to be assigned at once |

```ruby
# Initialization with method chaining
proco = Proco.interval(0.1).threads(8).queues(4).queue_size(100).batch(true).batch_size(10).new

# Traditional initialization with options hash is also allowed
proco = Proco.new(
          interval:   0.1,
          threads:    8,
          queues:     4,
          queue_size: 100,
          batch:      true,
          batch_size: 10)
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

Benchmarks
----------

The purpose of the benchmarks shown here is not to present absolute
measurements of performance but to give you a general idea of how Proco should
be configured under various workloads of different characteristics.

The following benchmark results were gathered on an 8-core system with JRuby 1.7.3.

### Modeling CPU-intensive task

- The task does not involve any blocking I/O
- A fixed amount of CPU time is required for each item
- There's little benefit of batch processing as the total amount of work is just the same

#### Task definition

```ruby
task = lambda do |item|
  (1..10000).inject(:+)
end

# Total amount of work is just the same
batch_task = lambda do |items|
  items.each do
    (1..10000).inject(:+)
  end
end
```

#### Result

```
                                           : Elapsed time
loop                                       : *********************************************************
Proco.new                                  : ************************************************************
Proco.threads(2).queues(1).new             : *******************************
Proco.threads(2).queues(1).batch(true).new : ***********************************
Proco.threads(2).queues(4).new             : *******************************
Proco.threads(2).queues(4).batch(true).new : ********************************
Proco.threads(4).queues(1).new             : ****************
Proco.threads(4).queues(1).batch(true).new : ************************
Proco.threads(4).queues(4).new             : ****************
Proco.threads(4).queues(4).batch(true).new : ********************
Proco.threads(8).queues(1).new             : *********
Proco.threads(8).queues(1).batch(true).new : ******************
Proco.threads(8).queues(4).new             : *********
Proco.threads(8).queues(4).batch(true).new : *************
```

##### Analysis

- Proco with default configuration is slightly slower than simple loop due to thread coordination overhead
- As we increase the number of threads performance increases as we utilize more CPU cores
- Dispatcher thread is not the bottleneck. Increasing the number of queues and their dispatcher threads doesn't do any good.
- Batch mode takes longer as the tasks are not uniformly distributed among threads
  - We can set `batch_size` to limit the maximum number of items in a batch

##### Result with batch_size = 100

```
proco = Proco.batch_size(100)
                                           : Elapsed time
loop                                       : *********************************************************
proco.new                                  : ************************************************************
proco.threads(2).queues(1).new             : *******************************
proco.threads(2).queues(1).batch(true).new : *******************************
proco.threads(2).queues(4).new             : *******************************
proco.threads(2).queues(4).batch(true).new : ******************************
proco.threads(4).queues(1).new             : ****************
proco.threads(4).queues(1).batch(true).new : ***************
proco.threads(4).queues(4).new             : ****************
proco.threads(4).queues(4).batch(true).new : ***************
proco.threads(8).queues(1).new             : *********
proco.threads(8).queues(1).batch(true).new : *********
proco.threads(8).queues(4).new             : *********
proco.threads(8).queues(4).batch(true).new : ********
```

### Modeling direct I/O on a single disk

- We're bypassing write buffer of the Kernel
- Time required to write data on disk is dominated by the seek time
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

# Let's say it makes sense to group multiple writes into a single I/O operation
batch_task = lambda do |items|
  mtx.synchronize do
    # Seek time: 0.01 sec
    # Transfer time: n * (50kB / 50MB/sec) = n * 0.001 sec
    sleep 0.01 + items.length * 0.001
  end
end
```

#### Result

```
loop                                       : ***********************************************************
Proco.new                                  : ***********************************************************
Proco.threads(2).queues(1).new             : ***********************************************************
Proco.threads(2).queues(1).batch(true).new : ****
Proco.threads(2).queues(4).new             : ***********************************************************
Proco.threads(2).queues(4).batch(true).new : *****
Proco.threads(4).queues(1).new             : ***********************************************************
Proco.threads(4).queues(1).batch(true).new : ****
Proco.threads(4).queues(4).new             : ***********************************************************
Proco.threads(4).queues(4).batch(true).new : *****
Proco.threads(8).queues(1).new             : ************************************************************
Proco.threads(8).queues(1).batch(true).new : ****
Proco.threads(8).queues(4).new             : ***********************************************************
Proco.threads(8).queues(4).batch(true).new : ****
```


##### Analysis

- The number of threads, queues or dispather threads, none of them matters
- Batch mode shows much better performance

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
