Proco
=====

Proco is a lightweight asynchronous task executor service with a thread pool
especially designed for efficient batch processing of multiple data items.

Requirements
------------

Proco requires Ruby 1.8 or higher.

Architecture
------------

![Basic producer-consumer configuration](https://github.com/junegunn/proco/raw/master/viz/producer-consumer.png)

Proco implements the traditional [producer-consumer model](http://en.wikipedia.org/wiki/Producer-consumer_problem) (hence the name *Pro-Co*).

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

### Proco with multiple queues

![](https://github.com/junegunn/proco/raw/master/viz/proco-6-4-5.png)

Batch processing
----------------

Sometimes it really helps to process multiple items in bulk instead of one at a time.

Notable examples includes
- buffered disk I/O in Kernel
- consolidated e-mail notification
- database batch updates
- and group commit of database transactions.

In such scheme, we don't process a request as soon as it arrives,
but wait a little while hoping that we receive more requests as well,
so we can process them together with minimal amortized latency.

It's a pretty common pattern, that most developers will be writing similar scenarios
one way or another at some point. So *why don't we make it reusable*?

Proco was designed with this in mind.
As described above, item assignments to executor threads can be done periodically at the specified interval,
so that certain number of items are piled up between assignments and then assigned at once in batch.

```ruby
# Assigns items in batch every second
proco = Proco.interval(1).batch(true).new
```

Thread pool
-----------

```ruby
# Proco with 8 executor threads
proco = Proco.threads(8).new
```

Proco implements a pool of concurrently running executor threads.
If you're running CRuby, multi-threading only makes sense if your task involves blocking I/O operations.
On JRuby or Rubinius, executor threads will run in parallel and efficiently utilize multiple cores.

Is it any good?
---------------

Yes.


Installation
------------

Add this line to your application's Gemfile:

    gem 'proco'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install proco

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

# Traditional initialization with options hash
proco = Proco.new(
          interval:   0.1,
          threads:    8,
          queues:     4,
          queue_size: 100,
          batch:      true)
```

### Starting

### Submitting items

### Quitting

```ruby
proco.exit

proco.kill
```

Basic usage
-----------

```ruby
require 'proco'

proco = Proco.interval(0.1).     # Runs every 0.1 second
              threads(4).        # 4 threads processing items every interval
              tries(2).          # Retry on processing error
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


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
