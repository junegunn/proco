Proco
=====

Proco is a lightweight asynchronous task executor service with a thread pool
especially designed for efficient batch processing of multiple data items.

Architecture
------------

Proco implements the traditional [producer-consumer model](http://en.wikipedia.org/wiki/Producer-consumer_problem).

- Mutliple clients simultaneously submits (*produces*) items to be processed.
  - A client can asynchronously submit an item and optionally wait for its completion.
- Executor threads in the thread pool process (*consumes*) items concurrently.
- A submitted item is first put into a fixed sized queue.
- A queue has its own dedicated dispatcher thread.
- Each item in the queue is taken out by the dispatcher and assigned to one of the executor threads.
  - Assignments can be done periodically at certain interval, where multiple items are assigned at once for batch processing (see next section).
- In a highly concurrent environment, a queue becomes a point of contention, thus Proco allows having multiple queues.
  - However, for strict serializability (FCFS), you should just have a single queue and a single executor thread (default).

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
proco = Proco.interval(1).batch(true).new
```

Installation
------------

Add this line to your application's Gemfile:

    gem 'proco'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install proco

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
